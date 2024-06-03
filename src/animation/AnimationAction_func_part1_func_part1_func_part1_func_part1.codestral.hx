class AnimationAction {
    public var _mixer:Mixer;
    public var _clip:Clip;
    public var _localRoot:Dynamic;
    public var blendMode:Int;
    public var _interpolants:Array<Interpolant>;
    public var _interpolantSettings:Dynamic;
    public var _propertyBindings:Array<Dynamic>;
    public var _cacheIndex:Int;
    public var _byClipCacheIndex:Int;
    public var _timeScaleInterpolant:Interpolant;
    public var _weightInterpolant:Interpolant;
    public var loop:Int;
    public var _loopCount:Int;
    public var _startTime:Float;
    public var time:Float;
    public var timeScale:Float;
    public var _effectiveTimeScale:Float;
    public var weight:Float;
    public var _effectiveWeight:Float;
    public var repetitions:Float;
    public var paused:Bool;
    public var enabled:Bool;
    public var clampWhenFinished:Bool;
    public var zeroSlopeAtStart:Bool;
    public var zeroSlopeAtEnd:Bool;

    public function new(mixer:Mixer, clip:Clip, localRoot:Dynamic = null, blendMode:Int = -1) {
        this._mixer = mixer;
        this._clip = clip;
        this._localRoot = localRoot;
        this.blendMode = blendMode != -1 ? blendMode : clip.blendMode;

        var tracks = clip.tracks;
        var nTracks = tracks.length;
        this._interpolants = new Array<Interpolant>(nTracks);
        this._interpolantSettings = {
            endingStart: ZeroCurvatureEnding,
            endingEnd: ZeroCurvatureEnding
        };

        for (var i:Int = 0; i < nTracks; i++) {
            var interpolant = tracks[i].createInterpolant(null);
            this._interpolants[i] = interpolant;
            interpolant.settings = this._interpolantSettings;
        }

        this._propertyBindings = new Array<Dynamic>(nTracks);
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
        this.repetitions = Float.POSITIVE_INFINITY;
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

    public function setLoop(mode:Int, repetitions:Int):AnimationAction {
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

    public function fadeIn(duration:Float):AnimationAction {
        return this._scheduleFading(duration, 0, 1);
    }

    public function fadeOut(duration:Float):AnimationAction {
        return this._scheduleFading(duration, 1, 0);
    }

    public function crossFadeFrom(fadeOutAction:AnimationAction, duration:Float, warp:Bool):AnimationAction {
        fadeOutAction.fadeOut(duration);
        this.fadeIn(duration);

        if (warp) {
            var fadeInDuration = this._clip.duration;
            var fadeOutDuration = fadeOutAction._clip.duration;
            var startEndRatio = fadeOutDuration / fadeInDuration;
            var endStartRatio = fadeInDuration / fadeOutDuration;
            fadeOutAction.warp(1.0, startEndRatio, duration);
            this.warp(endStartRatio, 1.0, duration);
        }

        return this;
    }

    public function crossFadeTo(fadeInAction:AnimationAction, duration:Float, warp:Bool):AnimationAction {
        return fadeInAction.crossFadeFrom(this, duration, warp);
    }

    public function stopFading():AnimationAction {
        var weightInterpolant = this._weightInterpolant;

        if (weightInterpolant != null) {
            this._weightInterpolant = null;
            this._mixer._takeBackControlInterpolant(weightInterpolant);
        }

        return this;
    }

    public function setEffectiveTimeScale(timeScale:Float):AnimationAction {
        this.timeScale = timeScale;
        this._effectiveTimeScale = this.paused ? 0 : timeScale;
        return this.stopWarping();
    }

    public function getEffectiveTimeScale():Float {
        return this._effectiveTimeScale;
    }

    public function setDuration(duration:Float):AnimationAction {
        this.timeScale = this._clip.duration / duration;
        return this.stopWarping();
    }

    public function syncWith(action:AnimationAction):AnimationAction {
        this.time = action.time;
        this.timeScale = action.timeScale;
        return this.stopWarping();
    }

    public function halt(duration:Float):AnimationAction {
        return this.warp(this._effectiveTimeScale, 0, duration);
    }

    public function warp(startTimeScale:Float, endTimeScale:Float, duration:Float):AnimationAction {
        var mixer = this._mixer;
        var now = mixer.time;
        var timeScale = this.timeScale;
        var interpolant = this._timeScaleInterpolant;

        if (interpolant == null) {
            interpolant = mixer._lendControlInterpolant();
            this._timeScaleInterpolant = interpolant;
        }

        var times = interpolant.parameterPositions;
        var values = interpolant.sampleValues;
        times[0] = now;
        times[1] = now + duration;
        values[0] = startTimeScale / timeScale;
        values[1] = endTimeScale / timeScale;

        return this;
    }

    public function stopWarping():AnimationAction {
        var timeScaleInterpolant = this._timeScaleInterpolant;

        if (timeScaleInterpolant != null) {
            this._timeScaleInterpolant = null;
            this._mixer._takeBackControlInterpolant(timeScaleInterpolant);
        }

        return this;
    }

    public function getMixer():Mixer {
        return this._mixer;
    }

    public function getClip():Clip {
        return this._clip;
    }

    public function getRoot():Dynamic {
        return this._localRoot != null ? this._localRoot : this._mixer._root;
    }

    // ... (_update, _updateWeight, _updateTimeScale, _updateTime, _setEndings, _scheduleFading methods omitted for brevity)
}