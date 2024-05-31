import three.core.EventDispatcher;
import three.math.interpolants.LinearInterpolant;
import three.animation.AnimationClip;
import three.animation.AnimationAction;
import three.animation.PropertyBinding;
import three.animation.PropertyMixer;
import three.constants.NormalAnimationBlendMode;

class AnimationMixer extends EventDispatcher {
	var _root:Dynamic;
	var _actions:Array<AnimationAction>;
	var _nActiveActions:Int;
	var _actionsByClip:Map<String, { knownActions:Array<AnimationAction>, actionByRoot:Map<String, AnimationAction> }>;
	var _bindings:Array<PropertyMixer>;
	var _nActiveBindings:Int;
	var _bindingsByRootAndName:Map<String, Map<String, PropertyMixer>>;
	var _controlInterpolants:Array<LinearInterpolant>;
	var _nActiveControlInterpolants:Int;
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

	private function _bindAction(action:AnimationAction, prototypeAction:AnimationAction):Void {
		var root = action._localRoot == null ? this._root : action._localRoot;
		var tracks = action._clip.tracks;
		var nTracks = tracks.length;
		var bindings = action._propertyBindings;
		var interpolants = action._interpolants;
		var rootUuid = root.uuid;
		var bindingsByRoot = this._bindingsByRootAndName;

		var bindingsByName = bindingsByRoot.get(rootUuid);
		if (bindingsByName == null) {
			bindingsByName = new Map<String, PropertyMixer>();
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
					}
					continue;
				}

				var path = prototypeAction != null ? prototypeAction._propertyBindings[i].binding.parsedPath : null;

				binding = new PropertyMixer(
					PropertyBinding.create(root, trackName, path),
					track.ValueTypeName, track.getValueSize()
				);

				binding.referenceCount++;
				this._addInactiveBinding(binding, rootUuid, trackName);

