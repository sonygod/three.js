import js.three.animation.AnimationAction;
import js.three.core.EventDispatcher;
import js.three.math.interpolants.LinearInterpolant;
import js.three.animation.PropertyBinding;
import js.three.animation.PropertyMixer;
import js.three.animation.AnimationClip;
import js.three.constants.NormalAnimationBlendMode;

class AnimationMixer extends EventDispatcher {

    var _root: Dynamic;
    var _accuIndex: Int;
    var time: Float;
    var timeScale: Float;

    public function new(root: Dynamic) {
        super();
        this._root = root;
        this._initMemoryManager();
        this._accuIndex = 0;
        this.time = 0;
        this.timeScale = 1.0;
    }

    private function _bindAction(action: AnimationAction, prototypeAction: AnimationAction): Void {
        // implementation
    }

    private function _activateAction(action: AnimationAction): Void {
        // implementation
    }

    private function _deactivateAction(action: AnimationAction): Void {
        // implementation
    }

    private function _initMemoryManager(): Void {
        // implementation
    }

    private function _isActiveAction(action: AnimationAction): Bool {
        // implementation
        return false;
    }

    private function _addInactiveAction(action: AnimationAction, clipUuid: String, rootUuid: String): Void {
        // implementation
    }

    private function _removeInactiveAction(action: AnimationAction): Void {
        // implementation
    }

    private function _removeInactiveBindingsForAction(action: AnimationAction): Void {
        // implementation
    }

    private function _lendAction(action: AnimationAction): Void {
        // implementation
    }

    private function _takeBackAction(action: AnimationAction): Void {
        // implementation
    }

    private function _addInactiveBinding(binding: PropertyMixer, rootUuid: String, trackName: String): Void {
        // implementation
    }

    private function _removeInactiveBinding(binding: PropertyMixer): Void {
        // implementation
    }

    private function _lendBinding(binding: PropertyMixer): Void {
        // implementation
    }

    private function _takeBackBinding(binding: PropertyMixer): Void {
        // implementation
    }

    private function _lendControlInterpolant(): LinearInterpolant {
        // implementation
        return null;
    }

    private function _takeBackControlInterpolant(interpolant: LinearInterpolant): Void {
        // implementation
    }

    public function clipAction(clip: Dynamic, optionalRoot: Dynamic, blendMode: Int): AnimationAction {
        // implementation
        return null;
    }

    public function existingAction(clip: Dynamic, optionalRoot: Dynamic): AnimationAction {
        // implementation
        return null;
    }

    public function stopAllAction(): AnimationMixer {
        // implementation
        return this;
    }

    public function update(deltaTime: Float): AnimationMixer {
        // implementation
        return this;
    }

    public function setTime(timeInSeconds: Float): AnimationMixer {
        // implementation
        return this.update(timeInSeconds);
    }

    public function getRoot(): Dynamic {
        return this._root;
    }

    public function uncacheClip(clip: Dynamic): Void {
        // implementation
    }

    public function uncacheRoot(root: Dynamic): Void {
        // implementation
    }

    public function uncacheAction(clip: Dynamic, optionalRoot: Dynamic): Void {
        // implementation
    }

}