import haxe.ds.Vector;
import haxe.ui.Animation;
import haxe.ui.AnimationBlendMode;

enum Ending {
	ZeroCurvature,
	WrapAround,
	ZeroSlope;
}

enum LoopMode {
	LoopOnce,
	LoopRepeat,
	LoopPingPong;
}

class AnimationAction {
	public var _mixer:Animation;
	public var _clip:Animation;
	public var _localRoot:Dynamic;
	public var blendMode:AnimationBlendMode;

	public var loop:LoopMode = LoopRepeat;
	public var _loopCount:Int = -1;
	public var _startTime:Float = null;
	public var time:Float = 0;
	public var timeScale:Float = 1;
	public var _effectiveTimeScale:Float = 1;
	public var weight:Float = 1;
	public var _effectiveWeight:Float = 1;
	public var repetitions:Float = Math.POSITIVE_INFINITY;
	public var paused:Bool = false;
	public var enabled:Bool = true;
	public var clampWhenFinished:Bool = false;
	public var zeroSlopeAtStart:Bool = true;
	public var zeroSlopeAtEnd:Bool = true;

	public var _interpolantSettings:Dynamic;
	public var _interpolants:Vector<Dynamic>;
	public var _propertyBindings:Vector<Dynamic>;
	public var _cacheIndex:Dynamic = null;
	public var _byClipCacheIndex:Dynamic = null;
	public var _timeScaleInterpolant:Dynamic = null;
	public var _weightInterpolant:Dynamic = null;

	public function new(mixer:Animation, clip:Animation, localRoot:Dynamic = null, blendMode:AnimationBlendMode = clip.blendMode) {
		this._mixer = mixer;
		this._clip = clip;
		this._localRoot = localRoot;
		this.blendMode = blendMode;

		this._interpolantSettings = {
			endingStart: Ending.ZeroCurvature,
			endingEnd: Ending.ZeroCurvature
		};

		this._interpolants = new Vector<Dynamic>();
		for (i in 0...clip.tracks.length) {
			this._interpolants.push(clip.tracks[i].createInterpolant(null));
			this._interpolants[i].settings = this._interpolantSettings;
		}

		this._propertyBindings = new Vector<Dynamic>();

		this._cacheIndex = null;
		this._byClipCacheIndex = null;
		this._timeScaleInterpolant = null;
		this._weightInterpolant = null;
	}

	public function play():AnimationAction {
		this._mixer.activateAction(this);
		return this;
	}

	public function stop():AnimationAction {
		this._mixer.deactivateAction(this);
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
		return this.enabled && !this.paused && this.timeScale != 0 && this._startTime == null && this._mixer.isActiveAction(this);
	}

	public function isScheduled():Bool {
		return this._mixer.isActiveAction(this);
	}

	public function startAt(time:Float):AnimationAction {
		this._startTime = time;
		return this;
	}

