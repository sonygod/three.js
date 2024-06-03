package three.animation;

import three.animation.AnimationAction;
import three.core.EventDispatcher;
import three.math.interpolants.LinearInterpolant;
import three.animation.PropertyBinding;
import three.animation.PropertyMixer;
import three.animation.AnimationClip;
import three.constants.NormalAnimationBlendMode;

class AnimationMixer extends EventDispatcher {

    private var _root:Dynamic;
    private var _actions:Array<AnimationAction>;
    private var _nActiveActions:Int;
    private var _actionsByClip:haxe.ds.StringMap<Dynamic>;
    private var _bindings:Array<PropertyMixer>;
    private var _nActiveBindings:Int;
    private var _bindingsByRootAndName:haxe.ds.StringMap<haxe.ds.StringMap<PropertyMixer>>;
    private var _controlInterpolants:Array<LinearInterpolant>;
    private var _nActiveControlInterpolants:Int;
    private var _accuIndex:Int;
    public var time:Float;
    public var timeScale:Float;
    public var stats:Dynamic;

    public function new(root:Dynamic) {
        super();
        this._root = root;
        this._initMemoryManager();
        this._accuIndex = 0;
        this.time = 0;
        this.timeScale = 1.0;
    }

    private function _bindAction(action:AnimationAction, prototypeAction:AnimationAction):Void {
        var root = action._localRoot != null ? action._localRoot : this._root;
        var tracks = action._clip.tracks;
        var nTracks = tracks.length;
        var bindings = action._propertyBindings;
        var interpolants = action._interpolants;
        var rootUuid = root.uuid;
        var bindingsByRoot = this._bindingsByRootAndName;
        var bindingsByName = bindingsByRoot.get(rootUuid);

        if (bindingsByName == null) {
            bindingsByName = new haxe.ds.StringMap<PropertyMixer>();
            bindingsByRoot.set(rootUuid, bindingsByName);
        }

        for (var i = 0; i < nTracks; i++) {
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
                    }
                    continue;
                }

                var path = null;
                if (prototypeAction != null) {
                    path = prototypeAction._propertyBindings[i].binding.parsedPath;
                }

                binding = new PropertyMixer(PropertyBinding.create(root, trackName, path), track.ValueTypeName, track.getValueSize());
                binding.referenceCount++;
                this._addInactiveBinding(binding, rootUuid, trackName);

                bindings[i] = binding;
            }

            interpolants[i].resultBuffer = binding.buffer;
        }
    }

    // Rest of the methods...
}