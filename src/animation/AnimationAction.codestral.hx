package three.js.animation;

import three.js.constants.WrapAroundEnding;
import three.js.constants.ZeroCurvatureEnding;
import three.js.constants.ZeroSlopeEnding;
import three.js.constants.LoopPingPong;
import three.js.constants.LoopOnce;
import three.js.constants.LoopRepeat;
import three.js.constants.NormalAnimationBlendMode;
import three.js.constants.AdditiveAnimationBlendMode;
import three.js.core.AnimationMixer;
import three.js.core.AnimationClip;
import three.js.core.Interpolant;
import three.js.core.AnimationActionEvent;
import three.js.math.Vector;
import three.js.math.Quaternion;

class AnimationAction {
  private var _mixer: AnimationMixer;
  private var _clip: AnimationClip;
  private var _localRoot: Object;
  public var blendMode: Int;
  private var _interpolants: Array<Interpolant<Float>>;
  private var _interpolantSettings: Dynamic;
  private var _propertyBindings: Array<Dynamic>;
  private var _cacheIndex: Int;
  private var _byClipCacheIndex: Int;
  private var _timeScaleInterpolant: Interpolant<Float>;
  private var _weightInterpolant: Interpolant<Float>;
  public var loop: Int;
  private var _loopCount: Int;
  private var _startTime: Float;
  public var time: Float;
  public var timeScale: Float;
  private var _effectiveTimeScale: Float;
  public var weight: Float;
  private var _effectiveWeight: Float;
  public var repetitions: Int;
  public var paused: Bool;
  public var enabled: Bool;
  public var clampWhenFinished: Bool;
  public var zeroSlopeAtStart: Bool;
  public var zeroSlopeAtEnd: Bool;

  public function new(mixer: AnimationMixer, clip: AnimationClip, localRoot: Object = null, blendMode: Int = -1) {
    this._mixer = mixer;
    this._clip = clip;
    this._localRoot = localRoot;
    this.blendMode = blendMode == -1 ? clip.blendMode : blendMode;

    var tracks = clip.tracks;
    var nTracks = tracks.length;
    this._interpolants = new Array<Interpolant<Float>>();

    var interpolantSettings = {
      endingStart: ZeroCurvatureEnding,
      endingEnd: ZeroCurvatureEnding
    };

    for (var i: Int = 0; i < nTracks; i++) {
      var interpolant = tracks[i].createInterpolant(null);
      this._interpolants[i] = interpolant;
      interpolant.settings = interpolantSettings;
    }

    this._interpolantSettings = interpolantSettings;
    this._propertyBindings = new Array<Dynamic>();
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
    this.repetitions = Int.POSITIVE_INFINITY;
    this.paused = false;
    this.enabled = true;
    this.clampWhenFinished = false;
    this.zeroSlopeAtStart = true;
    this.zeroSlopeAtEnd = true;
  }

  public function play(): AnimationAction {
    this._mixer._activateAction(this);
    return this;
  }

  public function stop(): AnimationAction {
    this._mixer._deactivateAction(this);
    return this.reset();
  }

  public function reset(): AnimationAction {
    this.paused = false;
    this.enabled = true;
    this.time = 0;
    this._loopCount = -1;
    this._startTime = null;
    return this.stopFading().stopWarping();
  }

  public function isRunning(): Bool {
    return this.enabled && !this.paused && this.timeScale != 0 && this._startTime == null && this._mixer._isActiveAction(this);
  }

  public function isScheduled(): Bool {
    return this._mixer._isActiveAction(this);
  }

  public function startAt(time: Float): AnimationAction {
    this._startTime = time;
    return this;
  }

  public function setLoop(mode: Int, repetitions: Int): AnimationAction {
    this.loop = mode;
    this.repetitions = repetitions;
    return this;
  }

  public function setEffectiveWeight(weight: Float): AnimationAction {
    this.weight = weight;
    this._effectiveWeight = this.enabled ? weight : 0;
    return this.stopFading();
  }

  public function getEffectiveWeight(): Float {
    return this._effectiveWeight;
  }

  public function fadeIn(duration: Float): AnimationAction {
    return this._scheduleFading(duration, 0, 1);
  }

  public function fadeOut(duration: Float): AnimationAction {
    return this._scheduleFading(duration, 1, 0);
  }

