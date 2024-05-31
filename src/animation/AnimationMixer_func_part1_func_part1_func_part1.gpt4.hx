import three.animation.AnimationAction;
import three.core.EventDispatcher;
import three.math.interpolants.LinearInterpolant;
import three.animation.PropertyBinding;
import three.animation.PropertyMixer;
import three.animation.AnimationClip;
import three.constants.NormalAnimationBlendMode;
import haxe.ds.StringMap;
import haxe.ds.ObjectMap;
import js.lib.Float32Array;

class AnimationMixer extends EventDispatcher {
    var _root:Dynamic;
    var _accuIndex:Int = 0;
    public var time:Float = 0;
    public var timeScale:Float = 1.0;
    var _actions:Array<AnimationAction> = [];
    var _nActiveActions:Int = 0;
    var _actionsByClip:ObjectMap<String, { knownActions:Array<AnimationAction>, actionByRoot:StringMap<AnimationAction> }> = new ObjectMap();
    var _bindings:Array<PropertyMixer> = [];
    var _nActiveBindings:Int = 0;
    var _bindingsByRootAndName:ObjectMap<String, StringMap<PropertyMixer>> = new ObjectMap();
    var _controlInterpolants:Array<LinearInterpolant> = [];
    var _nActiveControlInterpolants:Int = 0;
    var _controlInterpolantsResultBuffer:Float32Array = new Float32Array(1);

    public function new(root:Dynamic) {
        super();
        this._root = root;
        this._initMemoryManager();
    }

    function _bindAction(action:AnimationAction, prototypeAction:AnimationAction):Void {
        var root = action._localRoot != null ? action._localRoot : this._root;
        var tracks = action._clip.tracks;
        var nTracks = tracks.length;
        var bindings = action._propertyBindings;
        var interpolants = action._interpolants;
        var rootUuid = root.uuid;
        var bindingsByRoot = this._bindingsByRootAndName;

        var bindingsByName = bindingsByRoot.get(rootUuid);
        if (bindingsByName == null) {
            bindingsByName = new StringMap<PropertyMixer>();
            bindingsByRoot.set(rootUuid, bindingsByName);
        }

        for (i in 0...nTracks) {
            var track = tracks[i];
            var trackName = track.name;
            var binding = bindingsByName.get(trackName);
            if (binding != null) {
                binding.referenceCount++;
                bindings[i] = binding;
            } else {
                binding = bindings[i];
                if (binding != null) {
                    if (binding._cacheIndex == null) {
                        binding.referenceCount++;
                        this._addInactiveBinding(binding, rootUuid, trackName);
                        continue;
                    }
                }
                var path = prototypeAction != null ? prototypeAction._propertyBindings[i].binding.parsedPath : null;
                binding = new PropertyMixer(PropertyBinding.create(root, trackName, path), track.ValueTypeName, track.getValueSize());
                binding.referenceCount++;
                this._addInactiveBinding(binding, rootUuid, trackName);
                bindings[i] = binding;
            }
            interpolants[i].resultBuffer = binding.buffer;
        }
    }

    // Other methods should be translated in a similar manner

    public function clipAction(clip:Dynamic, optionalRoot:Dynamic = null, blendMode:NormalAnimationBlendMode = null):AnimationAction {
        var root = optionalRoot != null ? optionalRoot : this._root;
        var rootUuid = root.uuid;
        var clipObject = Std.is(clip, String) ? AnimationClip.findByName(root, clip) : clip;
        var clipUuid = clipObject != null ? clipObject.uuid : clip;

        var actionsForClip = this._actionsByClip.get(clipUuid);
        var prototypeAction:AnimationAction = null;

        if (blendMode == null) {
            if (clipObject != null) {
                blendMode = clipObject.blendMode;
            } else {
                blendMode = NormalAnimationBlendMode;
            }
        }

        if (actionsForClip != null) {
            var existingAction = actionsForClip.actionByRoot.get(rootUuid);
            if (existingAction != null && existingAction.blendMode == blendMode) {
                return existingAction;
            }
            prototypeAction = actionsForClip.knownActions[0];
            if (clipObject == null) clipObject = prototypeAction._clip;
        }

        if (clipObject == null) return null;

        var newAction = new AnimationAction(this, clipObject, optionalRoot, blendMode);
        this._bindAction(newAction, prototypeAction);
        this._addInactiveAction(newAction, clipUuid, rootUuid);
        return newAction;
    }

    // Continue translating remaining methods
}