Here is the equivalent Haxe code for the provided JavaScript code:
```
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
    private var _mixer:Mixer;
    private var _clip:Clip;
    private var _localRoot:Null<Node>;
    private var _blendMode:Int;

    private var _interpolants:Array<Interpolant>;
    private var _interpolantSettings:InterpolantSettings;

    private var _propertyBindings:Array<PropertyMixer>;

    private var _cacheIndex:Null<Int>;
    private var _byClipCacheIndex:Null<Int>;

    private var _timeScaleInterpolant:Null<Interpolant>;
    private var _weightInterpolant:Null<Interpolant>;

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

    public function new(mixer:Mixer, clip:Clip, ?localRoot:Node, ?blendMode:Int = -1) {
        _mixer = mixer;
        _clip = clip;
        _localRoot = localRoot;
        _blendMode = blendMode != -1 ? blendMode : clip.blendMode;

        var tracks:Array<Track> = clip.tracks;
        var nTracks:Int = tracks.length;
        _interpolants = new Array<Interpolant>(nTracks);

        _interpolantSettings = {
            endingStart: ZeroCurvatureEnding,
            endingEnd: ZeroCurvatureEnding
        };

        for (i in 0...nTracks) {
            var interpolant:Interpolant = tracks[i].createInterpolant(null);
            _interpolants[i] = interpolant;
            interpolant.settings = _interpolantSettings;
        }

        _propertyBindings = new Array<PropertyMixer>(nTracks);

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
        var weightInterpolant:Interpolant = _weightInterpolant;
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
        var mixer:Mixer = _mixer;
        var now:Float = mixer.time;
        var timeScale:Float = this.timeScale;
        var interpolant:Interpolant = _timeScaleInterpolant;

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
        var timeScaleInterpolant:Interpolant = _timeScaleInterpolant;
        if (timeScaleInterpolant != null) {
            _timeScaleInterpolant = null;
            _mixer._takeBackControlInterpolant(timeScaleInterpolant);
        }
        return this;
    }

    public function getMixer():Mixer {
        return _mixer;
    }

    public function getClip():Clip {
        return _clip;
    }

    public function getRoot():Node {
        return _localRoot != null ? _localRoot : _mixer._root;
    }

    public function _update(time:Float, deltaTime:Float, timeDirection:Float, accuIndex:Int):Void {
        if (!enabled) {
            _updateWeight(time);
            return;
        }

        var startTime:Float = _startTime;
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

        var weight:Float = _updateWeight(time);

        if (weight > 0) {
            var interpolants:Array<Interpolant> = _interpolants;
            var propertyMixers:Array<PropertyMixer> = _propertyBindings;

            switch (_blendMode) {
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

    public function _updateWeight(time:Float):Float {
        var weight:Float = enabled ? weight : 0;
        var interpolant:Interpolant = _weightInterpolant;

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

        _effectiveWeight = weight;
        return weight;
    }

    public function _updateTimeScale(time:Float):Float {
        var timeScale:Float = paused ? 0 : timeScale;

        var interpolant:Interpolant = _timeScaleInterpolant;

        if (interpolant != null) {
            var interpolantValue:Float = interpolant.evaluate(time)[0];
            timeScale *= interpolantValue;

            if (time > interpolant.parameterPositions[1]) {
                stopWarping();

                if (interpolantValue == 0) {
                    paused = true;
                } else {
                    timeScale = timeScale;
                }
            }
        }

        _effectiveTimeScale = timeScale;
        return timeScale;
    }

    public function _updateTime(deltaTime:Float):Float {
        var duration:Float = _clip.duration;
        var loop:Int = loop;
        var loopCount:Int = _loopCount;

        var pingPong:Bool = loop == LoopPingPong;

        if (deltaTime == 0) {
            if (loopCount == -1) return time;
            return pingPong && (loopCount & 1) == 1 ? duration - time : time;
        }

        if (loop == LoopOnce) {
            if (loopCount == -1) {
                _loopCount = 0;
                _setEndings(true, true, false);
            }

            if (time + deltaTime >= duration) {
                time = duration;
            } else if (time + deltaTime < 0) {
                time = 0;
            } else {
                time += deltaTime;
            }

            if (clampWhenFinished) paused = true;
            else enabled = false;

            _mixer.dispatchEvent({ type: 'finished', action: this, direction: deltaTime < 0 ? -1 : 1 });
        } else {
            if (loopCount == -1) {
                if (deltaTime >= 0) {
                    loopCount = 0;
                    _setEndings(true, repetitions == 0, pingPong);
                } else {
                    _setEndings(repetitions == 0, true, pingPong);
                }
            }

            if (time + deltaTime >= duration || time + deltaTime < 0) {
                var loopDelta:Int = Math.floor((time + deltaTime) / duration);
                time -= duration * loopDelta;
                loopCount += Math.abs(loopDelta);

                var pending:Int = repetitions - loopCount;

                if (pending <= 0) {
                    paused = clampWhenFinished;
                    enabled = !clampWhenFinished;

                    time = deltaTime > 0 ? duration : 0;

                    _mixer.dispatchEvent({ type: 'finished', action: this, direction: deltaTime > 0 ? 1 : -1 });
                } else {
                    if (pending == 1) {
                        _setEndings(pingPong, !pingPong, pingPong);
                    } else {
                        _setEndings(false, false, pingPong);
                    }

                    _loopCount = loopCount;

                    time += deltaTime;

                    _mixer.dispatchEvent({ type: 'loop', action: this, loopDelta: loopDelta });
                }
            } else {
                time += deltaTime;
            }

            if (pingPong && (loopCount & 1) == 1) {
                return duration - time;
            }
        }

        return time;
    }

    public function _setEndings(atStart:Bool, atEnd:Bool, pingPong:Bool):Void {
        var settings:InterpolantSettings = _interpolantSettings;

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

    public function _scheduleFading(duration:Float, weightNow:Float, weightThen:Float):AnimationAction {
        var mixer:Mixer = _mixer;
        var now:Float = mixer.time;
        var interpolant:Interpolant = _weightInterpolant;

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
```
Note that I had to make some assumptions about the types of certain variables, as the JavaScript code did not provide explicit type annotations. Additionally, I had to rename some variables to conform to Haxe's naming conventions.