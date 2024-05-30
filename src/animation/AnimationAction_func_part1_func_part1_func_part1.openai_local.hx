import AnimationBlendMode from '../constants/AnimationBlendMode';

class AnimationAction {
    private var _mixer:Mixer;
    private var _clip:Clip;
    private var _localRoot:Null<Dynamic>;
    public var blendMode:AnimationBlendMode;
    
    public function new(mixer:Mixer, clip:Clip, ?localRoot:Null<Dynamic>, ?blendMode:AnimationBlendMode) {
        this._mixer = mixer;
        this._clip = clip;
        this._localRoot = localRoot;
        this.blendMode = blendMode != null ? blendMode : clip.blendMode;

        var tracks:Array<Track> = clip.tracks;
        var nTracks:Int = tracks.length;
        var interpolants:Array<Interpolant> = new Array(nTracks);
        var interpolantSettings = {
            endingStart: ZeroCurvatureEnding,
            endingEnd: ZeroCurvatureEnding
        };

        for (i in 0...nTracks) {
            var interpolant:Interpolant = tracks[i].createInterpolant(null);
            interpolants[i] = interpolant;
            interpolant.settings = interpolantSettings;
        }

        this._interpolantSettings = interpolantSettings;
        this._interpolants = interpolants;

        this._propertyBindings = new Array(nTracks);

        this._cacheIndex = null;
        this._byClipCacheIndex = null;

        this._timeScaleInterpolant = null;
        this._weightInterpolant = null;

        this.loop = LoopRepeat;
        this._loopCount = -1;

        this._startTime = null;
        this.time = 0;

        this.timeScale = 1;
        this._effectiveTimeScale = 1;

        this.weight = 1;
        this._effectiveWeight = 1;

        this.repetitions = Infinity;

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

    // Other methods...

}