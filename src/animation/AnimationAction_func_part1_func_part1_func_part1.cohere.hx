import js.Browser.window;

class AnimationAction {
	var _mixer:Dynamic;
	var _clip:Dynamic;
	var _localRoot:Dynamic;
	var blendMode:Dynamic;
	var _interpolantSettings:Dynamic;
	var _interpolants:Array<Dynamic>;
	var _propertyBindings:Array<Dynamic>;
	var _cacheIndex:Int;
	var _byClipCacheIndex:Int;
	var _timeScaleInterpolant:Dynamic;
	var _weightInterpolant:Dynamic;
	var loop:Dynamic;
	var _loopCount:Int;
	var _startTime:Float;
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

	public function new(mixer:Dynamic, clip:Dynamic, ?localRoot:Dynamic, ?blendMode:Dynamic) {
		_mixer = mixer;
		_clip = clip;
		_localRoot = localRoot;
		blendMode = blendMode != null ? blendMode : clip.blendMode;

		var tracks = clip.tracks;
		var nTracks = tracks.length;
		_interpolants = new Array<Dynamic>(nTracks);

		_interpolantSettings = {
			endingStart: ZeroCurvatureEnding,
			endingEnd: ZeroCurvatureEnding
		};

		var i = 0;
		while (i < nTracks) {
			var interpolant = tracks[i].createInterpolant(null);
			_interpolants[i] = interpolant;
			interpolant.settings = _interpolantSettings;
			i++;
		}

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

		repetitions = haxe.Inf;

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

	public function setLoop(mode:Dynamic, repetitions:Int):AnimationAction {
		loop = mode;
		repetitions = repetitions;
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
			var fadeInDuration = _clip.duration;
			var fadeOutDuration = fadeOutAction._clip.duration;

			var startEndRatio = fadeOutDuration / fadeInDuration;
			var endStartRatio = fadeInDuration / fadeOutDuration;

			fadeOutAction.warp(1.0, startEndRatio, duration);
			warp(endStartRatio, 1.0, duration);
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
		var mixer = _mixer;
		var now = mixer.time;
		var timeScale = this.timeScale;

		var interpolant = _timeScaleInterpolant;

		if (interpolant == null) {
			interpolant = mixer._lendControlInterpolant();
			_timeScaleInterpolant = interpolant;
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
		var timeScaleInterpolant = _timeScaleInterpolant;

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
		return _localRoot != null ? _localRoot : _mixer._root;
	}

	public function _update(time:Float, deltaTime:Float, timeDirection:Float, accuIndex:Int):Void {
		if (!enabled) {
			_updateWeight(time);
			return;
		}

		var startTime = _startTime;

		if (startTime != null) {
			var timeRunning = (time - startTime) * timeDirection;
			if (timeRunning < 0 || timeDirection == 0) {
				deltaTime = 0;
			} else {
				_startTime = null;
				deltaTime = timeDirection * timeRunning;
			}
		}

		deltaTime *= _updateTimeScale(time);
		var clipTime = _updateTime(deltaTime);

		var weight = _updateWeight(time);

		if (weight > 0) {
			var interpolants = _interpolants;
			var propertyMixers = _propertyBindings;

			switch (_clip.blendMode) {
				case AdditiveAnimationBlendMode:
					var j = 0;
					while (j < interpolants.length) {
						interpolants[j].evaluate(clipTime);
						propertyMixers[j].accumulateAdditive(weight);
						j++;
					}
					break;
				case NormalAnimationBlendMode:
				default:
					var j = 0;
					while (j < interpolants.length) {
						interpolants[j].evaluate(clipTime);
						propertyMixers[j].accumulate(accuIndex, weight);
						j++;
					}
			}
		}
	}

	public function _updateWeight(time:Float):Float {
		var weight = 0.0;

		if (enabled) {
			weight = this.weight;
			var interpolant = _weightInterpolant;

			if (interpolant != null) {
				var interpolantValue = interpolant.evaluate(time)[0];
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

	public function _updateTimeScale(time:Float):Float {
		var timeScale = 0.0;

		if (!paused) {
			timeScale = this.timeScale;

			var interpolant = _timeScaleInterpolant;

			if (interpolant != null) {
				var interpolantValue = interpolant.evaluate(time)[0];
				timeScale *= interpolantValue;

				if (time > interpolant.parameterPositions[1]) {
					stopWarping();

					if (timeScale == 0) {
						paused = true;
					} else {
						timeScale = this.timeScale;
					}
				}
			}
		}

		_effectiveTimeScale = timeScale;
		return timeScale;
	}

	public function _updateTime(deltaTime:Float):Float {
		var duration = _clip.duration;
		var loop = this.loop;

		var time = this.time + deltaTime;
		var loopCount = _loopCount;

		var pingPong = (loop == LoopPingPong);

		if (deltaTime == 0) {
			if (loopCount == -1) return time;

			return (pingPong && (loopCount & 1) == 1) ? duration - time : time;
		}

		if (loop == LoopOnce) {
			if (loopCount == -1) {
				_loopCount = 0;
				_setEndings(true, true, false);
			}

			if (time >= duration) {
				time = duration;
			} else if (time < 0) {
				time = 0;
			} else {
				this.time = time;
				return time;
			}

			if (clampWhenFinished) paused = true;
			else enabled = false;

			this.time = time;

			_mixer.dispatchEvent({
				type: 'finished',
				action: this,
				direction: deltaTime < 0 ? -1 : 1
			});

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
				var loopDelta = Std.int(time / duration);
				time -= duration * loopDelta;

				loopCount += loopDelta.abs();

				var pending = repetitions - loopCount;

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
				return duration - time;
			}
		}

		return time;
	}

	public function _setEndings(atStart:Bool, atEnd:Bool, pingPong:Bool):Void {
		var settings = _interpolantSettings;

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
		var mixer = _mixer;
		var now = mixer.time;
		var interpolant = _weightInterpolant;

		if (interpolant == null) {
			interpolant = mixer._lendControlInterpolant();
			_weightInterpolant = interpolant;
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

class ZeroCurvatureEnding {
	public static var NONE:Int = 0;
	public static var ZERO_CURVATURE:Int = 1;
	public static var ZERO_SLOPE:Int = 2;
	public static var WRAP_AROUND:Int = 3;
}

class LoopStyle {
	public static var LoopOnce:Int = 0;
	public static var LoopRepeat:Int = 1;
	public static var LoopPingPong:Int = 2;
}

class AnimationBlendMode {
	public static var NormalAnimationBlendMode:Int = 0;
	public static var AdditiveAnimationBlendMode:Int = 1;
}

export {
	AnimationAction,
	ZeroCurvatureEnding,
	LoopStyle,
	AnimationBlendMode
}