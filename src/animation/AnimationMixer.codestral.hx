import three.animation.AnimationAction;
import three.core.EventDispatcher;
import three.math.interpolants.LinearInterpolant;
import three.animation.PropertyBinding;
import three.animation.PropertyMixer;
import three.animation.AnimationClip;
import three.constants.NormalAnimationBlendMode;

class AnimationMixer extends EventDispatcher {
	public var _root:Dynamic;
	public var _accuIndex:Int;
	public var time:Float;
	public var timeScale:Float;

	private var _actions:Array<AnimationAction>;
	private var _nActiveActions:Int;
	private var _actionsByClip:haxe.ds.StringMap<Dynamic>;
	private var _bindings:Array<PropertyMixer>;
	private var _nActiveBindings:Int;
	private var _bindingsByRootAndName:haxe.ds.StringMap<haxe.ds.StringMap<PropertyMixer>>;
	private var _controlInterpolants:Array<LinearInterpolant>;
	private var _nActiveControlInterpolants:Int;
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
		var root:Dynamic = action._localRoot || this._root;
		var tracks:Array<Dynamic> = action._clip.tracks;
		var nTracks:Int = tracks.length;
		var bindings:Array<PropertyMixer> = action._propertyBindings;
		var interpolants:Array<LinearInterpolant> = action._interpolants;
		var rootUuid:String = root.uuid;
		var bindingsByRoot:haxe.ds.StringMap<haxe.ds.StringMap<PropertyMixer>> = this._bindingsByRootAndName;

		var bindingsByName:haxe.ds.StringMap<PropertyMixer> = bindingsByRoot.get(rootUuid);

		if(bindingsByName == null) {
			bindingsByName = new haxe.ds.StringMap<PropertyMixer>();
			bindingsByRoot.set(rootUuid, bindingsByName);
		}

		for(var i:Int = 0; i != nTracks; ++i) {
			var track:Dynamic = tracks[i];
			var trackName:String = track.name;

			var binding:PropertyMixer = bindingsByName.get(trackName);

			if(binding != null) {
				++binding.referenceCount;
				bindings[i] = binding;
			} else {
				binding = bindings[i];

				if(binding != null) {
					if(binding._cacheIndex == null) {
						++binding.referenceCount;
						this._addInactiveBinding(binding, rootUuid, trackName);
					}

					continue;
				}

				var path:String = prototypeAction != null ? prototypeAction._propertyBindings[i].binding.parsedPath : null;

				binding = new PropertyMixer(PropertyBinding.create(root, trackName, path), track.ValueTypeName, track.getValueSize());

				++binding.referenceCount;
				this._addInactiveBinding(binding, rootUuid, trackName);

				bindings[i] = binding;
			}

			interpolants[i].resultBuffer = binding.buffer;
		}
	}

	// More functions follow, but this should give you an idea of how to convert the rest of the JavaScript code to Haxe.
}