import AnimationAction.AnimationAction;
import EventDispatcher.EventDispatcher;
import LinearInterpolant.LinearInterpolant;
import PropertyBinding.PropertyBinding;
import PropertyMixer.PropertyMixer;
import AnimationClip.AnimationClip;
import NormalAnimationBlendMode.NormalAnimationBlendMode;

class AnimationMixer extends EventDispatcher {

    var _root:Dynamic;
    var _accuIndex:Int;
    var time:Float;
    var timeScale:Float;

    public function new(root:Dynamic) {
        super();
        _root = root;
        _initMemoryManager();
        _accuIndex = 0;
        time = 0;
        timeScale = 1.0;
    }

    private function _bindAction(action:AnimationAction, prototypeAction:AnimationAction) {
        // ...
    }

    private function _activateAction(action:AnimationAction) {
        // ...
    }

    private function _deactivateAction(action:AnimationAction) {
        // ...
    }

    private function _initMemoryManager() {
        // ...
    }

    private function _isActiveAction(action:AnimationAction):Bool {
        // ...
    }

    private function _addInactiveAction(action:AnimationAction, clipUuid:String, rootUuid:String) {
        // ...
    }

    private function _removeInactiveAction(action:AnimationAction) {
        // ...
    }

    private function _removeInactiveBindingsForAction(action:AnimationAction) {
        // ...
    }

    private function _lendAction(action:AnimationAction) {
        // ...
    }

    private function _takeBackAction(action:AnimationAction) {
        // ...
    }

    private function _addInactiveBinding(binding:PropertyMixer, rootUuid:String, trackName:String) {
        // ...
    }

    private function _removeInactiveBinding(binding:PropertyMixer) {
        // ...
    }

    private function _lendBinding(binding:PropertyMixer) {
        // ...
    }

    private function _takeBackBinding(binding:PropertyMixer) {
        // ...
    }

    private function _lendControlInterpolant():LinearInterpolant {
        // ...
    }

    private function _takeBackControlInterpolant(interpolant:LinearInterpolant) {
        // ...
    }

    public function clipAction(clip:Dynamic, optionalRoot:Dynamic, blendMode:Dynamic):AnimationAction {
        // ...
    }

    public function existingAction(clip:Dynamic, optionalRoot:Dynamic):AnimationAction {
        // ...
    }

    public function stopAllAction():AnimationMixer {
        // ...
    }

    public function update(deltaTime:Float):AnimationMixer {
        // ...
    }

    public function setTime(timeInSeconds:Float):AnimationMixer {
        // ...
    }

    public function getRoot():Dynamic {
        // ...
    }

    public function uncacheClip(clip:AnimationClip):Void {
        // ...
    }

    public function uncacheRoot(root:Dynamic):Void {
        // ...
    }

    public function uncacheAction(clip:Dynamic, optionalRoot:Dynamic):Void {
        // ...
    }

}