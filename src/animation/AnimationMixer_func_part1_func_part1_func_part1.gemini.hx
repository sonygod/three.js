import three.core.EventDispatcher;
import three.animation.AnimationAction;
import three.animation.AnimationClip;
import three.math.interpolants.LinearInterpolant;
import three.animation.PropertyBinding;
import three.animation.PropertyMixer;
import three.constants.NormalAnimationBlendMode;

class AnimationMixer extends EventDispatcher {

	private var _root:Dynamic;
	private var _actions:Array<AnimationAction>;
	private var _nActiveActions:Int;
	private var _actionsByClip:Map<String, { knownActions:Array<AnimationAction>, actionByRoot:Map<String, AnimationAction> }>;
	private var _bindings:Array<PropertyMixer>;
	private var _nActiveBindings:Int;
	private var _bindingsByRootAndName:Map<String, Map<String, PropertyMixer>>;
	private var _controlInterpolants:Array<LinearInterpolant>;
	private var _nActiveControlInterpolants:Int;
	private var _accuIndex:Int;

	public var time:Float;
	public var timeScale:Float;

	public function new(root:Dynamic) {
		super();
		this._root = root;
		this._initMemoryManager();
		this._accuIndex = 0;
		this.time = 0;
		this.timeScale = 1.0;
	}

