import animation.Constants;
import animation.Interpolant;
import animation.PropertyMixer;
import js.lib.Float32Array;

class AnimationAction {

    public var blendMode(default, null):Int;
    public var loop(default, null):Int;
    public var repetitions(default, null):Float;
    public var paused(default, null):Bool;
    public var enabled(default, null):Bool;
    public var clampWhenFinished(default, null):Bool;
    public var zeroSlopeAtStart(default, null):Bool;
    public var zeroSlopeAtEnd(default, null):Bool;
    public var time(default, null):Float;
    public var timeScale(default, null):Float;
    public var weight(default, null):Float;
    public var _mixer:Mixer;
    public var _clip:Clip;
    public var _localRoot(default, null):Dynamic;
    public var _interpolants(default, null):Array<Interpolant>;
    public var _propertyBindings(default, null):Array<PropertyMixer>;
    public var _cacheIndex(default, null):Dynamic;
    public var _byClipCacheIndex(default, null):Dynamic;
    public var _timeScaleInterpolant(default, null):Interpolant;
    public var _weightInterpolant(default, null):Interpolant;
    public var _loopCount(default, null):Int;
    public var _startTime(default, null):Float;
    public var _effectiveTimeScale(default, null):Float;
    public var _effectiveWeight(default, null):Float;

    public function new(mixer:Mixer, clip:Clip, localRoot:Dynamic = null, blendMode:Int = clip.blendMode) {
        this._mixer = mixer;
        this._clip = clip;
        this._localRoot = localRoot;
        this.blendMode = blendMode;
        
        var tracks = clip.tracks;
        var nTracks = tracks.length;
        var interpolants = new Array<Interpolant>(nTracks);
        var interpolantSettings = { endingStart: Constants.ZeroCurvatureEnding, endingEnd: Constants.ZeroCurvatureEnding };
        
        for (i in 0...nTracks) {
            var interpolant = tracks[i].createInterpolant(null);
            interpolants[i] = interpolant;
            interpolant.settings = interpolantSettings;
        }
        
        this._interpolantSettings = interpolantSettings;
        this._interpolants = interpolants;
        this._propertyBindings = new Array<PropertyMixer>(nTracks);
        this._timeScaleInterpolant = null;
        this._weightInterpolant = null;
        this.loop = Constants.LoopRepeat;
        this._loopCount = -1;
        this._startTime = null;
        this.time = 0;
        this.timeScale = 1;
        this._effectiveTimeScale = 1;
        this.weight = 1;
        this._effectiveWeight = 1;
        this.repetitions = Math.POSITIVE_INFINITY;
        this.paused = false;
        this.enabled = true;
        this.clampWhenFinished = false;
        this.zeroSlopeAtStart = true;
        this.zeroSlopeAtEnd = true;
    }

    public function play():AnimationAction {
        this._mixer._activateAction(this);
        return this;
    }

    public function stop():AnimationAction {
        this._mixer._deactivateAction(this);
        return this.reset();
    }

    public function reset():AnimationAction {
        this.paused = false;
        this.enabled = true;
        this.time = 0;
        this._loopCount = -1;
        this._startTime = null;
        return this.stopFading().stopWarping();
    }

    public function isRunning():Bool {
        return this.enabled && !this.paused && this.timeScale != 0 && this._startTime == null && this._mixer._isActiveAction(this);
    }

    public function isScheduled():Bool {
        return this._mixer._isActiveAction(this);
    }

    public function startAt(time:Float):AnimationAction {
        this._startTime = time;
        return this;
    }

    public function setLoop(mode:Int, repetitions:Float):AnimationAction {
        this.loop = mode;
        this.repetitions = repetitions;
        return this;
    }

    public function setEffectiveWeight(weight:Float):AnimationAction {
        this.weight = weight;
        this._effectiveWeight = this.enabled ? weight : 0;
        return this.stopFading();
    }

    public function getEffectiveWeight():Float {
        return this._effectiveWeight;
    }

    // Other methods omitted for brevity...
}