	public function setLoop(mode:LoopMode, repetitions:Float):AnimationAction {
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

	public function crossFadeFrom(fadeOutAction:AnimationAction, duration:Float, warp:Bool = false):AnimationAction {
		fadeOutAction.fadeOut(duration);
		this.fadeIn(duration);

		if (warp) {
			var fadeInDuration:Float = this._clip.duration;
			var fadeOutDuration:Float = fadeOutAction._clip.duration;

			var startEndRatio:Float = fadeOutDuration / fadeInDuration;
			var endStartRatio:Float = fadeInDuration / fadeOutDuration;

			fadeOutAction.warp(1.0, startEndRatio, duration);
			this.warp(endStartRatio, 1.0, duration);
		}

		return this;
	}

	public function crossFadeTo(fadeInAction:AnimationAction, duration:Float, warp:Bool = false):AnimationAction {
		return fadeInAction.crossFadeFrom(this, duration, warp);
	}

	public function stopFading():AnimationAction {
		if (this._weightInterpolant != null) {
			this._weightInterpolant = null;
			this._mixer.takeBackControlInterpolant(this._weightInterpolant);
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
		var mixer:Animation = this._mixer;
		var now:Float = mixer.time;
		var timeScale:Float = this.timeScale;

		var interpolant:Dynamic = this._timeScaleInterpolant;

		if (interpolant == null) {
			interpolant = mixer.lendControlInterpolant();
			this._timeScaleInterpolant = interpolant;
		}

		interpolant.parameterPositions[0] = now;
		interpolant.parameterPositions[1] = now + duration;

		interpolant.sampleValues[0] = startTimeScale / timeScale;
		interpolant.sampleValues[1] = endTimeScale / timeScale;

		return this;
	}

	public function stopWarping():AnimationAction {
		if (this._timeScaleInterpolant != null) {
			this._timeScaleInterpolant = null;
			this._mixer.takeBackControlInterpolant(this._timeScaleInterpolant);
		}
		return this;
	}

	public function getMixer():Animation {
		return this._mixer;
	}

	public function getClip():Animation {
		return this._clip;
	}

	public function getRoot():Dynamic {
		return this._localRoot != null ? this._localRoot : this._mixer.root;
	}

	public function _update(time:Float, deltaTime:Float, timeDirection:Float, accuIndex:Int) {
		if (!this.enabled) {
			this._updateWeight(time);
			return;
		}

		var startTime:Float = this._startTime;

		if (startTime != null) {
			var timeRunning:Float = (time - startTime) * timeDirection;
			if (timeRunning < 0 || timeDirection == 0) {
				deltaTime = 0;
			} else {
				this._startTime = null;
				deltaTime = timeDirection * timeRunning;
			}
		}

		deltaTime *= this._updateTimeScale(time);
		var clipTime:Float = this._updateTime(deltaTime);

		var weight:Float = this._updateWeight(time);

		if (weight > 0) {
			var interpolants:Vector<Dynamic> = this._interpolants;
			var propertyMixers:Vector<Dynamic> = this._propertyBindings;

			switch (this.blendMode) {
				case AnimationBlendMode.Additive:
					for (j in 0...interpolants.length) {
						interpolants[j].evaluate(clipTime);
						propertyMixers[j].accumulateAdditive(weight);
					}
					break;
				case AnimationBlendMode.Normal:
				default:
					for (j in 0...interpolants.length) {
						interpolants[j].evaluate(clipTime);
						propertyMixers[j].accumulate(accuIndex, weight);
					}
			}
		}
	}

	public function _updateWeight(time:Float):Float {
		var weight:Float = 0;

		if (this.enabled) {
			weight = this.weight;
			var interpolant:Dynamic = this._weightInterpolant;

			if (interpolant != null) {
				var interpolantValue:Float = interpolant.evaluate(time)[0];
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

	public function _updateTimeScale(time:Float):Float {
		var timeScale:Float = 0;

		if (!this.paused) {
			timeScale = this.timeScale;
			var interpolant:Dynamic = this._timeScaleInterpolant;

			if (interpolant != null) {
				var interpolantValue:Float = interpolant.evaluate(time)[0];
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

	public function _updateTime(deltaTime:Float):Float {
		var duration:Float = this._clip.duration;
		var loop:LoopMode = this.loop;

		var time:Float = this.time + deltaTime;
		var loopCount:Int = this._loopCount;

		var pingPong:Bool = (loop == LoopPingPong);

		if (deltaTime == 0) {
			if (loopCount == -1) return time;
			return (pingPong && (loopCount & 1) == 1) ? duration - time : time;
		}

		if (loop == LoopOnce) {
			if (loopCount == -1) {
				this._loopCount = 0;
				this._setEndings(true, true, false);
			}

			if (time >= duration) {
				time = duration;
			} else if (time < 0) {
				time = 0;
			} else {
				this.time = time;
				break;
			}

			if (this.clampWhenFinished) this.paused = true;
			else this.enabled = false;

			this.time = time;

			this._mixer.dispatchEvent({
				type: "finished",
				action: this,
				direction: deltaTime < 0 ? -1 : 1
			});
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
				var loopDelta:Int = Math.floor(time / duration);
				time -= duration * loopDelta;
				loopCount += Math.abs(loopDelta);

				var pending:Float = this.repetitions - loopCount;

				if (pending <= 0) {
					if (this.clampWhenFinished) this.paused = true;
					else this.enabled = false;

					time = deltaTime > 0 ? duration : 0;
					this.time = time;

					this._mixer.dispatchEvent({
						type: "finished",
						action: this,
						direction: deltaTime > 0 ? 1 : -1
					});
				} else {
					if (pending == 1) {
						var atStart:Bool = deltaTime < 0;
						this._setEndings(atStart, !atStart, pingPong);
					} else {
						this._setEndings(false, false, pingPong);
					}

					this._loopCount = loopCount;
					this.time = time;

					this._mixer.dispatchEvent({
						type: "loop",
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

	public function _setEndings(atStart:Bool, atEnd:Bool, pingPong:Bool) {
		var settings:Dynamic = this._interpolantSettings;

		if (pingPong) {
			settings.endingStart = Ending.ZeroSlope;
			settings.endingEnd = Ending.ZeroSlope;
		} else {
			if (atStart) {
				settings.endingStart = this.zeroSlopeAtStart ? Ending.ZeroSlope : Ending.ZeroCurvature;
			} else {
				settings.endingStart = Ending.WrapAround;
			}

			if (atEnd) {
				settings.endingEnd = this.zeroSlopeAtEnd ? Ending.ZeroSlope : Ending.ZeroCurvature;
			} else {
				settings.endingEnd = Ending.WrapAround;
			}
		}
	}

	public function _scheduleFading(duration:Float, weightNow:Float, weightThen:Float):AnimationAction {
		var mixer:Animation = this._mixer;
		var now:Float = mixer.time;
		var interpolant:Dynamic = this._weightInterpolant;

		if (interpolant == null) {
			interpolant = mixer.lendControlInterpolant();
			this._weightInterpolant = interpolant;
		}

		interpolant.parameterPositions[0] = now;
		interpolant.sampleValues[0] = weightNow;
		interpolant.parameterPositions[1] = now + duration;
		interpolant.sampleValues[1] = weightThen;

		return this;
	}
}