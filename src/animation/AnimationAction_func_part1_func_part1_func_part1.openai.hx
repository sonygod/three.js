import Constants.{WrapAroundEnding, ZeroCurvatureEnding, ZeroSlopeEnding, LoopPingPong, LoopOnce, LoopRepeat, NormalAnimationBlendMode, AdditiveAnimationBlendMode}

class AnimationAction {

	public var _mixer:Dynamic;
	public var _clip:Dynamic;
	public var _localRoot:Dynamic = null;
	public var blendMode:Int;

	public function new(mixer:Dynamic, clip:Dynamic, localRoot:Dynamic = null, blendMode:Int = clip.blendMode) {
		...
	}

	public function play():AnimationAction {
		...
	}

	public function stop():AnimationAction {
		...
	}

	public function reset():AnimationAction {
		...
	}

	public function isRunning():Bool {
		...
	}

	public function isScheduled():Bool {
		...
	}

	public function startAt(time:Dynamic) {
		...
	}

	public function setLoop(mode:Dynamic, repetitions:Int) {
		...
	}

	public function setEffectiveWeight(weight:Dynamic) {
		...
	}

	public function getEffectiveWeight():Float {
		...
	}

	public function fadeIn(duration:Dynamic) {
		...
	}

	public function fadeOut(duration:Dynamic) {
		...
	}

	public function crossFadeFrom(fadeOutAction:AnimationAction, duration:Dynamic, warp:Bool) {
		...
	}

	public function crossFadeTo(fadeInAction:AnimationAction, duration:Dynamic, warp:Bool) {
		...
	}

	public function stopFading():AnimationAction {
		...
	}

	public function setEffectiveTimeScale(timeScale:Dynamic) {
		...
	}

	public function getEffectiveTimeScale():Float {
		...
	}

	public function setDuration(duration:Dynamic) {
		...
	}

	public function syncWith(action:Dynamic) {
		...
	}

	public function halt(duration:Dynamic) {
		...
	}

	public function warp(startTimeScale:Float, endTimeScale:Float, duration:Dynamic) {
		...
	}

	public function stopWarping():AnimationAction {
		...
	}

	public function getMixer():Dynamic {
		...
	}

	public function getClip():Dynamic {
		...
	}

	public function getRoot():Dynamic {
		...
	}

	private function _update(time:Float, deltaTime:Float, timeDirection:Int, accuIndex:Int) {
		...
	}

	private function _updateWeight(time:Float):Float {
		...
	}

	private function _updateTimeScale(time:Float):Float {
		...
	}

	private function _updateTime(deltaTime:Float):Float {
		...
	}

	private function _setEndings(atStart:Bool, atEnd:Bool, pingPong:Bool) {
		...
	}

	private function _scheduleFading(duration:Dynamic, weightNow:Dynamic, weightThen:Dynamic) {
		...
	}

}