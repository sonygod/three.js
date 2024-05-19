package three.animation;

import three.constants.WrapAroundEnding;
import three.constants.ZeroCurvatureEnding;
import three.constants.ZeroSlopeEnding;
import three.constants.LoopPingPong;
import three.constants.LoopOnce;
import three.constants.LoopRepeat;
import three.constants.NormalAnimationBlendMode;
import three.constants.AdditiveAnimationBlendMode;

class AnimationAction {
    private var _mixer:Dynamic;
    private var _clip:Dynamic;
    private var _localRoot:Dynamic;
    private var blendMode:Int;

    private var _interpolants:Array<Dynamic>;
    private var _propertyBindings:Array<Dynamic>;
    private var _cacheIndex:Null<Int>;
    private var _byClipCacheIndex:Null<Int>;

    private var _timeScaleInterpolant:Dynamic;
    private var _weightInterpolant:Dynamic;

    private var loop:Int;
    private var _loopCount:Int;
    private var _startTime:Null<Float>;

    private var time:Float;
    private var timeScale:Float;
    private var _effectiveTimeScale:Float;

    private var weight:Float;
    private var _effectiveWeight:Float;

    private var repetitions:Int;
    private var paused:Bool;
    private var enabled:Bool;

    private var clampWhenFinished:Bool;
    private var zeroSlopeAtStart:Bool;
    private var zeroSlopeAtEnd:Bool;

    public function new(mixer:Dynamic, clip:Dynamic, localRoot:Dynamic = null, blendMode:Int = -1) {
        _mixer = mixer;
        _clip = clip;
        _localRoot = localRoot;
        this.blendMode = blendMode;

        var tracks:Array<Dynamic> = clip.tracks;
        var nTracks:Int = tracks.length;
        _interpolants = new Array<Dynamic>(nTracks);

        var interpolantSettings:Dynamic = {
            endingStart: ZeroCurvatureEnding,
            endingEnd: ZeroCurvatureEnding
        };

        for (i in 0...nTracks) {
            var interpolant:Dynamic = tracks[i].createInterpolant(null);
            _interpolants[i] = interpolant;
            interpolant.settings = interpolantSettings;
        }

        _propertyBindings = new Array<Dynamic>(nTracks);
        _cacheIndex = null;
        _byClipCacheIndex = null;

        _timeScaleInterpolant = null;
        _weightInterpolant = null;

        loop = LoopRepeat;
        _loopCount = -1;

        _startTime = null;

        time = 0;
        timeScale = 1;
        _effectiveTimeScale = 1;

        weight = 1;
        _effectiveWeight = 1;

        repetitions = Math.POSITIVE_INFINITY;
        paused = false;
        enabled = true;

        clampWhenFinished = false;
        zeroSlopeAtStart = true;
        zeroSlopeAtEnd = true;
    }

    public function play():AnimationAction {
        _mixer._activateAction(this);
        return this;
    }

    public function stop():AnimationAction {
        _mixer._deactivateAction(this);
        return reset();
    }

    public function reset():AnimationAction {
        paused = false;
        enabled = true;

        time = 0;
        _loopCount = -1;
        _startTime = null;

        return stopFading().stopWarping();
    }

    public function isRunning():Bool {
        return enabled && !paused && timeScale != 0 && _startTime == null && _mixer._isActiveAction(this);
    }

    public function isScheduled():Bool {
        return _mixer._isActiveAction(this);
    }

    public function startAt(time:Float):AnimationAction {
        _startTime = time;
        return this;
    }

    public function setLoop(mode:Int, repetitions:Int):AnimationAction {
        loop = mode;
        this.repetitions = repetitions;
        return this;
    }

    public function setEffectiveWeight(weight:Float):AnimationAction {
        this.weight = weight;
        _effectiveWeight = enabled ? weight : 0;
        return stopFading();
    }

    public function getEffectiveWeight():Float {
        return _effectiveWeight;
    }

    public function fadeIn(duration:Float):AnimationAction {
        return _scheduleFading(duration, 0, 1);
    }

    public function fadeOut(duration:Float):AnimationAction {
        return _scheduleFading(duration, 1, 0);
    }

