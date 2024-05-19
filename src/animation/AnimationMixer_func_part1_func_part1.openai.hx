import AnimationAction from './AnimationAction';
import EventDispatcher from '../core/EventDispatcher';
import LinearInterpolant from '../math/interpolants/LinearInterpolant';
import PropertyBinding from './PropertyBinding';
import PropertyMixer from './PropertyMixer';
import AnimationClip from './AnimationClip';
import { NormalAnimationBlendMode } from '../constants';

class AnimationMixer extends EventDispatcher {

    public var _controlInterpolantsResultBuffer:Float32Array = new Float32Array(1);
    public var _root:Dynamic;
    public var _accuIndex:Int;
    public var time:Float;
    public var timeScale:Float;

    public function new(root:Dynamic)
    {
        super();
        this._root = root;
        this._initMemoryManager();
        this._accuIndex = 0;
        this.time = 0;
        this.timeScale = 1.0;
    }

    private function _bindAction(action:AnimationAction, prototypeAction:AnimationAction):Void
    {
        // TODO: Implement the _bindAction method
    }

    private function _activateAction(action:AnimationAction):Void
    {
        // TODO: Implement the _activateAction method
    }

    private function _deactivateAction(action:AnimationAction):Void
    {
        // TODO: Implement the _deactivateAction method
    }

    private function _initMemoryManager():Void
    {
        // TODO: Implement the _initMemoryManager method
    }

    private function _isActiveAction(action:AnimationAction):Bool
    {
        // TODO: Implement the _isActiveAction method
    }

    private function _addInactiveAction(action:AnimationAction, clipUuid:String, rootUuid:String):Void
    {
        // TODO: Implement the _addInactiveAction method
    }

    private function _removeInactiveAction(action:AnimationAction):Void
    {
        // TODO: Implement the _removeInactiveAction method
    }

    private function _removeInactiveBindingsForAction(action:AnimationAction):Void
    {
        // TODO: Implement the _removeInactiveBindingsForAction method
    }

    private function _lendAction(action:AnimationAction):Void
    {
        // TODO: Implement the _lendAction method
    }

    private function _takeBackAction(action:AnimationAction):Void
    {
        // TODO: Implement the _takeBackAction method
    }

    private function _addInactiveBinding(binding:PropertyMixer, rootUuid:String, trackName:String):Void
    {
        // TODO: Implement the _addInactiveBinding method
    }

    private function _removeInactiveBinding(binding:PropertyMixer):Void
    {
        // TODO: Implement the _removeInactiveBinding method
    }

    private function _lendBinding(binding:PropertyMixer):Void
    {
        // TODO: Implement the _lendBinding method
    }

    private function _takeBackBinding(binding:PropertyMixer):Void
    {
        // TODO: Implement the _takeBackBinding method
    }

    private function _lendControlInterpolant():Dynamic
    {
        // TODO: Implement the _lendControlInterpolant method
        return null;
    }

    private function _takeBackControlInterpolant(interpolant:Dynamic):Void
    {
        // TODO: Implement the _takeBackControlInterpolant method
    }

    private function clipAction(clip:Dynamic, optionalRoot:Dynamic, blendMode:Int):AnimationAction
    {
        // TODO: Implement the clipAction method
        return null;
    }

    private function existingAction(clip:Dynamic, optionalRoot:Dynamic):AnimationAction
    {
        // TODO: Implement the existingAction method
        return null;
    }

    private function stopAllAction():AnimationMixer
    {
        // TODO: Implement the stopAllAction method
        return this;
    }

    private function update(deltaTime:Float):AnimationMixer
    {
        // TODO: Implement the update method
        return this;
    }

    private function setTime(timeInSeconds:Float):AnimationMixer
    {
        // TODO: Implement the setTime method
        return this;
    }

    private function getRoot():Dynamic
    {
        return this._root;
    }

    private function uncacheClip(clip:Dynamic):Void
    {
        // TODO: Implement the uncacheClip method
    }

    private function uncacheRoot(root:Dynamic):Void
    {
        // TODO: Implement the uncacheRoot method
    }

    private function uncacheAction(clip:Dynamic, optionalRoot:Dynamic):Void
    {
        // TODO: Implement the uncacheAction method
    }

}