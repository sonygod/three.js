import three.constants.WrapAroundEnding;
import three.constants.ZeroCurvatureEnding;
import three.constants.ZeroSlopeEnding;
import three.constants.LoopPingPong;
import three.constants.LoopOnce;
import three.constants.LoopRepeat;
import three.constants.NormalAnimationBlendMode;
import three.constants.AdditiveAnimationBlendMode;

class AnimationAction {

    public var blendMode:Int;
    public var loop:Int;
    public var repetitions:Float;
    public var paused:Bool;
    public var enabled:Bool;
    public var clampWhenFinished:Bool;
    public var zeroSlopeAtStart:Bool;
    public var zeroSlopeAtEnd:Bool;

    private var _mixer:Dynamic;
    private var _clip:Dynamic;
    private var _localRoot:Dynamic;
    private var _interpolantSettings:Dynamic;
    private var _interpolants:Array<Dynamic>;
    private var _propertyBindings:Array<Dynamic>;
    private var _cacheIndex:Dynamic;
    private var _byClipCacheIndex:Dynamic;
    private var _timeScaleInterpolant:Dynamic;
    private var _weightInterpolant:Dynamic;
    private var _loopCount:Int;
    private var _startTime:Dynamic;
    public var time:Float;
    public var timeScale:Float;
    private var _effectiveTimeScale:Float;
    public var weight:Float;
    private var _effectiveWeight:Float;

    public function new(mixer:Dynamic, clip:Dynamic, ?localRoot:Dynamic, ?blendMode:Int) {
        this._mixer = mixer;
        this._clip = clip;
        this._localRoot = localRoot;
        this.blendMode = blendMode != null ? blendMode : clip.blendMode;

        var tracks = clip.tracks;
        var nTracks = tracks.length;
        this._interpolants = new Array<Dynamic>(nTracks);
        this._interpolantSettings = { endingStart: ZeroCurvatureEnding, endingEnd: ZeroCurvatureEnding };

        for (i in 0...nTracks) {
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
        this.repetitions = Math.POSITIVE_INFINITY;
        this.paused = false;
        this.enabled = true;
        this.clampWhenFinished = false;
        this.zeroSlopeAtStart = true;
        this.zeroSlopeAtEnd = true;
    }

    // State & Scheduling

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

    // Weight

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
        if (this._weightInterpolant != null) {
            this._weightInterpolant = null;
            this._mixer._takeBackControlInterpolant(this._weightInterpolant);
        }
        return this;
    }

    // Time Scale Control

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
        var now = this._mixer.time;
        var timeScale = this.timeScale;

        if (this._timeScaleInterpolant == null) {
            this._timeScaleInterpolant = this._mixer._lendControlInterpolant();
        }

        var times = this._timeScaleInterpolant.parameterPositions;
        var values = this._timeScaleInterpolant.sampleValues;

        times[0] = now;
        times[1] = now + duration;

        values[0] = startTimeScale / timeScale;
        values[1] = endTimeScale / timeScale;