    public function crossFadeFrom(fadeOutAction:AnimationAction, duration:Float, warp:Bool):AnimationAction {
        fadeOutAction.fadeOut(duration);
        fadeIn(duration);

        if (warp) {
            var fadeInDuration:Float = _clip.duration;
            var fadeOutDuration:Float = fadeOutAction._clip.duration;

            var startEndRatio:Float = fadeOutDuration / fadeInDuration;
            var endStartRatio:Float = fadeInDuration / fadeOutDuration;

            fadeOutAction.warp(1.0, startEndRatio, duration);
            warp(endStartRatio, 1.0, duration);
        }

        return this;
    }

    public function crossFadeTo(fadeInAction:AnimationAction, duration:Float, warp:Bool):AnimationAction {
        return fadeInAction.crossFadeFrom(this, duration, warp);
    }

    public function stopFading():AnimationAction {
        var weightInterpolant:Dynamic = _weightInterpolant;
        if (weightInterpolant != null) {
            _weightInterpolant = null;
            _mixer._takeBackControlInterpolant(weightInterpolant);
        }
        return this;
    }

    public function setEffectiveTimeScale(timeScale:Float):AnimationAction {
        this.timeScale = timeScale;
        _effectiveTimeScale = paused ? 0 : timeScale;
        return stopWarping();
    }

    public function getEffectiveTimeScale():Float {
        return _effectiveTimeScale;
    }

    public function setDuration(duration:Float):AnimationAction {
        timeScale = _clip.duration / duration;
        return stopWarping();
    }

    public function syncWith(action:AnimationAction):AnimationAction {
        time = action.time;
        timeScale = action.timeScale;
        return stopWarping();
    }

    public function halt(duration:Float):AnimationAction {
        return warp(_effectiveTimeScale, 0, duration);
    }

    public function warp(startTimeScale:Float, endTimeScale:Float, duration:Float):AnimationAction {
        var mixer:Dynamic = _mixer;
        var now:Float = mixer.time;
        var timeScale:Float = this.timeScale;

        var interpolant:Dynamic = _timeScaleInterpolant;
        if (interpolant == null) {
            interpolant = mixer._lendControlInterpolant();
            _timeScaleInterpolant = interpolant;
        }

        var times:Array<Float> = interpolant.parameterPositions;
        var values:Array<Float> = interpolant.sampleValues;

        times[0] = now;
        times[1] = now + duration;

        values[0] = startTimeScale / timeScale;
        values[1] = endTimeScale / timeScale;

        return this;
    }

    public function stopWarping():AnimationAction {
        var timeScaleInterpolant:Dynamic = _timeScaleInterpolant;
        if (timeScaleInterpolant != null) {
            _timeScaleInterpolant = null;
            _mixer._takeBackControlInterpolant(timeScaleInterpolant);
        }
        return this;
    }

    public function getMixer():Dynamic {
        return _mixer;
    }

    public function getClip():Dynamic {
        return _clip;
    }

    public function getRoot():Dynamic {
        return _localRoot || _mixer._root;
    }

    private function _update(time:Float, deltaTime:Float, timeDirection:Float, accuIndex:Int):Void {
        if (!enabled) {
            _updateWeight(time);
            return;
        }

        var startTime:Null<Float> = _startTime;

        if (startTime != null) {
            var timeRunning:Float = (time - startTime) * timeDirection;
            if (timeRunning < 0 || timeDirection == 0) {
                deltaTime = 0;
            } else {
                _startTime = null; // unschedule
                deltaTime = timeDirection * timeRunning;
            }
        }

        deltaTime *= _updateTimeScale(time);
        var clipTime:Float = _updateTime(deltaTime);

        if (_effectiveWeight > 0) {
            var interpolants:Array<Dynamic> = _interpolants;
            var propertyMixers:Array<Dynamic> = _propertyBindings;

            switch (blendMode) {
                case AdditiveAnimationBlendMode:
                    for (i in 0...interpolants.length) {
                        interpolants[i].evaluate(clipTime);
                        propertyMixers[i].accumulateAdditive(_effectiveWeight);
                    }
                    break;
                case NormalAnimationBlendMode:
                default:
                    for (i in 0...interpolants.length) {
                        interpolants[i].evaluate(clipTime);
                        propertyMixers[i].accumulate(accuIndex, _effectiveWeight);
                    }
            }
        }
    }

    private function _updateWeight(time:Float):Float {
        var weight:Float = 0;

        if (enabled) {
            weight = this.weight;
            var interpolant:Dynamic = _weightInterpolant;

            if (interpolant != null) {
                var interpolantValue:Float = interpolant.evaluate(time)[0];
                weight *= interpolantValue;

                if (time > interpolant.parameterPositions[1]) {
                    stopFading();

                    if (interpolantValue == 0) {
                        enabled = false;
                    }
                }
            }
        }

        _effectiveWeight = weight;
        return weight;
    }

