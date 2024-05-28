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
    private var _blendMode:Int;
    private var _interpolantSettings:Dynamic;
    private var _interpolants:Array<Dynamic>;
    private var _propertyBindings:Array<Dynamic>;
    private var _cacheIndex:Null<Int>;
    private var _byClipCacheIndex:Null<Int>;
    private var _timeScaleInterpolant:Null<Dynamic>;
    private var _weightInterpolant:Null<Dynamic>;
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
    private var loop:Int;

    public function new(mixer:Dynamic, clip:Dynamic, ?localRoot:Dynamic, ?blendMode:Int) {
        _mixer = mixer;
        _clip = clip;
        _localRoot = localRoot;
        _blendMode = blendMode != null ? blendMode : clip.blendMode;

        var tracks:Array<Dynamic> = clip.tracks;
        var nTracks:Int = tracks.length;
        _interpolants = new Array<Dynamic>(nTracks);
        _interpolantSettings = {
            endingStart: ZeroCurvatureEnding,
            endingEnd: ZeroCurvatureEnding
        };

        for (i in 0...nTracks) {
            var interpolant = tracks[i].createInterpolant(null);
            _interpolants[i] = interpolant;
            interpolant.settings = _interpolantSettings;
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

        repetitions = Math.POSITIVE_INFINITY; // no. of repetitions when looping

        paused = false; // true -> zero effective time scale
        enabled = true; // false -> zero effective weight

        clampWhenFinished = false; // keep feeding the last frame?

        zeroSlopeAtStart = true; // for smooth interpolation w/o separate clips for start, loop and end
        zeroSlopeAtEnd = true;
    }

    // State & Scheduling

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

        time = 0; // restart clip
        _loopCount = -1; // forget previous loops
        _startTime = null; // forget scheduling

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

    // Weight

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
            var fadeInDuration:Float = _clip.duration,
                fadeOutDuration:Float = fadeOutAction._clip.duration,

                startEndRatio:Float = fadeOutDuration / fadeInDuration,
                endStartRatio:Float = fadeInDuration / fadeOutDuration;

            fadeOutAction.warp(1.0, startEndRatio, duration);
            this.warp(endStartRatio, 1.0, duration);
        }

        return this;
    }

    public function crossFadeTo(fadeInAction:AnimationAction, duration:Float, warp:Bool):AnimationAction {
        return fadeInAction.crossFadeFrom(this, duration, warp);
    }

    public function stopFading():AnimationAction {
        var weightInterpolant = _weightInterpolant;

        if (weightInterpolant != null) {
            _weightInterpolant = null;
            _mixer._takeBackControlInterpolant(weightInterpolant);
        }

        return this;
    }

    // Time Scale Control

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
        var mixer = _mixer, now = mixer.time, timeScale = this.timeScale;
        var interpolant = _timeScaleInterpolant;

        if (interpolant == null) {
            interpolant = mixer._lendControlInterpolant();
            _timeScaleInterpolant = interpolant;
        }

        var times = interpolant.parameterPositions,
            values = interpolant.sampleValues;

        times[0] = now;
        times[1] = now + duration;

        values[0] = startTimeScale / timeScale;
        values[1] = endTimeScale / timeScale;

        return this;
    }

    public function stopWarping():AnimationAction {
        var timeScaleInterpolant = _timeScaleInterpolant;

        if (timeScaleInterpolant != null) {
            _timeScaleInterpolant = null;
            _mixer._takeBackControlInterpolant(timeScaleInterpolant);
        }

        return this;
    }

    // Object Accessors

    public function getMixer():Dynamic {
        return _mixer;
    }

    public function getClip():Dynamic {
        return _clip;
    }

    public function getRoot():Dynamic {
        return _localRoot || _mixer._root;
    }

    // Interna

    public function _update(time:Float, deltaTime:Float, timeDirection:Float, accuIndex:Int):Void {
        if (!enabled) {
            _updateWeight(time);
            return;
        }

        var startTime = _startTime;

        if (startTime != null) {
            // check for scheduled start of action

            var timeRunning = (time - startTime) * timeDirection;
            if (timeRunning < 0 || timeDirection == 0) {
                deltaTime = 0;
            } else {
                _startTime = null; // unschedule
                deltaTime = timeDirection * timeRunning;
            }
        }

        // apply time scale and advance time

        deltaTime *= _updateTimeScale(time);
        var clipTime = _updateTime(deltaTime);

        // note: _updateTime may disable the action resulting in
        // an effective weight of 0

        var weight = _updateWeight(time);

        if (weight > 0) {
            var interpolants = _interpolants;
            var propertyMixers = _propertyBindings;

            switch (_blendMode) {
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

    private function _updateWeight(time:Float):Float {
        var weight = 0;

        if (enabled) {
            weight = this.weight;
            var interpolant = _weightInterpolant;

            if (interpolant != null) {
                var interpolantValue = interpolant.evaluate(time)[0];
                weight *= interpolantValue;

                if (time > interpolant.parameterPositions[1]) {
                    stopFading();

                    if (interpolantValue == 0) {
                        // faded out, disable
                        enabled = false;
                    }
                }
            }
        }

        _effectiveWeight = weight;
        return weight;
    }

    private function _updateTimeScale(time:Float):Float {
        var timeScale = 0;

        if (!paused) {
            timeScale = this.timeScale;

            var interpolant = _timeScaleInterpolant;

            if (interpolant != null) {
                var interpolantValue = interpolant.evaluate(time)[0];
                timeScale *= interpolantValue;

                if (time > interpolant.parameterPositions[1]) {
                    stopWarping();

                    if (timeScale == 0) {
                        // motion has halted, pause
                        paused = true;
                    } else {
                        // warp done - apply final time scale
                        this.timeScale = timeScale;
                    }
                }
            }
        }

        _effectiveTimeScale = timeScale;
        return timeScale;
    }

    private function _updateTime(deltaTime:Float):Float {
        var duration = _clip.duration;
        var loop = loop;

        var time = this.time + deltaTime;
        var loopCount = _loopCount;

        var pingPong = (loop == LoopPingPong);

        if (deltaTime == 0) {
            if (loopCount == -1) return time;

            return (pingPong && (loopCount & 1) == 1) ? duration - time : time;
        }

        if (loop == LoopOnce) {
            if (loopCount == -1) {
                // just started

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
        } else { // repetitive Repeat or PingPong
            if (loopCount == -1) {
                // just started

                if (deltaTime >= 0) {
                    loopCount = 0;

                    _setEndings(true, repetitions == 0, pingPong);

                } else {
                    // when looping in reverse direction, the initial
                    // transition through zero counts as a repetition,
                    // so leave loopCount at -1

                    _setEndings(repetitions == 0, true, pingPong);
                }
            }

            if (time >= duration || time < 0) {
                // wrap around

                var loopDelta = Math.floor(time / duration); // signed
                time -= duration * loopDelta;

                loopCount += Math.abs(loopDelta);

                var pending = repetitions - loopCount;

                if (pending <= 0) {
                    // have to stop (switch state, clamp time, fire event)

                    if (clampWhenFinished) paused = true;
                    else enabled = false;

                    time = deltaTime > 0 ? duration : 0;

                    this.time = time;

                    _mixer.dispatchEvent({
                        type: 'finished',
                        action: this,
                        direction: deltaTime > 0 ? 1 : - 1
                    });
                } else {
                    // keep running

                    if (pending == 1) {
                        // entering the last round

                        var atStart = deltaTime < 0;
                        _setEndings(atStart, !atStart, pingPong);
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
                // invert time for the "pong round"

                return duration - time;
            }
        }

        return time;
    }

    private function _setEndings(atStart:Bool, atEnd:Bool, pingPong:Bool):Void {
        var settings = _interpolantSettings;

        if (pingPong) {
            settings.endingStart = ZeroSlopeEnding;
            settings.endingEnd = ZeroSlopeEnding;
        } else {
            // assuming for LoopOnce atStart == atEnd == true

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
        var mixer = _mixer, now = mixer.time;
        var interpolant = _weightInterpolant;

        if (interpolant == null) {
            interpolant = mixer._lendControlInterpolant();
            _weightInterpolant = interpolant;
        }

        var times = interpolant.parameterPositions,
            values = interpolant.sampleValues;

        times[0] = now;
        values[0] = weightNow;
        times[1] = now + duration;
        values[1] = weightThen;

        return this;
    }
}