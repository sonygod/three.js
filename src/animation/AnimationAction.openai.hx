import animation.constants.ZeroCurvatureEnding;
import animation.constants.ZeroSlopeEnding;
import animation.constants.LoopPingPong;
import animation.constants.LoopOnce;
import animation.constants.LoopRepeat;
import animation.constants.NormalAnimationBlendMode;
import animation.constants.AdditiveAnimationBlendMode;

class AnimationAction {

	var _mixer: Mixer;
	var _clip: Clip;
	var _localRoot: Null<LocalRoot>;
	var blendMode: BlendMode;
	var _interpolantSettings: { endingStart: EndingType, endingEnd: EndingType };
	var _interpolants: Array<Interpolant>;
	var _propertyBindings: Array<PropertyMixer>;
	var _cacheIndex: Null<Int>;
	var _byClipCacheIndex: Null<Int>;
	var _timeScaleInterpolant: Null<Interpolant>;
	var _weightInterpolant: Null<Interpolant>;
	var loop: LoopType;
	var _loopCount: Int;
	var _startTime: Null<Float>;
	var time: Float;
	var timeScale: Float;
	var _effectiveTimeScale: Float;
	var weight: Float;
	var _effectiveWeight: Float;
	var repetitions: Int;
	var paused: Bool;
	var enabled: Bool;
	var clampWhenFinished: Bool;
	var zeroSlopeAtStart: Bool;
	var zeroSlopeAtEnd: Bool;

	public function new(mixer: Mixer, clip: Clip, ?localRoot: Null<LocalRoot> = null, ?blendMode: BlendMode = clip.blendMode) {
		this._mixer = mixer;
		this._clip = clip;
		this._localRoot = localRoot;
		this.blendMode = blendMode;

		var nTracks = clip.tracks.length;
		var interpolants = new Array<Interpolant>(nTracks);

		var interpolantSettings = { endingStart: ZeroCurvatureEnding, endingEnd: ZeroCurvatureEnding };

		for (i in 0...nTracks) {
			var interpolant = clip.tracks[i].createInterpolant(null);
			interpolants[i] = interpolant;
			interpolant.settings = interpolantSettings;
		}

		this._interpolantSettings = interpolantSettings;
		this._interpolants = interpolants;

		this._propertyBindings = new Array<PropertyMixer>(nTracks);
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

	public function play(): AnimationAction {
		this._mixer._activateAction(this);
		return this;
	}

	public function stop(): AnimationAction {
		this._mixer._deactivateAction(this);
		return this.reset();
	}

	// Other methods here...

}