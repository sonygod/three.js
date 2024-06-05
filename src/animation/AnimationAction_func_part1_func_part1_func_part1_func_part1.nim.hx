import three.animation.constants.WrapAroundEnding;
import three.animation.constants.ZeroCurvatureEnding;
import three.animation.constants.ZeroSlopeEnding;
import three.animation.constants.LoopPingPong;
import three.animation.constants.LoopOnce;
import three.animation.constants.LoopRepeat;
import three.animation.constants.NormalAnimationBlendMode;
import three.animation.constants.AdditiveAnimationBlendMode;

class AnimationAction {

    public var _mixer(default, null):AnimationMixer;
    public var _clip(default, null):AnimationClip;
    public var _localRoot(default, null):Object;
    public var blendMode(default, null):Int;

    public var _interpolantSettings(default, null):InterpolantSettings;
    public var _interpolants(default, null):Array<Interpolant>;
    public var _propertyBindings(default, null):Array<PropertyMixer>;
    public var _cacheIndex(default, null):Int;
    public var _byClipCacheIndex(default, null):Int;
    public var _timeScaleInterpolant(default, null):Interpolant;
    public var _weightInterpolant(default, null):Interpolant;

    public var loop(default, LoopRepeat):Int;
    public var _loopCount(default, -1):Int;
    public var _startTime(default, null):Float;
    public var time(default, 0):Float;
    public var timeScale(default, 1):Float;
    public var _effectiveTimeScale(default, 1):Float;
    public var weight(default, 1):Float;
    public var _effectiveWeight(default, 1):Float;
    public var repetitions(default, Infinity):Float;
    public var paused(default, false):Bool;
    public var enabled(default, true):Bool;
    public var clampWhenFinished(default, false):Bool;
    public var zeroSlopeAtStart(default, true):Bool;
    public var zeroSlopeAtEnd(default, true):Bool;

    public function new(mixer:AnimationMixer, clip:AnimationClip, localRoot:Object = null, blendMode:Int = clip.blendMode) {
        this._mixer = mixer;
        this._clip = clip;
        this._localRoot = localRoot;
        this.blendMode = blendMode;

        const tracks = clip.tracks;
        const nTracks = tracks.length;
        const interpolants = new Array<Interpolant>();

        const interpolantSettings = {
            endingStart: ZeroCurvatureEnding,
            endingEnd: ZeroCurvatureEnding
        };

        for (i in 0...nTracks) {
            const interpolant = tracks[i].createInterpolant(null);
            interpolants[i] = interpolant;
            interpolant.settings = interpolantSettings;
        }

        this._interpolantSettings = interpolantSettings;
        this._interpolants = interpolants;
        this._propertyBindings = new Array<PropertyMixer>();
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
        return this.enabled && !this.paused && this.timeScale !== 0 &&
            this._startTime === null && this._mixer._isActiveAction(this);
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
            const fadeInDuration = this._clip.duration;
            const fadeOutDuration = fadeOutAction._clip.duration;

            const startEndRatio = fadeOutDuration / fadeInDuration;
            const endStartRatio = fadeInDuration / fadeOutDuration;

            fadeOutAction.warp(1.0, startEndRatio, duration);
            this.warp(endStartRatio, 1.0, duration);
        }

