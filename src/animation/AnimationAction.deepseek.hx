import three.js.src.animation.AnimationAction;
import three.js.src.constants.*;

class AnimationAction {

	var _mixer:Dynamic;
	var _clip:Dynamic;
	var _localRoot:Dynamic;
	var blendMode:Dynamic;
	var _interpolantSettings:Dynamic;
	var _interpolants:Array<Dynamic>;
	var _propertyBindings:Array<Dynamic>;
	var _cacheIndex:Dynamic;
	var _byClipCacheIndex:Dynamic;
	var _timeScaleInterpolant:Dynamic;
	var _weightInterpolant:Dynamic;
	var loop:Dynamic;
	var _loopCount:Int;
	var _startTime:Dynamic;
	var time:Float;
	var timeScale:Float;
	var _effectiveTimeScale:Float;
	var weight:Float;
	var _effectiveWeight:Float;
	var repetitions:Int;
	var paused:Bool;
	var enabled:Bool;
	var clampWhenFinished:Bool;
	var zeroSlopeAtStart:Bool;
	var zeroSlopeAtEnd:Bool;

	public function new(mixer:Dynamic, clip:Dynamic, localRoot:Dynamic = null, blendMode:Dynamic = clip.blendMode) {

		this._mixer = mixer;
		this._clip = clip;
		this._localRoot = localRoot;
		this.blendMode = blendMode;

		var tracks = clip.tracks;
		var nTracks = tracks.length;
		var interpolants = new Array(nTracks);

		var interpolantSettings = {
			endingStart: ZeroCurvatureEnding,
			endingEnd: ZeroCurvatureEnding
		};

		for (i in 0...nTracks) {

			var interpolant = tracks[i].createInterpolant(null);
			interpolants[i] = interpolant;
			interpolant.settings = interpolantSettings;

		}

		this._interpolantSettings = interpolantSettings;

		this._interpolants = interpolants; // bound by the mixer

		this._propertyBindings = new Array(nTracks);

		this._cacheIndex = null; // for the memory manager
		this._byClipCacheIndex = null; // for the memory manager

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

	public function setLoop(mode:Dynamic, repetitions:Int):AnimationAction {

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

		var mixer = this._mixer;
		var now = mixer.time;
		var timeScale = this.timeScale;

		var interpolant = this._timeScaleInterpolant;

		if (interpolant === null) {

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

		if (timeScaleInterpolant !== null) {

			this._timeScaleInterpolant = null;
			this._mixer._takeBackControlInterpolant(timeScaleInterpolant);

		}

		return this;

	}

	public function getMixer():Dynamic {

		return this._mixer;

	}

	public function getClip():Dynamic {

		return this._clip;

	}

	public function getRoot():Dynamic {

		return this._localRoot || this._mixer._root;

	}

	public function _update(time:Float, deltaTime:Float, timeDirection:Int, accuIndex:Int):Void {

		if (!this.enabled) {

			this._updateWeight(time);
			return;

		}

		var startTime = this._startTime;

		if (startTime !== null) {

			var timeRunning = (time - startTime) * timeDirection;
			if (timeRunning < 0 || timeDirection === 0) {

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

		var weight = 0;

		if (this.enabled) {

			weight = this.weight;
			var interpolant = this._weightInterpolant;

			if (interpolant !== null) {

				var interpolantValue = interpolant.evaluate(time)[0];

				weight *= interpolantValue;

				if (time > interpolant.parameterPositions[1]) {

					this.stopFading();

					if (interpolantValue === 0) {

						this.enabled = false;

					}

				}

			}

		}

		this._effectiveWeight = weight;
		return weight;

	}

	public function _updateTimeScale(time:Float):Float {

		var timeScale = 0;

		if (!this.paused) {

			timeScale = this.timeScale;

			var interpolant = this._timeScaleInterpolant;

			if (interpolant !== null) {

				var interpolantValue = interpolant.evaluate(time)[0];

				timeScale *= interpolantValue;

				if (time > interpolant.parameterPositions[1]) {

					this.stopWarping();

					if (timeScale === 0) {

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

	public function _updateTime(deltaTime:Float):Float {

		var duration = this._clip.duration;
		var loop = this.loop;

		var time = this.time + deltaTime;
		var loopCount = this._loopCount;

		var pingPong = (loop === LoopPingPong);

		if (deltaTime === 0) {

			if (loopCount === -1) return time;

			return (pingPong && (loopCount & 1) === 1) ? duration - time : time;

		}

		if (loop === LoopOnce) {

			if (loopCount === -1) {

				loopCount = 0;
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

		} else {

			if (loopCount === -1) {

				loopCount = 0;

				this._setEndings(true, this.repetitions === 0, pingPong);

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

					this._mixer.dispatchEvent({
						type: 'finished', action: this,
						direction: deltaTime > 0 ? 1 : -1
					});

				} else {

					this._setEndings(false, false, pingPong);

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

				return duration - time;

			}

		}

		return time;

	}

	public function _setEndings(atStart:Bool, atEnd:Bool, pingPong:Bool):Void {

		var settings = this._interpolantSettings;

		if (pingPong) {

			settings.endingStart = ZeroSlopeEnding;
			settings.endingEnd = ZeroSlopeEnding;

		} else {

			settings.endingStart = atStart ? (this.zeroSlopeAtStart ? ZeroSlopeEnding : ZeroCurvatureEnding) : WrapAroundEnding;
			settings.endingEnd = atEnd ? (this.zeroSlopeAtEnd ? ZeroSlopeEnding : ZeroCurvatureEnding) : WrapAroundEnding;

		}

	}

	public function _scheduleFading(duration:Float, weightNow:Float, weightThen:Float):AnimationAction {

		var mixer = this._mixer;
		var now = mixer.time;
		var interpolant = this._weightInterpolant;

		if (interpolant === null) {

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