import three.core.Object3D;

class Audio extends Object3D {

    public var listener:Listener;
    public var context:Context;
    public var gain:GainNode;
    public var autoplay:Bool;
    public var buffer:AudioBuffer;
    public var detune:Float;
    public var loop:Bool;
    public var loopStart:Float;
    public var loopEnd:Float;
    public var offset:Float;
    public var duration:Float;
    public var playbackRate:Float;
    public var isPlaying:Bool;
    public var hasPlaybackControl:Bool;
    public var source:AudioNode;
    public var sourceType:String;
    private var _startedAt:Float;
    private var _progress:Float;
    private var _connected:Bool;
    public var filters:Array<AudioNode>;

    public function new(listener:Listener) {
        super();

        this.type = "Audio";

        this.listener = listener;
        this.context = listener.context;

        this.gain = this.context.createGain();
        this.gain.connect(listener.getInput());

        this.autoplay = false;

        this.buffer = null;
        this.detune = 0;
        this.loop = false;
        this.loopStart = 0;
        this.loopEnd = 0;
        this.offset = 0;
        this.duration = NaN;
        this.playbackRate = 1;
        this.isPlaying = false;
        this.hasPlaybackControl = true;
        this.source = null;
        this.sourceType = "empty";

        this._startedAt = 0;
        this._progress = 0;
        this._connected = false;

        this.filters = [];
    }

    public function getOutput():GainNode {
        return this.gain;
    }

    public function setNodeSource(audioNode:AudioNode):Audio {
        this.hasPlaybackControl = false;
        this.sourceType = "audioNode";
        this.source = audioNode;
        this.connect();

        return this;
    }

    public function setMediaElementSource(mediaElement:MediaElement):Audio {
        this.hasPlaybackControl = false;
        this.sourceType = "mediaNode";
        this.source = this.context.createMediaElementSource(mediaElement);
        this.connect();

        return this;
    }

    public function setMediaStreamSource(mediaStream:MediaStream):Audio {
        this.hasPlaybackControl = false;
        this.sourceType = "mediaStreamNode";
        this.source = this.context.createMediaStreamSource(mediaStream);
        this.connect();

        return this;
    }

    public function setBuffer(audioBuffer:AudioBuffer):Audio {
        this.buffer = audioBuffer;
        this.sourceType = "buffer";

        if (this.autoplay) this.play();

        return this;
    }

    public function play(delay:Float = 0):Audio {
        if (this.isPlaying) {
            trace("THREE.Audio: Audio is already playing.");
            return this;
        }

        if (!this.hasPlaybackControl) {
            trace("THREE.Audio: this Audio has no playback control.");
            return this;
        }

        this._startedAt = this.context.currentTime + delay;

        var source = this.context.createBufferSource();
        source.buffer = this.buffer;
        source.loop = this.loop;
        source.loopStart = this.loopStart;
        source.loopEnd = this.loopEnd;
        source.onended = this.onEnded.bind(this);
        source.start(this._startedAt, this._progress + this.offset, this.duration);

        this.isPlaying = true;

        this.source = source;

        this.setDetune(this.detune);
        this.setPlaybackRate(this.playbackRate);

        return this.connect();
    }

    // ... rest of the methods ...

    public function getFilter():AudioNode {
        return this.filters[0];
    }

    public function setFilter(filter:AudioNode):Audio {
        return this.setFilters(filter != null ? [filter] : []);
    }

    // ... rest of the methods ...
}