import AnimationAction from "./AnimationAction";
import EventDispatcher from "../core/EventDispatcher";
import LinearInterpolant from "../math/interpolants/LinearInterpolant";
import PropertyBinding from "./PropertyBinding";
import PropertyMixer from "./PropertyMixer";
import AnimationClip from "./AnimationClip";
import { NormalAnimationBlendMode } from "../constants";

class AnimationMixer extends EventDispatcher {
	public _root:Dynamic;
	public _actions:Array<AnimationAction>;
	public _nActiveActions:Int;
	public _actionsByClip:Dynamic;
	public _bindings:Array<PropertyMixer>;
	public _nActiveBindings:Int;
	public _bindingsByRootAndName:Dynamic;
	public _controlInterpolants:Array<LinearInterpolant>;
	public _nActiveControlInterpolants:Int;
	public _accuIndex:Int;
	public time:Float;
	public timeScale:Float;
	public stats:Dynamic;

	public function new(root:Dynamic) {
		super();
		this._root = root;
		this._initMemoryManager();
		this._accuIndex = 0;
		this.time = 0;
		this.timeScale = 1.0;
	}

	public function _bindAction(action:AnimationAction, prototypeAction:AnimationAction):Void {
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

		for (var i = 0; i < nTracks; i++) {
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

				var path = prototypeAction != null ? prototypeAction._propertyBindings[i].binding.parsedPath : null;

				binding = new PropertyMixer(PropertyBinding.create(root, trackName, path), track.ValueTypeName, track.getValueSize());

				binding.referenceCount++;
				this._addInactiveBinding(binding, rootUuid, trackName);

				bindings[i] = binding;
			}

			interpolants[i].resultBuffer = binding.buffer;
		}
	}

	public function _activateAction(action:AnimationAction):Void {
		if (!this._isActiveAction(action)) {
			if (action._cacheIndex == null) {
				var rootUuid = (action._localRoot || this._root).uuid;
				var clipUuid = action._clip.uuid;
				var actionsForClip = this._actionsByClip[clipUuid];

				this._bindAction(action, actionsForClip != null ? actionsForClip.knownActions[0] : null);
				this._addInactiveAction(action, clipUuid, rootUuid);
			}

			var bindings = action._propertyBindings;
			for (var i = 0, n = bindings.length; i < n; i++) {
				var binding = bindings[i];
				if (binding.useCount++ == 0) {
					this._lendBinding(binding);
					binding.saveOriginalState();
				}
			}

			this._lendAction(action);
		}
	}

	public function _deactivateAction(action:AnimationAction):Void {
		if (this._isActiveAction(action)) {
			var bindings = action._propertyBindings;

			for (var i = 0, n = bindings.length; i < n; i++) {
				var binding = bindings[i];
				if (--binding.useCount == 0) {
					binding.restoreOriginalState();
					this._takeBackBinding(binding);
				}
			}

			this._takeBackAction(action);
		}
	}

	public function _initMemoryManager():Void {
		this._actions = [];
		this._nActiveActions = 0;

		this._actionsByClip = {};

		this._bindings = [];
		this._nActiveBindings = 0;

		this._bindingsByRootAndName = {};

		this._controlInterpolants = [];
		this._nActiveControlInterpolants = 0;

		var scope = this;

		this.stats = {
			get actions() {
				return {
					get total() {
						return scope._actions.length;
					},
					get inUse() {
						return scope._nActiveActions;
					}
				};
			},
			get bindings() {
				return {
					get total() {
						return scope._bindings.length;
					},
					get inUse() {
						return scope._nActiveBindings;
					}
				};
			},
			get controlInterpolants() {
				return {
					get total() {
						return scope._controlInterpolants.length;
					},
					get inUse() {
						return scope._nActiveControlInterpolants;
					}
				};
			}
		};
	}

	public function _isActiveAction(action:AnimationAction):Bool {
		var index = action._cacheIndex;
		return index != null && index < this._nActiveActions;
	}

	public function _addInactiveAction(action:AnimationAction, clipUuid:String, rootUuid:String):Void {
		var actions = this._actions;
		var actionsByClip = this._actionsByClip;

		var actionsForClip = actionsByClip[clipUuid];

		if (actionsForClip == null) {
			actionsForClip = {
				knownActions: [action],
				actionByRoot: {}
			};

			action._byClipCacheIndex = 0;

			actionsByClip[clipUuid] = actionsForClip;
		} else {
			var knownActions = actionsForClip.knownActions;

			action._byClipCacheIndex = knownActions.length;
			knownActions.push(action);
		}

		action._cacheIndex = actions.length;
		actions.push(action);

		actionsForClip.actionByRoot[rootUuid] = action;
	}

	public function _removeInactiveAction(action:AnimationAction):Void {
		var actions = this._actions;
		var lastInactiveAction = actions[actions.length - 1];
		var cacheIndex = action._cacheIndex;

		lastInactiveAction._cacheIndex = cacheIndex;
		actions[cacheIndex] = lastInactiveAction;
		actions.pop();

		action._cacheIndex = null;

		var clipUuid = action._clip.uuid;
		var actionsByClip = this._actionsByClip;
		var actionsForClip = actionsByClip[clipUuid];
		var knownActionsForClip = actionsForClip.knownActions;

		var lastKnownAction = knownActionsForClip[knownActionsForClip.length - 1];

		var byClipCacheIndex = action._byClipCacheIndex;

		lastKnownAction._byClipCacheIndex = byClipCacheIndex;
		knownActionsForClip[byClipCacheIndex] = lastKnownAction;
		knownActionsForClip.pop();

		action._byClipCacheIndex = null;

		var actionByRoot = actionsForClip.actionByRoot;
		var rootUuid = (action._localRoot || this._root).uuid;

		delete actionByRoot[rootUuid];

		if (knownActionsForClip.length == 0) {
			delete actionsByClip[clipUuid];
		}

		this._removeInactiveBindingsForAction(action);
	}

	public function _removeInactiveBindingsForAction(action:AnimationAction):Void {
		var bindings = action._propertyBindings;
		for (var i = 0, n = bindings.length; i < n; i++) {
			var binding = bindings[i];
			if (--binding.referenceCount == 0) {
				this._removeInactiveBinding(binding);
			}
		}
	}

	public function _lendAction(action:AnimationAction):Void {
		var actions = this._actions;
		var prevIndex = action._cacheIndex;

		var lastActiveIndex = this._nActiveActions++;

		var firstInactiveAction = actions[lastActiveIndex];

		action._cacheIndex = lastActiveIndex;
		actions[lastActiveIndex] = action;

		firstInactiveAction._cacheIndex = prevIndex;
		actions[prevIndex] = firstInactiveAction;
	}

	public function _takeBackAction(action:AnimationAction):Void {
		var actions = this._actions;
		var prevIndex = action._cacheIndex;

		var firstInactiveIndex = --this._nActiveActions;

		var lastActiveAction = actions[firstInactiveIndex];

		action._cacheIndex = firstInactiveIndex;
		actions[firstInactiveIndex] = action;

		lastActiveAction._cacheIndex = prevIndex;
		actions[prevIndex] = lastActiveAction;
	}

	public function _addInactiveBinding(binding:PropertyMixer, rootUuid:String, trackName:String):Void {
		var bindingsByRoot = this._bindingsByRootAndName;
		var bindings = this._bindings;

		var bindingByName = bindingsByRoot[rootUuid];

		if (bindingByName == null) {
			bindingByName = {};
			bindingsByRoot[rootUuid] = bindingByName;
		}

		bindingByName[trackName] = binding;

		binding._cacheIndex = bindings.length;
		bindings.push(binding);
	}

	public function _removeInactiveBinding(binding:PropertyMixer):Void {
		var bindings = this._bindings;
		var propBinding = binding.binding;
		var rootUuid = propBinding.rootNode.uuid;
		var trackName = propBinding.path;
		var bindingsByRoot = this._bindingsByRootAndName;
		var bindingByName = bindingsByRoot[rootUuid];

		var lastInactiveBinding = bindings[bindings.length - 1];
		var cacheIndex = binding._cacheIndex;

		lastInactiveBinding._cacheIndex = cacheIndex;
		bindings[cacheIndex] = lastInactiveBinding;
		bindings.pop();

		delete bindingByName[trackName];

		if (Reflect.field(bindingByName, "length") == 0) {
			delete bindingsByRoot[rootUuid];
		}
	}

	public function _lendBinding(binding:PropertyMixer):Void {
		var bindings = this._bindings;
		var prevIndex = binding._cacheIndex;

		var lastActiveIndex = this._nActiveBindings++;

		var firstInactiveBinding = bindings[lastActiveIndex];

		binding._cacheIndex = lastActiveIndex;
		bindings[lastActiveIndex] = binding;

		firstInactiveBinding._cacheIndex = prevIndex;
		bindings[prevIndex] = firstInactiveBinding;
	}

	public function _takeBackBinding(binding:PropertyMixer):Void {
		var bindings = this._bindings;
		var prevIndex = binding._cacheIndex;

		var firstInactiveIndex = --this._nActiveBindings;

		var lastActiveBinding = bindings[firstInactiveIndex];

		binding._cacheIndex = firstInactiveIndex;
		bindings[firstInactiveIndex] = binding;

		lastActiveBinding._cacheIndex = prevIndex;
		bindings[prevIndex] = lastActiveBinding;
	}

	public function _lendControlInterpolant():LinearInterpolant {
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

	public function _takeBackControlInterpolant(interpolant:LinearInterpolant):Void {
		var interpolants = this._controlInterpolants;
		var prevIndex = interpolant.__cacheIndex;

		var firstInactiveIndex = --this._nActiveControlInterpolants;

		var lastActiveInterpolant = interpolants[firstInactiveIndex];

		interpolant.__cacheIndex = firstInactiveIndex;
		interpolants[firstInactiveIndex] = interpolant;

		lastActiveInterpolant.__cacheIndex = prevIndex;
		interpolants[prevIndex] = lastActiveInterpolant;
	}

	public function clipAction(clip:Dynamic, optionalRoot:Dynamic = null, blendMode:Int = -1):AnimationAction {
		var root = optionalRoot != null ? optionalRoot : this._root;
		var rootUuid = root.uuid;

		var clipObject:Dynamic = typeof clip == "string" ? AnimationClip.findByName(root, clip) : clip;

		var clipUuid = clipObject != null ? clipObject.uuid : clip;

		var actionsForClip = this._actionsByClip[clipUuid];
		var prototypeAction:AnimationAction = null;

		if (blendMode == -1) {
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

	public function existingAction(clip:Dynamic, optionalRoot:Dynamic = null):AnimationAction {
		var root = optionalRoot != null ? optionalRoot : this._root;
		var rootUuid = root.uuid;

		var clipObject:Dynamic = typeof clip == "string" ? AnimationClip.findByName(root, clip) : clip;

		var clipUuid = clipObject != null ? clipObject.uuid : clip;

		var actionsForClip = this._actionsByClip[clipUuid];

		if (actionsForClip != null) {
			return actionsForClip.actionByRoot[rootUuid] != null ? actionsForClip.actionByRoot[rootUuid] : null;
		}

		return null;
	}

	public function stopAllAction():AnimationMixer {
		var actions = this._actions;
		var nActions = this._nActiveActions;

		for (var i = nActions - 1; i >= 0; i--) {
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

		for (var i = 0; i < nActions; i++) {
			var action = actions[i];
			action._update(time, deltaTime, timeDirection, accuIndex);
		}

		var bindings = this._bindings;
		var nBindings = this._nActiveBindings;

		for (var i = 0; i < nBindings; i++) {
			bindings[i].apply(accuIndex);
		}

		return this;
	}

	public function setTime(timeInSeconds:Float):AnimationMixer {
		this.time = 0;
		for (var i = 0; i < this._actions.length; i++) {
			this._actions[i].time = 0;
		}
		return this.update(timeInSeconds);
	}

	public function getRoot():Dynamic {
		return this._root;
	}

	public function uncacheClip(clip:AnimationClip):Void {
		var actions = this._actions;
		var clipUuid = clip.uuid;
		var actionsByClip = this._actionsByClip;
		var actionsForClip = actionsByClip[clipUuid];

		if (actionsForClip != null) {
			var actionsToRemove = actionsForClip.knownActions;

			for (var i = 0, n = actionsToRemove.length; i < n; i++) {
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

			delete actionsByClip[clipUuid];
		}
	}

	public function uncacheRoot(root:Dynamic):Void {
		var rootUuid = root.uuid;
		var actionsByClip = this._actionsByClip;

		for (var clipUuid in actionsByClip) {
			var actionByRoot = actionsByClip[clipUuid].actionByRoot;
			var action = actionByRoot[rootUuid];

			if (action != null) {
				this._deactivateAction(action);
				this._removeInactiveAction(action);
			}
		}

		var bindingsByRoot = this._bindingsByRootAndName;
		var bindingByName = bindingsByRoot[rootUuid];

		if (bindingByName != null) {
			for (var trackName in bindingByName) {
				var binding = bindingByName[trackName];
				binding.restoreOriginalState();
				this._removeInactiveBinding(binding);
			}
		}
	}

	public function uncacheAction(clip:Dynamic, optionalRoot:Dynamic = null):Void {
		var action = this.existingAction(clip, optionalRoot);

		if (action != null) {
			this._deactivateAction(action);
			this._removeInactiveAction(action);
		}
	}
}

export default AnimationMixer;