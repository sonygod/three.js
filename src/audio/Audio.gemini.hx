import three.core.Object3D;
import three.audio.AudioListener;

class Audio extends Object3D {

	public var type:String = 'Audio';

	public var listener:AudioListener;
	public var context:Dynamic;

	public var gain:Dynamic;
	public var autoplay:Bool = false;

	public var buffer:Dynamic = null;
	public var detune:Float = 0;
	public var loop:Bool = false;
	public var loopStart:Float = 0;
	public var loopEnd:Float = 0;
	public var offset:Float = 0;
	public var duration:Float = null;
	public var playbackRate:Float = 1;
	public var isPlaying:Bool = false;
	public var hasPlaybackControl:Bool = true;
	public var source:Dynamic = null;
	public var sourceType:String = 'empty';

	private var _startedAt:Float = 0;
	private var _progress:Float = 0;
	private var _connected:Bool = false;

	public var filters:Array<Dynamic> = [];

	public function new(listener:AudioListener) {
		super();

		this.listener = listener;
		this.context = listener.context;

		this.gain = this.context.createGain();
		this.gain.connect(listener.getInput());
	}

	public function getOutput():Dynamic {
		return this.gain;
	}

	public function setNodeSource(audioNode:Dynamic):Audio {
		this.hasPlaybackControl = false;
		this.sourceType = 'audioNode';
		this.source = audioNode;
		this.connect();
		return this;
	}

	public function setMediaElementSource(mediaElement:Dynamic):Audio {
		this.hasPlaybackControl = false;
		this.sourceType = 'mediaNode';
		this.source = this.context.createMediaElementSource(mediaElement);
		this.connect();
		return this;
	}

	public function setMediaStreamSource(mediaStream:Dynamic):Audio {
		this.hasPlaybackControl = false;
		this.sourceType = 'mediaStreamNode';
		this.source = this.context.createMediaStreamSource(mediaStream);
		this.connect();
		return this;
	}

	public function setBuffer(audioBuffer:Dynamic):Audio {
		this.buffer = audioBuffer;
		this.sourceType = 'buffer';
		if (this.autoplay) this.play();
		return this;
	}

	public function play(delay:Float = 0):Audio {
		if (this.isPlaying) {
			Sys.warning('THREE.Audio: Audio is already playing.');
			return this;
		}

		if (!this.hasPlaybackControl) {
			Sys.warning('THREE.Audio: this Audio has no playback control.');
			return this;
		}

		this._startedAt = this.context.currentTime + delay;

		var source = this.context.createBufferSource();
		source.buffer = this.buffer;
		source.loop = this.loop;
		source.loopStart = this.loopStart;
		source.loopEnd = this.loopEnd;
		source.onended = this.onEnded;
		source.start(this._startedAt, this._progress + this.offset, this.duration);

		this.isPlaying = true;

		this.source = source;

		this.setDetune(this.detune);
		this.setPlaybackRate(this.playbackRate);

		return this.connect();
	}

	public function pause():Audio {
		if (!this.hasPlaybackControl) {
			Sys.warning('THREE.Audio: this Audio has no playback control.');
			return this;
		}

		if (this.isPlaying) {
			// update current progress
			this._progress += Math.max(this.context.currentTime - this._startedAt, 0) * this.playbackRate;

			if (this.loop) {
				// ensure _progress does not exceed duration with looped audios
				this._progress %= (this.duration != null ? this.duration : this.buffer.duration);
			}

			this.source.stop();
			this.source.onended = null;
			this.isPlaying = false;
		}
		return this;
	}

	public function stop():Audio {
		if (!this.hasPlaybackControl) {
			Sys.warning('THREE.Audio: this Audio has no playback control.');
			return this;
		}

		this._progress = 0;

		if (this.source != null) {
			this.source.stop();
			this.source.onended = null;
		}

		this.isPlaying = false;
		return this;
	}

	public function connect():Audio {
		if (this.filters.length > 0) {
			this.source.connect(this.filters[0]);

			for (i in 1...this.filters.length) {
				this.filters[i - 1].connect(this.filters[i]);
			}

			this.filters[this.filters.length - 1].connect(this.getOutput());
		} else {
			this.source.connect(this.getOutput());
		}

		this._connected = true;
		return this;
	}

	public function disconnect():Audio {
		if (!this._connected) return this;

		if (this.filters.length > 0) {
			this.source.disconnect(this.filters[0]);

			for (i in 1...this.filters.length) {
				this.filters[i - 1].disconnect(this.filters[i]);
			}

			this.filters[this.filters.length - 1].disconnect(this.getOutput());
		} else {
			this.source.disconnect(this.getOutput());
		}

		this._connected = false;
		return this;
	}

	public function getFilters():Array<Dynamic> {
		return this.filters;
	}

	public function setFilters(value:Array<Dynamic>):Audio {
		if (value == null) value = [];

		if (this._connected) {
			this.disconnect();
			this.filters = value.copy();
			this.connect();
		} else {
			this.filters = value.copy();
		}

		return this;
	}

	public function setDetune(value:Float):Audio {
		this.detune = value;
		if (this.isPlaying && this.source.detune != null) {
			this.source.detune.setTargetAtTime(this.detune, this.context.currentTime, 0.01);
		}
		return this;
	}

	public function getDetune():Float {
		return this.detune;
	}

	public function getFilter():Dynamic {
		return this.getFilters()[0];
	}

	public function setFilter(filter:Dynamic):Audio {
		return this.setFilters(filter != null ? [filter] : []);
	}

	public function setPlaybackRate(value:Float):Audio {
		if (!this.hasPlaybackControl) {
			Sys.warning('THREE.Audio: this Audio has no playback control.');
			return this;
		}

		this.playbackRate = value;

		if (this.isPlaying) {
			this.source.playbackRate.setTargetAtTime(this.playbackRate, this.context.currentTime, 0.01);
		}

		return this;
	}

	public function getPlaybackRate():Float {
		return this.playbackRate;
	}

	public function onEnded(event:Dynamic) {
		this.isPlaying = false;
	}

	public function getLoop():Bool {
		if (!this.hasPlaybackControl) {
			Sys.warning('THREE.Audio: this Audio has no playback control.');
			return false;
		}

		return this.loop;
	}

	public function setLoop(value:Bool):Audio {
		if (!this.hasPlaybackControl) {
			Sys.warning('THREE.Audio: this Audio has no playback control.');
			return this;
		}

		this.loop = value;

		if (this.isPlaying) {
			this.source.loop = this.loop;
		}

		return this;
	}

	public function setLoopStart(value:Float):Audio {
		this.loopStart = value;
		return this;
	}

	public function setLoopEnd(value:Float):Audio {
		this.loopEnd = value;
		return this;
	}

	public function getVolume():Float {
		return this.gain.gain.value;
	}

	public function setVolume(value:Float):Audio {
		this.gain.gain.setTargetAtTime(value, this.context.currentTime, 0.01);
		return this;
	}

}