  public function crossFadeFrom(fadeOutAction: AnimationAction, duration: Float, warp: Bool): AnimationAction {
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

  public function crossFadeTo(fadeInAction: AnimationAction, duration: Float, warp: Bool): AnimationAction {
    return fadeInAction.crossFadeFrom(this, duration, warp);
  }

  public function stopFading(): AnimationAction {
    var weightInterpolant = this._weightInterpolant;

    if (weightInterpolant != null) {
      this._weightInterpolant = null;
      this._mixer._takeBackControlInterpolant(weightInterpolant);
    }

    return this;
  }

  public function setEffectiveTimeScale(timeScale: Float): AnimationAction {
    this.timeScale = timeScale;
    this._effectiveTimeScale = this.paused ? 0 : timeScale;
    return this.stopWarping();
  }

  public function getEffectiveTimeScale(): Float {
    return this._effectiveTimeScale;
  }

  public function setDuration(duration: Float): AnimationAction {
    this.timeScale = this._clip.duration / duration;
    return this.stopWarping();
  }

  public function syncWith(action: AnimationAction): AnimationAction {
    this.time = action.time;
    this.timeScale = action.timeScale;
    return this.stopWarping();
  }

  public function halt(duration: Float): AnimationAction {
    return this.warp(this._effectiveTimeScale, 0, duration);
  }

  public function warp(startTimeScale: Float, endTimeScale: Float, duration: Float): AnimationAction {
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

  public function stopWarping(): AnimationAction {
    var timeScaleInterpolant = this._timeScaleInterpolant;

    if (timeScaleInterpolant != null) {
      this._timeScaleInterpolant = null;
      this._mixer._takeBackControlInterpolant(timeScaleInterpolant);
    }

    return this;
  }

  public function getMixer(): AnimationMixer {
    return this._mixer;
  }

  public function getClip(): AnimationClip {
    return this._clip;
  }

  public function getRoot(): Object {
    return this._localRoot != null ? this._localRoot : this._mixer._root;
  }

  public function _update(time: Float, deltaTime: Float, timeDirection: Float, accuIndex: Int) {
    if (!this.enabled) {
      this._updateWeight(time);
      return;
    }

    var startTime = this._startTime;

    if (startTime != null) {
      var timeRunning = (time - startTime) * timeDirection;
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
          for (var j: Int = 0, m = interpolants.length; j < m; j++) {
            interpolants[j].evaluate(clipTime);
            propertyMixers[j].accumulateAdditive(weight);
          }
          break;

        case NormalAnimationBlendMode:
        default:
          for (var j: Int = 0, m = interpolants.length; j < m; j++) {
            interpolants[j].evaluate(clipTime);
            propertyMixers[j].accumulate(accuIndex, weight);
          }
          break;
      }
    }
  }

  private function _updateWeight(time: Float): Float {
    var weight = 0;

    if (this.enabled) {
      weight = this.weight;
      var interpolant = this._weightInterpolant;

      if (interpolant != null) {
        var interpolantValue = interpolant.evaluate(time)[0];

        weight *= interpolantValue;

        if (time > interpolant.parameterPositions[1]) {
          this.stopFading();

          if (interpolantValue == 0) {
            this.enabled = false;
          }
        }
      }
    }

    this._effectiveWeight = weight;
    return weight;
  }

  private function _updateTimeScale(time: Float): Float {
    var timeScale = 0;

    if (!this.paused) {
      timeScale = this.timeScale;

      var interpolant = this._timeScaleInterpolant;

      if (interpolant != null) {
        var interpolantValue = interpolant.evaluate(time)[0];

        timeScale *= interpolantValue;

        if (time > interpolant.parameterPositions[1]) {
          this.stopWarping();

          if (timeScale == 0) {
            this.paused = true;
          } else {
            this.timeScale = timeScale;
          }
        }
      }
    }

    this._effectiveTimeScale = timeScale;
    return timeScale;
  }

  private function _updateTime(deltaTime: Float): Float {
    var duration = this._clip.duration;
    var loop = this.loop;

    var time = this.time + deltaTime;
    var loopCount = this._loopCount;

    var pingPong = loop == LoopPingPong;

    if (deltaTime == 0) {
      if (loopCount == -1) return time;

      return pingPong && (loopCount & 1) == 1 ? duration - time : time;
    }

    if (loop == LoopOnce) {
      if (loopCount == -1) {
        this._loopCount = 0;
        this._setEndings(true, true, false);
      }

      if (time >= duration) {
        time = duration;

        if (this.clampWhenFinished) this.paused = true;
        else this.enabled = false;

        this.time = time;

        this._mixer.dispatchEvent(new AnimationActionEvent("finished", this, deltaTime < 0 ? -1 : 1));
      } else if (time < 0) {
        time = 0;

        if (this.clampWhenFinished) this.paused = true;
        else this.enabled = false;

        this.time = time;

        this._mixer.dispatchEvent(new AnimationActionEvent("finished", this, deltaTime < 0 ? -1 : 1));
      } else {
        this.time = time;
      }
    } else {
      if (loopCount == -1) {
        if (deltaTime >= 0) {
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

        if (pending <= 0) {
          if (this.clampWhenFinished) this.paused = true;
          else this.enabled = false;

          time = deltaTime > 0 ? duration : 0;

          this.time = time;

          this._mixer.dispatchEvent(new AnimationActionEvent("finished", this, deltaTime > 0 ? 1 : -1));
        } else {
          if (pending == 1) {
            var atStart = deltaTime < 0;
            this._setEndings(atStart, !atStart, pingPong);
          } else {
            this._setEndings(false, false, pingPong);
          }

          this._loopCount = loopCount;

          this.time = time;

          this._mixer.dispatchEvent(new AnimationActionEvent("loop", this, loopDelta));
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

  private function _setEndings(atStart: Bool, atEnd: Bool, pingPong: Bool) {
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

  private function _scheduleFading(duration: Float, weightNow: Float, weightThen: Float): AnimationAction {
    var mixer = this._mixer;
    var now = mixer.time;
    var interpolant = this._weightInterpolant;

    if (interpolant == null) {
      interpolant = mixer._lendControlInterpolant();
      this._weightInterpolant = interpolant;
    }

    var times = interpolant.parameterPositions;
    var values = interpolant.sampleValues;

    times[0] = now;
    values[0] = weightNow;
    times[1] = now + duration;
    values[1] = weightThen;

    return this;
  }
}