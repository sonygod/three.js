package three.js.src.animation;

import three.js.src.core.EventDispatcher;
import three.js.src.math.interpolants.LinearInterpolant;
import three.js.src.animation.AnimationAction;
import three.js.src.animation.PropertyBinding;
import three.js.src.animation.PropertyMixer;
import three.js.src.animation.AnimationClip;
import three.js.src.constants.NormalAnimationBlendMode;

class AnimationMixer extends EventDispatcher {

    var _root:Dynamic;
    var _initMemoryManager:Void->Void;
    var _accuIndex:Int;
    var time:Float;
    var timeScale:Float;

    public function new(root:Dynamic) {
        super();
        this._root = root;
        this._initMemoryManager();
        this._accuIndex = 0;
        this.time = 0;
        this.timeScale = 1.0;
    }

    private function _bindAction(action:Dynamic, prototypeAction:Dynamic):Void {
        var root = action._localRoot || this._root;
        var tracks = action._clip.tracks;
        var nTracks = tracks.length;
        var bindings = action._propertyBindings;
        var interpolants = action._interpolants;
        var rootUuid = root.uuid;
        var bindingsByRoot = this._bindingsByRootAndName;

        var bindingsByName = bindingsByRoot[rootUuid];

        if (bindingsByName == null) {
            bindingsByName = {};
            bindingsByRoot[rootUuid] = bindingsByName;
        }

        for (i in 0...nTracks) {
            var track = tracks[i];
            var trackName = track.name;
            var binding = bindingsByName[trackName];

            if (binding != null) {
                binding.referenceCount++;
                bindings[i] = binding;
            } else {
                binding = bindings[i];

                if (binding != null) {
                    if (binding._cacheIndex == null) {
                        binding.referenceCount++;
                        this._addInactiveBinding(binding, rootUuid, trackName);
                    }
                    continue;
                }

                var path = prototypeAction && prototypeAction._propertyBindings[i].binding.parsedPath;
                binding = new PropertyMixer(PropertyBinding.create(root, trackName, path), track.ValueTypeName, track.getValueSize());
                binding.referenceCount++;
                this._addInactiveBinding(binding, rootUuid, trackName);
                bindings[i] = binding;
            }

            interpolants[i].resultBuffer = binding.buffer;
        }
    }

    // ... 其他函数的转换，与上述代码类似，这里省略了

    public function clipAction(clip:Dynamic, optionalRoot:Dynamic, blendMode:Dynamic):Dynamic {
        var root = optionalRoot || this._root;
        var rootUuid = root.uuid;
        var clipObject = (typeof clip == "string") ? AnimationClip.findByName(root, clip) : clip;
        var clipUuid = (clipObject != null) ? clipObject.uuid : clip;
        var actionsForClip = this._actionsByClip[clipUuid];
        var prototypeAction = null;

        if (blendMode == null) {
            if (clipObject != null) {
                blendMode = clipObject.blendMode;
            } else {
                blendMode = NormalAnimationBlendMode;
            }
        }

        if (actionsForClip != null) {
            var existingAction = actionsForClip.actionByRoot[rootUuid];

            if (existingAction != null && existingAction.blendMode == blendMode) {
                return existingAction;
            }

            prototypeAction = actionsForClip.knownActions[0];
            if (clipObject == null) {
                clipObject = prototypeAction._clip;
            }
        }

        if (clipObject == null) {
            return null;
        }

        var newAction = new AnimationAction(this, clipObject, optionalRoot, blendMode);
        this._bindAction(newAction, prototypeAction);
        this._addInactiveAction(newAction, clipUuid, rootUuid);
        return newAction;
    }

    // ... 其他函数的转换，与上述代码类似，这里省略了

    public function setTime(timeInSeconds:Float):Dynamic {
        this.time = 0;
        for (i in 0...this._actions.length) {
            this._actions[i].time = 0;
        }
        return this.update(timeInSeconds);
    }

    public function getRoot():Dynamic {
        return this._root;
    }

    // ... 其他函数的转换，与上述代码类似，这里省略了
}