	private function _bindAction(action:AnimationAction, prototypeAction:AnimationAction) {
		var root = action._localRoot || this._root;
		var tracks = action._clip.tracks;
		var nTracks = tracks.length;
		var bindings = action._propertyBindings;
		var interpolants = action._interpolants;
		var rootUuid = root.uuid;
		var bindingsByRoot = this._bindingsByRootAndName;

		var bindingsByName = bindingsByRoot.get(rootUuid);

		if (bindingsByName == null) {
			bindingsByName = new Map();
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

	private function _activateAction(action:AnimationAction) {
		if (!this._isActiveAction(action)) {
			if (action._cacheIndex == null) {
				var rootUuid = (action._localRoot || this._root).uuid;
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

	private function _deactivateAction(action:AnimationAction) {
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

	private function _initMemoryManager() {
		this._actions = [];
		this._nActiveActions = 0;

		this._actionsByClip = new Map();

		this._bindings = [];
		this._nActiveBindings = 0;

		this._bindingsByRootAndName = new Map();

		this._controlInterpolants = [];
		this._nActiveControlInterpolants = 0;
	}

	private function _isActiveAction(action:AnimationAction):Bool {
		var index = action._cacheIndex;
		return index != null && index < this._nActiveActions;
	}

	private function _addInactiveAction(action:AnimationAction, clipUuid:String, rootUuid:String) {
		var actions = this._actions;
		var actionsByClip = this._actionsByClip;

		var actionsForClip = actionsByClip.get(clipUuid);

		if (actionsForClip == null) {
			actionsForClip = {
				knownActions: [action],
				actionByRoot: new Map()
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

	private function _removeInactiveAction(action:AnimationAction) {
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
		var rootUuid = (action._localRoot || this._root).uuid;

		actionByRoot.remove(rootUuid);

		if (knownActionsForClip.length == 0) {
			actionsByClip.remove(clipUuid);
		}

		this._removeInactiveBindingsForAction(action);
	}

	private function _removeInactiveBindingsForAction(action:AnimationAction) {
		var bindings = action._propertyBindings;

		for (i in 0...bindings.length) {
			var binding = bindings[i];

			if (--binding.referenceCount == 0) {
				this._removeInactiveBinding(binding);
			}
		}
	}

	private function _lendAction(action:AnimationAction) {
		var actions = this._actions;
		var prevIndex = action._cacheIndex;
		var lastActiveIndex = this._nActiveActions++;
		var firstInactiveAction = actions[lastActiveIndex];

		action._cacheIndex = lastActiveIndex;
		actions[lastActiveIndex] = action;

		firstInactiveAction._cacheIndex = prevIndex;
		actions[prevIndex] = firstInactiveAction;
	}

	private function _takeBackAction(action:AnimationAction) {
		var actions = this._actions;
		var prevIndex = action._cacheIndex;
		var firstInactiveIndex = --this._nActiveActions;
		var lastActiveAction = actions[firstInactiveIndex];

		action._cacheIndex = firstInactiveIndex;
		actions[firstInactiveIndex] = action;

		lastActiveAction._cacheIndex = prevIndex;
		actions[prevIndex] = lastActiveAction;
	}

	private function _addInactiveBinding(binding:PropertyMixer, rootUuid:String, trackName:String) {
		var bindingsByRoot = this._bindingsByRootAndName;
		var bindings = this._bindings;

		var bindingByName = bindingsByRoot.get(rootUuid);

		if (bindingByName == null) {
			bindingByName = new Map();
			bindingsByRoot.set(rootUuid, bindingByName);
		}

		bindingByName.set(trackName, binding);

		binding._cacheIndex = bindings.length;
		bindings.push(binding);
	}

	private function _removeInactiveBinding(binding:PropertyMixer) {
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

	private function _lendBinding(binding:PropertyMixer) {
		var bindings = this._bindings;
		var prevIndex = binding._cacheIndex;
		var lastActiveIndex = this._nActiveBindings++;
		var firstInactiveBinding = bindings[lastActiveIndex];

		binding._cacheIndex = lastActiveIndex;
		bindings[lastActiveIndex] = binding;

		firstInactiveBinding._cacheIndex = prevIndex;
		bindings[prevIndex] = firstInactiveBinding;
	}

	private function _takeBackBinding(binding:PropertyMixer) {
		var bindings = this._bindings;
		var prevIndex = binding._cacheIndex;
		var firstInactiveIndex = --this._nActiveBindings;
		var lastActiveBinding = bindings[firstInactiveIndex];

		binding._cacheIndex = firstInactiveIndex;
		bindings[firstInactiveIndex] = binding;

		lastActiveBinding._cacheIndex = prevIndex;
		bindings[prevIndex] = lastActiveBinding;
	}

	private function _lendControlInterpolant():LinearInterpolant {
		var interpolants = this._controlInterpolants;
		var lastActiveIndex = this._nActiveControlInterpolants++;

		var interpolant = interpolants[lastActiveIndex];

		if (interpolant == null) {
			interpolant = new LinearInterpolant(new Float32Array(2), new Float32Array(2), 1, new Float32Array(1));
			interpolant.__cacheIndex = lastActiveIndex;
			interpolants[lastActiveIndex] = interpolant;
		}

		return interpolant;
	}

	private function _takeBackControlInterpolant(interpolant:LinearInterpolant) {
		var interpolants = this._controlInterpolants;
		var prevIndex = interpolant.__cacheIndex;
		var firstInactiveIndex = --this._nActiveControlInterpolants;
		var lastActiveInterpolant = interpolants[firstInactiveIndex];

		interpolant.__cacheIndex = firstInactiveIndex;
		interpolants[firstInactiveIndex] = interpolant;

		lastActiveInterpolant.__cacheIndex = prevIndex;
		interpolants[prevIndex] = lastActiveInterpolant;
	}

	public function clipAction(clip:Dynamic, optionalRoot:Dynamic, blendMode:Dynamic = null):AnimationAction {
		var root = optionalRoot || this._root;
		var rootUuid = root.uuid;

		var clipObject = typeof clip == 'String' ? AnimationClip.findByName(root, clip) : clip;

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

	public function existingAction(clip:Dynamic, optionalRoot:Dynamic):AnimationAction {
		var root = optionalRoot || this._root;
		var rootUuid = root.uuid;

		var clipObject = typeof clip == 'String' ? AnimationClip.findByName(root, clip) : clip;

		var clipUuid = clipObject != null ? clipObject.uuid : clip;

		var actionsForClip = this._actionsByClip.get(clipUuid);

		if (actionsForClip != null) {
			return actionsForClip.actionByRoot.get(rootUuid) || null;
		}

		return null;
	}

	public function stopAllAction():AnimationMixer {
		var actions = this._actions;
		var nActions = this._nActiveActions;

		for (i in nActions - 1...-1) {
			actions[i].stop();
		}

		return this;
	}

	public function update(deltaTime:Float):AnimationMixer {
		deltaTime *= this.timeScale;

		var actions = this._actions;
		var nActions = this._nActiveActions;

		var time = this.time += deltaTime;
		var timeDirection = Math.sign(deltaTime);

		var accuIndex = this._accuIndex ^= 1;

		for (i in 0...nActions) {
			var action = actions[i];
			action._update(time, deltaTime, timeDirection, accuIndex);
		}

		var bindings = this._bindings;
		var nBindings = this._nActiveBindings;

		for (i in 0...nBindings) {
			bindings[i].apply(accuIndex);
		}

		return this;
	}

	public function setTime(timeInSeconds:Float):AnimationMixer {
		this.time = 0;
		for (i in 0...this._actions.length) {
			this._actions[i].time = 0;
		}

		return this.update(timeInSeconds);
	}

	public function getRoot():Dynamic {
		return this._root;
	}

	public function uncacheClip(clip:AnimationClip) {
		var actions = this._actions;
		var clipUuid = clip.uuid;
		var actionsByClip = this._actionsByClip;
		var actionsForClip = actionsByClip.get(clipUuid);

		if (actionsForClip != null) {
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

	public function uncacheRoot(root:Dynamic) {
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

	public function uncacheAction(clip:Dynamic, optionalRoot:Dynamic) {
		var action = this.existingAction(clip, optionalRoot);

		if (action != null) {
			this._deactivateAction(action);
			this._removeInactiveAction(action);
		}
	}
}