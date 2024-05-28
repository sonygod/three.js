package three.js.src.animation;

import three.js.src.core.EventDispatcher;
import three.js.src.math.interpolants.LinearInterpolant;
import three.js.src.animation.AnimationAction;
import three.js.src.animation.AnimationClip;
import three.js.src.constants.NormalAnimationBlendMode;
import three.js.src.animation.PropertyBinding;
import three.js.src.animation.PropertyMixer;

class AnimationMixer extends EventDispatcher {
    private var _root:Dynamic;
    private var _accuIndex:Int;
    private var time:Float;
    private var timeScale:Float;
    private var _actions:Array<AnimationAction>;
    private var _nActiveActions:Int;
    private var _bindings:Array<PropertyMixer>;
    private var _nActiveBindings:Int;
    private var _controlInterpolants:Array<LinearInterpolant>;
    private var _nActiveControlInterpolants:Int;
    private var _actionsByClip:Map<String, {knownActions:Array<AnimationAction>, actionByRoot:Map<String, AnimationAction> }>;
    private var _bindingsByRootAndName:Map<String, Map<String, PropertyMixer>>;
    private var _controlInterpolantsResultBuffer:Float32Array;

    public function new(root:Dynamic) {
        super();
        _root = root;
        _initMemoryManager();
        _accuIndex = 0;
        time = 0;
        timeScale = 1.0;
    }

    private function _bindAction(action:AnimationAction, prototypeAction:AnimationAction) {
        // implementation
    }

    private function _activateAction(action:AnimationAction) {
        // implementation
    }

    private function _deactivateAction(action:AnimationAction) {
        // implementation
    }

    private function _initMemoryManager() {
        // implementation
    }

    private function _isActiveAction(action:AnimationAction):Bool {
        // implementation
    }

    private function _addInactiveAction(action:AnimationAction, clipUuid:String, rootUuid:String) {
        // implementation
    }

    private function _removeInactiveAction(action:AnimationAction) {
        // implementation
    }

    private function _lendAction(action:AnimationAction) {
        // implementation
    }

    private function _takeBackAction(action:AnimationAction) {
        // implementation
    }

    private function _addInactiveBinding(binding:PropertyMixer, rootUuid:String, trackName:String) {
        // implementation
    }

    private function _removeInactiveBinding(binding:PropertyMixer) {
        // implementation
    }

    private function _lendBinding(binding:PropertyMixer) {
        // implementation
    }

    private function _takeBackBinding(binding:PropertyMixer) {
        // implementation
    }

    private function _lendControlInterpolant():LinearInterpolant {
        // implementation
    }

    private function _takeBackControlInterpolant(interpolant:LinearInterpolant) {
        // implementation
    }

    public function clipAction(clip:AnimationClip, optionalRoot:Dynamic, blendMode:Int):AnimationAction {
        // implementation
    }

    public function existingAction(clip:AnimationClip, optionalRoot:Dynamic):AnimationAction {
        // implementation
    }

    public function stopAllAction():AnimationMixer {
        // implementation
        return this;
    }

    public function update(deltaTime:Float):AnimationMixer {
        // implementation
        return this;
    }

    public function setTime(timeInSeconds:Float):AnimationMixer {
        // implementation
        return this;
    }

    public function getRoot():Dynamic {
        return _root;
    }

    public function uncacheClip(clip:AnimationClip) {
        // implementation
    }

    public function uncacheRoot(root:Dynamic) {
        // implementation
    }

    public function uncacheAction(clip:AnimationClip, optionalRoot:Dynamic) {
        // implementation
    }
}