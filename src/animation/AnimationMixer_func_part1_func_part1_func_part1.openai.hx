package three.animation;

import haxe.ds.StringMap;
import three.animation.AnimationAction;
import three.core.EventDispatcher;
import three.math.interpolants.LinearInterpolant;
import three.animation.PropertyBinding;
import three.animation.PropertyMixer;

class AnimationMixer extends EventDispatcher {
    var _root:Dynamic;
    var _accuIndex:Int;
    var time:Float;
    var timeScale:Float;
    var _actions:Array<AnimationAction>;
    var _nActiveActions:Int;
    var _bindings:Array<PropertyMixer>;
    var _nActiveBindings:Int;
    var _controlInterpolants:Array<LinearInterpolant>;
    var _nActiveControlInterpolants:Int;
    var _actionsByClip:StringMap<{ knownActions:Array<AnimationAction>, actionByRoot:StringMap<AnimationAction> }>;
    var _bindingsByRootAndName:StringMap<StringMap<PropertyMixer>>;

    public function new(root:Dynamic) {
        super();
        _root = root;
        _initMemoryManager();
        _accuIndex = 0;
        time = 0;
        timeScale = 1.0;
    }

    function _bindAction(action:AnimationAction, prototypeAction:AnimationAction) {
        // implementation...
    }

    function _activateAction(action:AnimationAction) {
        // implementation...
    }

    function _deactivateAction(action:AnimationAction) {
        // implementation...
    }

    function _initMemoryManager() {
        _actions = [];
        _nActiveActions = 0;

        _actionsByClip = new StringMap();
        _bindingsByRootAndName = new StringMap();

        _bindings = [];
        _nActiveBindings = 0;

        _controlInterpolants = [];
        _nActiveControlInterpolants = 0;

        stats = {
            actions: {
                get_total():Int {
                    return _actions.length;
                },
                get_inUse():Int {
                    return _nActiveActions;
                }
            },
            bindings: {
                get_total():Int {
                    return _bindings.length;
                },
                get_inUse():Int {
                    return _nActiveBindings;
                }
            },
            controlInterpolants: {
                get_total():Int {
                    return _controlInterpolants.length;
                },
                get_inUse():Int {
                    return _nActiveControlInterpolants;
                }
            }
        };
    }

    function _isActiveAction(action:AnimationAction):Bool {
        return action._cacheIndex != null && action._cacheIndex < _nActiveActions;
    }

    function _addInactiveAction(action:AnimationAction, clipUuid:String, rootUuid:String) {
        // implementation...
    }

    function _removeInactiveAction(action:AnimationAction) {
        // implementation...
    }

    function _lendAction(action:AnimationAction) {
        // implementation...
    }

    function _takeBackAction(action:AnimationAction) {
        // implementation...
    }

    function _addInactiveBinding(binding:PropertyMixer, rootUuid:String, trackName:String) {
        // implementation...
    }

    function _removeInactiveBinding(binding:PropertyMixer) {
        // implementation...
    }

    function _lendBinding(binding:PropertyMixer) {
        // implementation...
    }

    function _takeBackBinding(binding:PropertyMixer) {
        // implementation...
    }

    function _lendControlInterpolant():LinearInterpolant {
        // implementation...
    }

    function _takeBackControlInterpolant(interpolant:LinearInterpolant) {
        // implementation...
    }

    function clipAction(clip:AnimationClip, optionalRoot:Dynamic, blendMode:Int):AnimationAction {
        // implementation...
    }

    function existingAction(clip:AnimationClip, optionalRoot:Dynamic):AnimationAction {
        // implementation...
    }

    function stopAllAction():AnimationMixer {
        // implementation...
    }

    function update(deltaTime:Float):AnimationMixer {
        // implementation...
    }

    function setTime(timeInSeconds:Float):AnimationMixer {
        // implementation...
    }

    function getRoot():Dynamic {
        return _root;
    }

    function uncacheClip(clip:AnimationClip) {
        // implementation...
    }

    function uncacheRoot(root:Dynamic) {
        // implementation...
    }

    function uncacheAction(clip:AnimationClip, optionalRoot:Dynamic) {
        // implementation...
    }
}