    private function _updateTimeScale(time:Float):Float {
        var timeScale:Float = 0;

        if (!paused) {
            timeScale = this.timeScale;
            var interpolant:Dynamic = _timeScaleInterpolant;

            if (interpolant != null) {
                var interpolantValue:Float = interpolant.evaluate(time)[0];
                timeScale *= interpolantValue;

                if (time > interpolant.parameterPositions[1]) {
                    stopWarping();

                    if (timeScale == 0) {
                        paused = true;
                    } else {
                        this.timeScale = timeScale;
                    }
                }
            }
        }

        _effectiveTimeScale = timeScale;
        return timeScale;
    }

    private function _updateTime(deltaTime:Float):Float {
        var duration:Float = _clip.duration;
        var loop:Int = loop;

        var time:Float = this.time + deltaTime;
        var loopCount:Int = _loopCount;

        var pingPong:Bool = (loop == LoopPingPong);

        if (deltaTime == 0) {
            if (loopCount == -1) return time;
            return (pingPong && (loopCount & 1) == 1) ? duration - time : time;
        }

        if (loop == LoopOnce) {
            if (loopCount == -1) {
                _loopCount = 0;
                _setEndings(true, true, false);
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

                if (clampWhenFinished) paused = true;
                else enabled = false;

                this.time = time;

                _mixer.dispatchEvent({
                    type: 'finished',
                    action: this,
                    direction: deltaTime < 0 ? -1 : 1
                });
            }
        } else {
            if (loopCount == -1) {
                if (deltaTime >= 0) {
                    loopCount = 0;
                    _setEndings(true, repetitions == 0, pingPong);
                } else {
                    _setEndings(repetitions == 0, true, pingPong);
                }
            }

            if (time >= duration || time < 0) {
                var loopDelta:Int = Math.floor(time / duration);
                time -= duration * loopDelta;

                loopCount += Math.abs(loopDelta);

                var pending:Int = repetitions - loopCount;

                if (pending <= 0) {
                    if (clampWhenFinished) paused = true;
                    else enabled = false;

                    time = deltaTime > 0 ? duration : 0;

                    this.time = time;

                    _mixer.dispatchEvent({
                        type: 'finished',
                        action: this,
                        direction: deltaTime > 0 ? 1 : -1
                    });
                } else {
                    if (pending == 1) {
                        _setEndings(false, false, pingPong);
                    } else {
                        _setEndings(false, false, pingPong);
                    }

                    _loopCount = loopCount;

                    this.time = time;

                    _mixer.dispatchEvent({
                        type: 'loop',
                        action: this,
                        loopDelta: loopDelta
                    });
                }
            } else {
                this.time = time;
            }

            if (pingPong && (loopCount & 1) == 1) {
                return duration - time;
            }
        }

        return time;
    }

    private function _setEndings(atStart:Bool, atEnd:Bool, pingPong:Bool):Void {
        var settings:Dynamic = _interpolantSettings;

        if (pingPong) {
            settings.endingStart = ZeroSlopeEnding;
            settings.endingEnd = ZeroSlopeEnding;
        } else {
            if (atStart) {
                settings.endingStart = zeroSlopeAtStart ? ZeroSlopeEnding : ZeroCurvatureEnding;
            } else {
                settings.endingStart = WrapAroundEnding;
            }

            if (atEnd) {
                settings.endingEnd = zeroSlopeAtEnd ? ZeroSlopeEnding : ZeroCurvatureEnding;
            } else {
                settings.endingEnd = WrapAroundEnding;
            }
        }
    }

    private function _scheduleFading(duration:Float, weightNow:Float, weightThen:Float):AnimationAction {
        var mixer:Dynamic = _mixer;
        var now:Float = mixer.time;
        var interpolant:Dynamic = _weightInterpolant;

        if (interpolant == null) {
            interpolant = mixer._lendControlInterpolant();
            _weightInterpolant = interpolant;
        }

        var times:Array<Float> = interpolant.parameterPositions;
        var values:Array<Float> = interpolant.sampleValues;

        times[0] = now;
        values[0] = weightNow;
        times[1] = now + duration;
        values[1] = weightThen;

        return this;
    }
}