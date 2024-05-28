class AnimationMixer extends EventDispatcher {

	private var _root:Dynamic;
	private var _accuIndex:Int;
	private var time:Float;
	private var timeScale:Float;

	public function new(root:Dynamic) {
		super();
		this._root = root;
		this._initMemoryManager();
		this._accuIndex = 0;
		this.time = 0;
		this.timeScale = 1.0;
	}

	private function _bindAction(action:Dynamic, prototypeAction:Dynamic) {
		// implementation omitted
	}

	private function _activateAction(action:Dynamic) {
		// implementation omitted
	}

	private function _deactivateAction(action:Dynamic) {
		// implementation omitted
	}

	// Memory manager

	private function _initMemoryManager() {
		// implementation omitted
	}

	// Memory management for AnimationAction objects

	private function _isActiveAction(action:Dynamic):Bool {
		// implementation omitted
	}

	private function _addInactiveAction(action:Dynamic, clipUuid:String, rootUuid:String) {
		// implementation omitted
	}

	private function _removeInactiveAction(action:Dynamic) {
		// implementation omitted
	}

	private function _removeInactiveBindingsForAction(action:Dynamic) {
		// implementation omitted
	}

	private function _lendAction(action:Dynamic) {
		// implementation omitted
	}

	private function _takeBackAction(action:Dynamic) {
		// implementation omitted
	}

	// Memory management for PropertyMixer objects

	private function _addInactiveBinding(binding:Dynamic, rootUuid:String, trackName:String) {
		// implementation omitted
	}

	private function _removeInactiveBinding(binding:Dynamic) {
		// implementation omitted
	}

	private function _lendBinding(binding:Dynamic) {
		// implementation omitted
	}

	private function _takeBackBinding(binding:Dynamic) {
		// implementation omitted
	}

	// Memory management of Interpolants for weight and time scale

	private function _lendControlInterpolant() {
		// implementation omitted
	}

	private function _takeBackControlInterpolant(interpolant:Dynamic) {
		// implementation omitted
	}

	public function clipAction(clip:Dynamic, optionalRoot:Dynamic, blendMode:Dynamic):Dynamic {
		// implementation omitted
	}

	public function existingAction(clip:Dynamic, optionalRoot:Dynamic):Dynamic {
		// implementation omitted
	}

	public function stopAllAction():Void {
		// implementation omitted
	}

	public function update(deltaTime:Float):Void {
		// implementation omitted
	}

	public function setTime(timeInSeconds:Float):Void {
		// implementation omitted
	}

	public function getRoot():Dynamic {
		return this._root;
	}

	public function uncacheClip(clip:Dynamic):Void {
		// implementation omitted
	}

	public function uncacheRoot(root:Dynamic):Void {
		// implementation omitted
	}

	public function uncacheAction(clip:Dynamic, optionalRoot:Dynamic):Void {
		// implementation omitted
	}

}