        return this;
    }

    public function crossFadeTo(fadeInAction:AnimationAction, duration:Float, warp:Bool):AnimationAction {
        return fadeInAction.crossFadeFrom(this, duration, warp);
    }

    public function stopFading():AnimationAction {
        const weightInterpolant = this._weightInterpolant;

        if (weightInterpolant !== null) {
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
        const mixer = this._mixer;
        const now = mixer.time;
        const timeScale = this.timeScale;

        let interpolant = this._timeScaleInterpolant;

        if (interpolant === null) {
            interpolant = mixer._lendControlInterpolant();
            this._timeScaleInterpolant = interpolant;
        }

        const times = interpolant.parameterPositions;
        const values = interpolant.sampleValues;

        times[0] = now;
        times[1] = now + duration;

        values[0] = startTimeScale / timeScale;
        values[1] = endTimeScale / timeScale;

        return this;
    }

    public function stopWarping():AnimationAction {
        const timeScaleInterpolant = this._timeScaleInterpolant;

        if (timeScaleInterpolant !== null) {
            this._timeScaleInterpolant = null;
            this._mixer._takeBackControlInterpolant(timeScaleInterpolant);
        }

        return this;
    }

    public function getMixer():AnimationMixer {
        return this._mixer;
    }

    public function getClip():AnimationClip {
        return this._clip;
    }

    public function getRoot():Object {
        return this._localRoot || this._mixer._root;
    }

    public function _update(time:Float, deltaTime:Float, timeDirection:Float, accuIndex:Int) {
        // called by the mixer

        if (!this.enabled) {
            // call ._updateWeight() to update ._effectiveWeight
            this._updateWeight(time);
            return;
        }

        const startTime = this._startTime;

        if (startTime !== null) {
            // check for scheduled start of action

            const timeRunning = (time - startTime) * timeDirection;
            if (timeRunning < 0 || timeDirection === 0) {
                deltaTime = 0;
            } else {
                this._startTime = null; // unschedule
                deltaTime = timeDirection * timeRunning;
            }
        }

        // apply time scale and advance time

        deltaTime *= this._updateTimeScale(time);
        const clipTime = this._updateTime(deltaTime);

        // note: _updateTime may disable the action resulting in
        // an effective weight of 0

        const weight = this._updateWeight(time);

        if (weight > 0) {
            const interpolants = this._interpolants;
            const propertyMixers = this._propertyBindings;

            switch (this.blendMode) {
                case AdditiveAnimationBlendMode:
                    for (j in 0...interpolants.length) {
                        interpolants[j].evaluate(clipTime);
                        propertyMixers[j].accumulateAdditive(weight);
                    }
                    break;
                case NormalAnimationBlendMode:
                default:
                    for (j in 0...interpolants.length) {
                        interpolants[j].evaluate(clipTime);
                        propertyMixers[j].accumulate(accuIndex, weight);
                    }
            }
        }
    }

    public function _updateWeight(time:Float):Float {
        let weight = 0;

        if (this.enabled) {
            weight = this.weight;
            const interpolant = this._weightInterpolant;

            if (interpolant !== null) {
                const interpolantValue = interpolant.evaluate(time)[0];

                weight *= interpolantValue;

                if (time > interpolant.parameterPositions[1]) {
                    this.stopFading();

                    if (interpolantValue === 0) {
                        // faded out, disable
                        this.enabled = false;
                    }
                }
            }
        }

        this._effectiveWeight = weight;
        return weight;
    }

    public function _updateTimeScale(time:Float):Float {
        let timeScale = 0;

        if (!this.paused) {
            timeScale = this.timeScale;

            const interpolant = this._timeScaleInterpolant;

            if (interpolant !== null) {
                const interpolantValue = interpolant.evaluate(time)[0];

                timeScale *= interpolantValue;

                if (time > interpolant.parameterPositions[1]) {
                    this.stopWarping();

                    if (timeScale === 0) {
                        // motion has halted, pause
                        this.paused = true;
                    } else {
                        // warp done - apply final time scale
                        this.timeScale = timeScale;
                    }
                }
            }
        }

        this._effectiveTimeScale = timeScale;
        return timeScale;
    }

    public function _updateTime(deltaTime:Float):Float {
        const duration = this._clip.duration;
        const loop = this.loop;

        let time = this.time + deltaTime;
        let loopCount = this._loopCount;

        const pingPong = (loop === LoopPingPong);

        if (deltaTime === 0) {
            if (loopCount === -1) return time;

            return (pingPong && (loopCount & 1) === 1) ? duration - time : time;
        }

        if (loop === LoopOnce) {
            if (loopCount === -1) {
                // just started
                this._loopCount = 0;
                this._setEndings(true, true, false);
            }

            handle_stop: {
                if (time >= duration) {
                    time = duration;
                } else if (time < 0) {
                    time = 0;
                } else {
                    this.time = time;
                    break handle_stop;
                }

                if (this.clampWhenFinished) this.paused = true;
                else this.enabled = false;

                this.time = time;

                this._mixer.dispatchEvent({
                    type: 'finished', action: this,
                    direction: deltaTime < 0 ? -1 : 1
                });
            }
        } else { // repetitive Repeat or PingPong
            if (loopCount === -1) {
                // just started
                if (deltaTime >= 0) {
                    loopCount = 0;
                    this._setEndings(true, this.repetitions === 0, pingPong);
                } else {
                    // when looping in reverse direction, the initial
                    // transition through zero counts as a repetition,
                    // so leave loopCount at -1
                    this._setEndings(this.repetitions === 0, true, pingPong);
                }
            }

            if (time >= duration || time < 0) {
                // wrap around
                const loopDelta = Math.floor(time / duration); // signed
                time -= duration * loopDelta;

                loopCount += Math.abs(loopDelta);

                const pending = this.repetitions - loopCount;

                if (pending <= 0) {
                    // have to stop (switch state, clamp time, fire event)
                    if (this.clampWhenFinished) this.paused = true;
                    else this.enabled = false;

                    time = deltaTime > 0 ? duration : 0;

                    this.time = time;

                    this._mixer.dispatchEvent({
                        type: 'finished', action: this,
                        direction: deltaTime > 0 ? 1 : -1
                    });
                } else {
                    // keep running
                    if (pending === 1) {
                        // entering the last round
                        const atStart = deltaTime < 0;
                        this._setEndings(atStart, !atStart, pingPong);
                    } else {
                        this._setEndings(false, false, pingPong);
                    }

                    this._loopCount = loopCount;

                    this.time = time;

                    this._mixer.dispatchEvent({
                        type: 'loop', action: this, loopDelta: loopDelta
                    });
                }
            } else {
                this.time = time;
            }

            if (pingPong && (loopCount & 1) === 1) {
                // invert time for the "pong round"
                return duration - time;
            }
        }

        return time;
    }

    public function _setEndings(atStart:Bool, atEnd:Bool, pingPong:Bool) {
        const settings = this._interpolantSettings;

        if (pingPong) {
            settings.endingStart = ZeroSlopeEnding;
            settings.endingEnd = ZeroSlopeEnding;
        } else {
            // assuming for LoopOnce atStart == atEnd == true
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

    public function _scheduleFading(duration:Float, weightNow:Float, weightThen:Float):AnimationAction {
        const mixer = this._mixer;
        const now = mixer.time;
        let interpolant = this._weightInterpolant;

        if (interpolant === null) {
            interpolant = mixer._lendControlInterpolant();
            this._weightInterpolant = interpolant;
        }

        const times = interpolant.parameterPositions;
        const values = interpolant.sampleValues;

        times[0] = now;
        values[0] = weightNow;
        times[1] = now + duration;
        values[1] = weightThen;

        return this;
    }

}