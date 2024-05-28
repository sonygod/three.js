package three.animation;

import three.animation.constants.AnimationActionBlendMode;
import three.animation.constants.AnimationLoopMode;
import three.animation.constants.AnimationEndingMode;

class AnimationAction {

	public var _mixer:Dynamic;
	public var _clip:Dynamic;
	public var _localRoot:Dynamic;
	public var blendMode:Int;

	public var loop:Int;
	public var _loopCount:Int;
	public var weight:Float;
	public var _effectiveWeight:Float;
	public var time:Float;
	public var timeScale:Float;
	public var _effectiveTimeScale:Float;
	public var repetitions:Int;
	public var paused:Bool;
	public var enabled:Bool;
	public var clampWhenFinished:Bool;
	public var zeroSlopeAtStart:Bool;
	public var zeroSlopeAtEnd:Bool;

	public function new(mixer, clip, localRoot = null, blendMode = clip.blendMode) {
		this._mixer = mixer;
		this._clip = clip;
		this._localRoot = localRoot;
		this.blendMode = blendMode;

		this.loop = AnimationLoopMode.REPEAT;
		this._loopCount = -1;
		this.weight = 1.0;
		this._effectiveWeight = 1.0;
		this.time = 0.0;
		this.timeScale = 1.0;
		this._effectiveTimeScale = 1.0;
		this.repetitions = Int.MAX_VALUE; // no. of repetitions when looping
		this.paused = false; // true -> zero effective time scale
		this.enabled = true; // false -> zero effective weight
		this.clampWhenFinished = false;
		this.zeroSlopeAtStart = true;
		this.zeroSlopeAtEnd = true;

		// ... (other initialization code remains the same)
	}
	
    // ... (other function implementations remain the same)

}