				bindings[i] = binding;
			}

			interpolants[i].resultBuffer = binding.buffer;
		}
	}

	private function _activateAction(action:AnimationAction):Void {
		if (!this._isActiveAction(action)) {
			if (action._cacheIndex == null) {
				var rootUuid = (action._localRoot == null ? this._root : action._localRoot).uuid;
				var clipUuid = action._clip.uuid;
				var actionsForClip = this._actionsByClip.get(clipUuid);

				this._bindAction(action, actionsForClip != null ? actionsForClip.knownActions[0] : null);

				this._addInactiveAction(action, clipUuid, rootUuid);
			}

			var bindings = action._propertyBindings;
			for (i in 0...bindings.length) {
				var binding = bindings[i];
				if (binding.useCount++ == 0) {
					this._lendBinding(binding);
					binding.saveOriginalState();
				}
			}

			this._lendAction(action);
		}
	}

	private function _deactivateAction(action:AnimationAction):Void {
		if (this._isActiveAction(action)) {
			var bindings = action._propertyBindings;
			for (i in 0...bindings.length) {
				var binding = bindings[i];
				if (--binding.useCount == 0) {
					binding.restoreOriginalState();
					this._takeBackBinding(binding);
				}
			}

			this._takeBackAction(action);
		}
	}

	// Memory manager

	private function _initMemoryManager():Void {
		this._actions = new Array<AnimationAction>();
		this._nActiveActions = 0;

		this._actionsByClip = new Map<String, { knownActions:Array<AnimationAction>, actionByRoot:Map<String, AnimationAction> }>();

		this._bindings = new Array<PropertyMixer>();
		this._nActiveBindings = 0;

		this._bindingsByRootAndName = new Map<String, Map<String, PropertyMixer>>();

		this._controlInterpolants = new Array<LinearInterpolant>();
		this._nActiveControlInterpolants = 0;
	}

	// Memory management for AnimationAction objects

	private function _isActiveAction(action:AnimationAction):Bool {
		var index = action._cacheIndex;
		return index != null && index < this._nActiveActions;
	}

	private function _addInactiveAction(action:AnimationAction, clipUuid:String, rootUuid:String):Void {
		var actions = this._actions;
		var actionsByClip = this._actionsByClip;

		var actionsForClip = actionsByClip.get(clipUuid);
		if (actionsForClip == null) {
			actionsForClip = {
				knownActions: [action],
				actionByRoot: new Map<String, AnimationAction>()
			};
			action._byClipCacheIndex = 0;
			actionsByClip.set(clipUuid, actionsForClip);
		} else {
			var knownActions = actionsForClip.knownActions;
			action._byClipCacheIndex = knownActions.length;
			knownActions.push(action);
		}

		action._cacheIndex = actions.length;
		actions.push(action);

		actionsForClip.actionByRoot.set(rootUuid, action);
	}

	private function _removeInactiveAction(action:AnimationAction):Void {
		var actions = this._actions;
		var lastInactiveAction = actions[actions.length - 1];
		var cacheIndex = action._cacheIndex;

		lastInactiveAction._cacheIndex = cacheIndex;
		actions[cacheIndex] = lastInactiveAction;
		actions.pop();

		action._cacheIndex = null;

		var clipUuid = action._clip.uuid;
		var actionsByClip = this._actionsByClip;
		var actionsForClip = actionsByClip.get(clipUuid);
		var knownActionsForClip = actionsForClip.knownActions;
		var lastKnownAction = knownActionsForClip[knownActionsForClip.length - 1];
		var byClipCacheIndex = action._byClipCacheIndex;

		lastKnownAction._byClipCacheIndex = byClipCacheIndex;
		knownActionsForClip[byClipCacheIndex] = lastKnownAction;
		knownActionsForClip.pop();

		action._byClipCacheIndex = null;

		var actionByRoot = actionsForClip.actionByRoot;
		var rootUuid = (action._localRoot == null ? this._root : action._localRoot).uuid;

		actionByRoot.remove(rootUuid);

		if (knownActionsForClip.length == 0) {
			actionsByClip.remove(clipUuid);
		}

		this._removeInactiveBindingsForAction(action);
	}

	private function _removeInactiveBindingsForAction(action:AnimationAction):Void {
		var bindings = action._propertyBindings;
		for (i in 0...bindings.length) {
			var binding = bindings[i];
			if (--binding.referenceCount == 0) {
				this._removeInactiveBinding(binding);
			}
		}
	}

	private function _lendAction(action:AnimationAction):Void {
		var actions = this._actions;
		var prevIndex = action._cacheIndex;
		var lastActiveIndex = this._nActiveActions++;
		var firstInactiveAction = actions[lastActiveIndex];

		action._cacheIndex = lastActiveIndex;
		actions[lastActiveIndex] = action;

		firstInactiveAction._cacheIndex = prevIndex;
		actions[prevIndex] = firstInactiveAction;
	}

	private function _takeBackAction(action:AnimationAction):Void {
		var actions = this._actions;
		var prevIndex = action._cacheIndex;
		var firstInactiveIndex = --this._nActiveActions;
		var lastActiveAction = actions[firstInactiveIndex];

		action._cacheIndex = firstInactiveIndex;
		actions[firstInactiveIndex] = action;

		lastActiveAction._cacheIndex = prevIndex;
		actions[prevIndex] = lastActiveAction;
	}

	// Memory management for PropertyMixer objects

	private function _addInactiveBinding(binding:PropertyMixer, rootUuid:String, trackName:String):Void {
		var bindingsByRoot = this._bindingsByRootAndName;
		var bindings = this._bindings;

		var bindingByName = bindingsByRoot.get(rootUuid);
		if (bindingByName == null) {
			bindingByName = new Map<String, PropertyMixer>();
			bindingsByRoot.set(rootUuid, bindingByName);
		}

		bindingByName.set(trackName, binding);

		binding._cacheIndex = bindings.length;
		bindings.push(binding);
	}

	private function _removeInactiveBinding(binding:PropertyMixer):Void {
		var bindings = this._bindings;
		var propBinding = binding.binding;
		var rootUuid = propBinding.rootNode.uuid;
		var trackName = propBinding.path;
		var bindingsByRoot = this._bindingsByRootAndName;
		var bindingByName = bindingsByRoot.get(rootUuid);

		var lastInactiveBinding = bindings[bindings.length - 1];
		var cacheIndex = binding._cacheIndex;

		lastInactiveBinding._cacheIndex = cacheIndex;
		bindings[cacheIndex] = lastInactiveBinding;
		bindings.pop();

		bindingByName.remove(trackName);

		if (bindingByName.keys().length == 0) {
			bindingsByRoot.remove(rootUuid);
		}
	}

	private function _lendBinding(binding:PropertyMixer):Void {
		var bindings = this._bindings;
		var prevIndex = binding._cacheIndex;
		var lastActiveIndex = this._nActiveBindings++;
		var firstInactiveBinding = bindings[lastActiveIndex];

		binding._cacheIndex = lastActiveIndex;
		bindings[lastActiveIndex] = binding;

		firstInactiveBinding._cacheIndex = prevIndex;
		bindings[prevIndex] = firstInactiveBinding;
	}

	private function _takeBackBinding(binding:PropertyMixer):Void {
		var bindings = this._bindings;
		var prevIndex = binding._cacheIndex;
		var firstInactiveIndex = --this._nActiveBindings;
		var lastActiveBinding = bindings[firstInactiveIndex];

		binding._cacheIndex = firstInactiveIndex;
		bindings[firstInactiveIndex] = binding;

		lastActiveBinding._cacheIndex = prevIndex;
		bindings[prevIndex] = lastActiveBinding;
	}

	// Memory management of Interpolants for weight and time scale

	private function _lendControlInterpolant():LinearInterpolant {
		var interpolants = this._controlInterpolants;
		var lastActiveIndex = this._nActiveControlInterpolants++;

		var interpolant = interpolants[lastActiveIndex];
		if (interpolant == null) {
			interpolant = new LinearInterpolant(
				new Float32Array(2), new Float32Array(2),
				1, new Float32Array(1)
			);
			interpolant.__cacheIndex = lastActiveIndex;
			interpolants[lastActiveIndex] = interpolant;
		}

		return interpolant;
	}

	private function _takeBackControlInterpolant(interpolant:LinearInterpolant):Void {
		var interpolants = this._controlInterpolants;
		var prevIndex = interpolant.__cacheIndex;
		var firstInactiveIndex = --this._nActiveControlInterpolants;
		var lastActiveInterpolant = interpolants[firstInactiveIndex];

		interpolant.__cacheIndex = firstInactiveIndex;
		interpolants[firstInactiveIndex] = interpolant;

		lastActiveInterpolant.__cacheIndex = prevIndex;
		interpolants[prevIndex] = lastActiveInterpolant;
	}

	// return an action for a clip optionally using a custom root target
	// object (this method allocates a lot of dynamic memory in case a
	// previously unknown clip/root combination is specified)
	public function clipAction(clip:Dynamic, optionalRoot:Dynamic = null, blendMode:Int = NormalAnimationBlendMode):AnimationAction {
		var root = optionalRoot == null ? this._root : optionalRoot;
		var rootUuid = root.uuid;

		var clipObject = Type.typeof(clip) == TString ? AnimationClip.findByName(root, clip) : clip;
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

			// we know the clip, so we don't have to parse all
			// the bindings again but can just copy
			prototypeAction = actionsForClip.knownActions[0];

			// also, take the clip from the prototype action
			if (clipObject == null)
				clipObject = prototypeAction._clip;
		}

		// clip must be known when specified via string
		if (clipObject == null) return null;

		// allocate all resources required to run it
		var newAction = new AnimationAction(this, clipObject, optionalRoot, blendMode);

		this._bindAction(newAction, prototypeAction);

		// and make the action known to the memory manager
		this._addInactiveAction(newAction, clipUuid, rootUuid);

		return newAction;
	}

	// get an existing action
	public function existingAction(clip:Dynamic, optionalRoot:Dynamic = null):AnimationAction {
		var root = optionalRoot == null ? this._root : optionalRoot;
		var rootUuid = root.uuid;

		var clipObject = Type.typeof(clip) == TString ? AnimationClip.findByName(root, clip) : clip;
		var clipUuid = clipObject != null ? clipObject.uuid : clip;

		var actionsForClip = this._actionsByClip.get(clipUuid);
		if (actionsForClip != null) {
			return actionsForClip.actionByRoot.get(rootUuid) == null ? null : actionsForClip.actionByRoot.get(rootUuid);
		}

		return null;
	}

	// deactivates all previously scheduled actions
	public function stopAllAction():AnimationMixer {
		var actions = this._actions;
		var nActions = this._nActiveActions;

		for (i in nActions - 1...0) {
			actions[i].stop();
		}

		return this;
	}

	// advance the time and update apply the animation
	public function update(deltaTime:Float):AnimationMixer {
		deltaTime *= this.timeScale;

		var actions = this._actions;
		var nActions = this._nActiveActions;
		var time = this.time += deltaTime;
		var timeDirection = Math.sign(deltaTime);
		var accuIndex = this._accuIndex ^= 1;

		// run active actions
		for (i in 0...nActions) {
			var action = actions[i];
			action._update(time, deltaTime, timeDirection, accuIndex);
		}

		// update scene graph
		var bindings = this._bindings;
		var nBindings = this._nActiveBindings;
		for (i in 0...nBindings) {
			bindings[i].apply(accuIndex);
		}

		return this;
	}

	// Allows you to seek to a specific time in an animation.
	public function setTime(timeInSeconds:Float):AnimationMixer {
		this.time = 0;
		for (i in 0...this._actions.length) {
			this._actions[i].time = 0;
		}
		return this.update(timeInSeconds);
	}

	// return this mixer's root target object
	public function getRoot():Dynamic {
		return this._root;
	}

	// free all resources specific to a particular clip
	public function uncacheClip(clip:AnimationClip):Void {
		var actions = this._actions;
		var clipUuid = clip.uuid;
		var actionsByClip = this._actionsByClip;
		var actionsForClip = actionsByClip.get(clipUuid);
		if (actionsForClip != null) {
			// note: just calling _removeInactiveAction would mess up the
			// iteration state and also require updating the state we can
			// just throw away

			var actionsToRemove = actionsForClip.knownActions;

			for (i in 0...actionsToRemove.length) {
				var action = actionsToRemove[i];
				this._deactivateAction(action);
				var cacheIndex = action._cacheIndex;
				var lastInactiveAction = actions[actions.length - 1];

				action._cacheIndex = null;
				action._byClipCacheIndex = null;

				lastInactiveAction._cacheIndex = cacheIndex;
				actions[cacheIndex] = lastInactiveAction;
				actions.pop();

				this._removeInactiveBindingsForAction(action);
			}

			actionsByClip.remove(clipUuid);
		}
	}

	// free all resources specific to a particular root target object
	public function uncacheRoot(root:Dynamic):Void {
		var rootUuid = root.uuid;
		var actionsByClip = this._actionsByClip;

		for (clipUuid in actionsByClip.keys()) {
			var actionByRoot = actionsByClip.get(clipUuid).actionByRoot;
			var action = actionByRoot.get(rootUuid);
			if (action != null) {
				this._deactivateAction(action);
				this._removeInactiveAction(action);
			}
		}

		var bindingsByRoot = this._bindingsByRootAndName;
		var bindingByName = bindingsByRoot.get(rootUuid);
		if (bindingByName != null) {
			for (trackName in bindingByName.keys()) {
				var binding = bindingByName.get(trackName);
				binding.restoreOriginalState();
				this._removeInactiveBinding(binding);
			}
		}
	}

	// remove a targeted clip from the cache
	public function uncacheAction(clip:Dynamic, optionalRoot:Dynamic = null):Void {
		var action = this.existingAction(clip, optionalRoot);
		if (action != null) {
			this._deactivateAction(action);
			this._removeInactiveAction(action);
		}
	}
}