        return this;
    }

    public function stopWarping():AnimationAction {
        if (this._timeScaleInterpolant != null) {
            this._timeScaleInterpolant = null;
            this._mixer._takeBackControlInterpolant(this._timeScaleInterpolant);
        }
        return this;
    }

    // Object Accessors

    public function getMixer():Dynamic {
        return this._mixer;
    }

    public function getClip():Dynamic {
        return this._clip;
    }

    public function getRoot():Dynamic {
        return this._localRoot != null ? this._localRoot : this._mixer._root;
    }

    // Internal

    public function _update(time:Float, deltaTime:Float, timeDirection:Int, accuIndex:Int):Void {
        if (!this.enabled) {
            this._updateWeight(time);
            return;
        }

        if (this._startTime != null) {
            var timeRunning = (time - this._startTime) * timeDirection;
            if (timeRunning < 0 || timeDirection == 0) {
                deltaTime = 0;
            } else {
                this._startTime = null;
                deltaTime = timeDirection * timeRunning;
            }
        }

        deltaTime *= this._updateTimeScale(time);
        var clipTime = this._updateTime(deltaTime);

        var weight = this._updateWeight(time);

        if (weight > 0) {
            var interpolants = this._interpolants;
            var propertyMixers = this._propertyBindings;

            switch (this.blendMode) {
                case AdditiveAnimationBlendMode:
                    for (i in 0...interpolants.length) {
                        interpolants[i].evaluate(clipTime);
                        propertyMixers[i].accumulateAdditive(weight);
                    }
                    break;
                case NormalAnimationBlendMode:
                default:
                    for (i in 0...interpolants.length) {
                        interpolants[i].evaluate(clipTime);
                        propertyMixers[i].accumulate(accuIndex, weight);
                    }
            }
        }
    }

    private function _updateWeight(time:Float):Float {
        var weight = 0;

        if (this._weightInterpolant != null) {
            weight = this._weightInterpolant.evaluate(time)[0];
            this._effectiveWeight = this.enabled ? weight : 0;

            if (time > this._weightInterpolant.parameterPositions[1]) {
                this.stopFading();
            }
        } else {
            weight = this._effectiveWeight;
        }

        return weight;
    }

    private function _updateTimeScale(time:Float):Float {
        var timeScale = 0;

        if (this._timeScaleInterpolant != null) {
            timeScale = this._timeScaleInterpolant.evaluate(time)[0];

            this._effectiveTimeScale = this.paused ? 0 : timeScale * this.timeScale;

            if (time > this._timeScaleInterpolant.parameterPositions[1]) {
                this.stopWarping();
            }
        } else {
            timeScale = this.timeScale;
            this._effectiveTimeScale = this.paused ? 0 : timeScale;
        }

        return this._effectiveTimeScale;
    }

    private function _updateTime(deltaTime:Float):Float {
        var duration = this._clip.duration;
        var loop = this.loop;
        var time = this.time + deltaTime;
        var loopCount = this._loopCount;

        if (deltaTime == 0) {
            if (loop == LoopPingPong) {
                var phase = (loopCount % 2);
                return (phase == 0) ? time : (duration - time);
            }

            return time;
        }

        if (loop == LoopOnce) {
            if (loopCount == -1) {
                this._loopCount = 0;
                this._setEndings(true, true, false);
            }

            if (time >= duration || time < 0) {
                if (this.clampWhenFinished) {
                    this.paused = true;
                    time = Math.max(0, Math.min(time, duration));
                } else {
                    this.enabled = false;
                    time = 0;
                }

                this._mixer._deactivateAction(this);
                this._setEndings(true, true, true);
            }
        } else {
            var pingPong = (loop == LoopPingPong);

            if (loopCount == -1) {
                if (deltaTime > 0) {
                    loopCount = 0;
                    this._setEndings(true, this.repetitions == 0, pingPong);
                } else {
                    this._setEndings(this.repetitions == 0, true, pingPong);
                }
            }

            if (time >= duration || time < 0) {
                var loopDelta = Math.floor(time / duration);
                time -= duration * loopDelta;
                loopCount += Math.abs(loopDelta);
                var pending = this.repetitions - loopCount;

                if (pending < 0) {
                    if (this.clampWhenFinished) {
                        this.paused = true;
                        time = (deltaTime > 0) ? duration : 0;
                    } else {
                        this.enabled = false;
                        time = 0;
                    }

                    this._mixer._deactivateAction(this);
                    this._setEndings(true, true, pingPong);
                } else {
                    if (pending == 0) {
                        var atStart = (deltaTime < 0);
                        this._setEndings(atStart, !atStart, pingPong);
                    } else {
                        this._setEndings(false, false, pingPong);
                    }

                    this._loopCount = loopCount;
                    this._mixer.dispatchEvent({
                        type: "loop", action: this, loopDelta: loopDelta
                    });

                    if (pingPong && (loopCount & 1) == 1) {
                        this.time = time;
                        return duration - time;
                    }
                }
            }
        }

        this.time = time;
        return time;
    }

    private function _setEndings(atStart:Bool, atEnd:Bool, pingPong:Bool):Void {
        var settings = this._interpolantSettings;

        if (pingPong) {
            settings.endingStart = ZeroSlopeEnding;
            settings.endingEnd = ZeroSlopeEnding;
        } else {
            if (atStart) {
                settings.endingStart = this.zeroSlopeAtStart ? ZeroSlopeEnding : ZeroCurvatureEnding;
            } else {
                settings.endingStart = WrapAroundEnding;
            }

            if (atEnd) {
                settings.endingEnd = this.zeroSlopeAtEnd ? ZeroSlopeEnding : ZeroCurvatureEnding;
            } else {
                settings.endingEnd = WrapAroundEnding;
            }
        }
    }
}