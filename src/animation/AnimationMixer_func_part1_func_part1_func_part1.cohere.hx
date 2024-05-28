import js.Browser.window;
import js.html.CanvasElement;
import js.html.Document;
import js.html.HtmlElement;
import js.html.ImageElement;
import js.html.MediaError;
import js.html.TimeRanges;
import js.html.VideoElement;
import js.html._Audio;
import js.html._CanvasRenderingContext2D;
import js.html._CanvasRenderingContext2D.LineCap;
import js.html._CanvasRenderingContext2D.LineJoin;
import js.html._CanvasRenderingContext2D.TextAlign;
import js.html._CanvasRenderingContext2D.TextBaseline;
import js.html._DataTransfer;
import js.html._DataTransferItemList;
import js.html._File;
import js.html._FileList;
import js.html._FileReader;
import js.html._FileReader.ReadyState;
import js.html._ImageData;
import js.html._MediaError;
import js.html._TimeRanges;
import js.html._Video;
import js.lib.DOMTokenList;
import js.lib.MimeType;
import js.lib.MimeTypeArray;
import js.lib._Event;
import js.lib._EventTarget;
import js.lib._HTMLCollection;
import js.lib._HTMLElement;
import js.lib._HTMLImageElement;
import js.lib._HTMLVideoElement;
import js.lib.css.CSSStyleDeclaration;
import js.lib.svg._Element;
import js.sys.ArrayBuffer;
import js.sys.DataView;
import js.sys.Float32Array;
import js.sys.Float64Array;
import js.sys.Int16Array;
import js.sys.Int32Array;
import js.sys.Int8Array;
import js.sys.Uint16Array;
import js.sys.Uint32Array;
import js.sys.Uint8Array;
import js.sys.Uint8ClampedArray;
class AnimationMixer extends EventDispatcher {
	public var time : Float;
	public var timeScale : Float;
	public var stats : { actions : { function get total() : Int; function get inUse() : Int; }; bindings : { function get total() : Int; function get inUse() : Int; }; controlInterpolants : { function get total() : Int; function get inUse() : Int; }; };
	public var _accuIndex : Int;
	public var _actions : Array<AnimationAction>;
	public var _actionsByClip : { [clipUuid:String]:{ knownActions:Array<AnimationAction>; actionByRoot:{ [rootUuid:String]:AnimationAction }; }; };
	public var _bindings : Array<PropertyMixer>;
	public var _bindingsByRootAndName : { [rootUuid:String]:{ [trackName:String]:PropertyMixer }; };
	public var _controlInterpolants : Array<Interpolant>;
	public var _initMemoryManager : Void->Void;
	public var _isActiveAction : AnimationAction->Bool;
	public var _lendAction : AnimationAction->Void;
	public var _lendBinding : PropertyMixer->Void;
	public var _lendControlInterpolant : { ():Interpolant; (_:Interpolant); };
	public var _nActiveActions : Int;
	public var _nActiveBindings : Int;
	public var _nActiveControlInterpolants : Int;
	public var _removeInactiveAction : AnimationAction->Void;
	public var _removeInactiveBinding : PropertyMixer->Void;
	public var _root : InteractiveObject;
	public var _takeBackAction : AnimationAction->Void;
	public var _takeBackBinding : PropertyMixer->Void;
	public var _takeBackControlInterpolant : Interpolant->Void;
	public function new(root : InteractiveObject) {
		super();
		this._root = root;
		this._initMemoryManager();
		this._accuIndex = 0;
		this.time = 0;
		this.timeScale = 1.;
	}
	public function _addInactiveAction(action : AnimationAction, clipUuid : String, rootUuid : String) : Void {
		var actions = this._actions;
		var actionsByClip = this._actionsByClip;
		var actionsForClip = actionsByClip[clipUuid];
		if (js.Lib.isUndefined(actionsForClip)) {
			actionsForClip = {
				knownActions : [action],
				actionByRoot : {}
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
	public function _addInactiveBinding(binding : PropertyMixer, rootUuid : String, trackName : String) : Void {
		var bindingsByRoot = this._bindingsByRootAndName;
		var bindings = this._bindings;
		var bindingByName = bindingsByRoot[rootUuid];
		if (js.Lib.isUndefined(bindingByName)) {
			bindingByName = { };
			bindingsByRoot[rootUuid] = bindingByName;
		}
		bindingByName[trackName] = binding;
		binding._cacheIndex = bindings.length;
		bindings.push(binding);
	}
	public function _activateAction(action : AnimationAction) : Void {
		if (!this._isActiveAction(action)) {
			if (action._cacheIndex == null) {
				var rootUuid = (action._localRoot ?? this._root).uuid;
				var clipUuid = action._clip.uuid;
				var actionsForClip = this._actionsByClip[clipUuid];
				this._bindAction(action, actionsForClip?.knownActions[0]);
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
	public function _bindAction(action : AnimationAction, prototypeAction : AnimationAction) : Void {
		var root = action._localRoot ?? this._root;
		var tracks = action._clip.tracks;
		var nTracks = tracks.length;
		var bindings = action._propertyBindings;
		var interpolants = action._interpolants;
		var rootUuid = root.uuid;
		var bindingsByRoot = this._bindingsByRootAndName;
		var bindingsByName = bindingsByRoot[rootUuid];
		if (js.Lib.isUndefined(bindingsByName)) {
			bindingsByName = { };
			bindingsByRoot[rootUuid] = bindingsByName;
		}
		var i = 0;
		while (i < nTracks) {
			var track = tracks[i];
			var trackName = track.name;
			var binding = bindingsByName[trackName];
			if (!js.Lib.isUndefined(binding)) {
				binding.referenceCount++;
				bindings[i] = binding;
			} else {
				binding = bindings[i];
				if (!js.Lib.isUndefined(binding)) {
					if (binding._cacheIndex == null) {
						binding.referenceCount++;
						this._addInactiveBinding(binding, rootUuid, trackName);
					}
					continue;
				}
				var path = prototypeAction?._propertyBindings[i]?.binding.parsedPath;
				binding = new PropertyMixer(PropertyBinding.create(root, trackName, path), track.ValueTypeName, track.getValueSize());
				binding.referenceCount++;
				this._addInactiveBinding(binding, rootUuid, trackName);
				bindings[i] = binding;
			}
			interpolants[i].resultBuffer = binding.buffer;
			i++;
		}
	}
	public function _deactivateAction(action : AnimationAction) : Void {
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
	public function _initMemoryManager() : Void {
		this._actions = [];
		this._nActiveActions = 0;
		this._actionsByClip = { };
		this._bindings = [];
		this._nActiveBindings = 0;
		this._bindingsByRootAndName = { };
		this._controlInterpolants = [];
		this._nActiveControlInterpolants = 0;
		var scope = this;
		this.stats = {
			actions : {
				get_total() : function() : Int {
					return scope._actions.length;
				},
				get_inUse() : function() : Int {
					return scope._nActiveActions;
				}
			},
			bindings : {
				get_total() : function() : Int {
					return scope._bindings.length;
				},
				get_inUse() : function() : Int {
					return scope._nActiveBindings;
				}
			},
			controlInterpolants : {
				get_total() : function() : Int {
					return scope._controlInterpolants.length;
				},
				get_inUse() : function() : Int {
					return scope._nActiveControlInterpolants;
				}
			}
		};
	}
	public function _isActiveAction(action : AnimationAction) : Bool {
		var index = action._cacheIndex;
		return index != null && index < this._nActiveActions;
	}
	public function _lendAction(action : AnimationAction) : Void {
		var actions = this._actions;
		var prevIndex = action._cacheIndex;
		var lastActiveIndex = this._nActiveActions++;
		var firstInactiveAction = actions[lastActiveIndex];
		action._cacheIndex = lastActiveIndex;
		actions[lastActiveIndex] = action;
		firstInactiveAction._cacheIndex = prevIndex;
		actions[prevIndex] = firstInactiveAction;
	}
	public function _lendBinding(binding : PropertyMixer) : Void {
		var bindings = this._bindings;
		var prevIndex = binding._cacheIndex;
		var lastActiveIndex = this._nActiveBindings++;
		var firstInactiveBinding = bindings[lastActiveIndex];
		binding._cacheIndex = lastActiveIndex;
		bindings[lastActiveIndex] = binding;
		firstInactiveBinding._cacheIndex = prevIndex;
		bindings[prevIndex] = firstInactiveBinding;
	}
	public function _lendControlInterpolant() : Interpolant {
		var interpolants = this._controlInterpolants;
		var lastActiveIndex = this._nActiveControlInterpolants++;
		var interpolant = interpolants[lastActiveIndex];
		if (js.Lib.isUndefined(interpolant)) {
			interpolant = new LinearInterpolant(new Float32Array(2), new Float32Array(2), 1, _controlInterpolantsResultBuffer);
			interpolant.__cacheIndex = lastActiveIndex;
			interpolants[lastActiveIndex] = interpolant;
		}
		return interpolant;
	}
	public function _removeInactiveAction(action : AnimationAction) : Void {
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
		var knownActions = actionsForClip.knownActions;
		var lastKnownAction = knownActions[knownActions.length - 1];
		var byClipCacheIndex = action._byClipCacheIndex;
		lastKnownAction._byClipCacheIndex = byClipCacheIndex;
		knownActions[byClipCacheIndex] = lastKnownAction;
		knownActions.pop();
		action._byClipCacheIndex = null;
		var actionByRoot = actionsForClip.actionByRoot;
		var rootUuid = (action._localRoot ?? this._root).uuid;
		delete actionByRoot[rootUuid];
		if (knownActions.length == 0) {
			delete actionsByClip[clipUuid];
		}
		this._removeInactiveBindingsForAction(action);
	}
	public function _removeInactiveBindingsForAction(action : AnimationAction) : Void {
		var bindings = action._propertyBindings;
		for (i in 0...bindings.length) {
			var binding = bindings[i];
			if (--binding.referenceCount == 0) {
				this._removeInactiveBinding(binding);
			}
		}
	}
	public function _removeInactiveBinding(binding : PropertyMixer) : Void {
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
		if (js.Lib.getKeys(bindingByName).length == 0) {
			delete bindingsByRoot[rootUuid];
		}
	}
	public function _takeBackAction(action : AnimationAction) : Void {
		var actions = this._actions;
		var prevIndex = action._cacheIndex;
		var firstInactiveIndex = --this._nActiveActions;
		var lastActiveAction = actions[firstInactiveIndex];
		action._cacheIndex = firstInactiveIndex;
		actions[firstInactiveIndex] = action;
		lastActiveAction._cacheIndex = prevIndex;
		actions[prevIndex] = lastActiveAction;
	}
	public function _takeBackBinding(binding : PropertyMixer) : Void {
		var bindings = this._bindings;
		var prevIndex = binding._cacheIndex;
		var firstInactiveIndex = --this._nActiveBindings;
		var lastActiveBinding = bindings[firstInactiveIndex];
		binding._cacheIndex = firstInactiveIndex;
		bindings[firstInactiveIndex] = binding;
		lastActiveBinding._cacheIndex = prevIndex;
		bindings[prevIndex] = lastActiveBinding;
	}
	public function _takeBackControlInterpolant(interpolant : Interpolant) : Void {
		var interpolants = this._controlInterpolants;
		var prevIndex = interpolant.__cacheIndex;
		var firstInactiveIndex = --this._nActiveControlInterpolants;
		var lastActiveInterpolant = interpolants[firstInactiveIndex];
		interpolant.__cacheIndex = firstInactiveIndex;
		interpolants[firstInactiveIndex] = interpolant;
		lastActiveInterpolant.__cacheIndex = prevIndex;
		interpolants[prevIndex] = lastActiveInterpolant;
	}
	public function clipAction(clip : Dynamic, optionalRoot : InteractiveObject, blendMode : Dynamic) : AnimationAction {
		var root = optionalRoot ?? this._root;
		var rootUuid = root.uuid;
		var clipObject = Std.is(clip, String) ? AnimationClip.findByName(root, clip) : clip;
		var clipUuid = clipObject != null ? clipObject.uuid : clip;
		var actionsForClip = this._actionsByClip[clipUuid];
		var prototypeAction = null;
		if (js.Lib.isUndefined(blendMode)) {
			if (clipObject != null) {
				blendMode = clipObject.blendMode;
			} else {
				blendMode = NormalAnimationBlendMode;
			}
		}
		if (!js.Lib.isUndefined(actionsForClip)) {
			var existingAction = actionsForClip.actionByRoot[rootUuid];
			if (!js.Lib.isUndefined(existingAction) && existingAction.blendMode == blendMode) {
				return existingAction;
			}
			if (!js.Lib.isUndefined(prototypeAction)) {
				prototypeAction = actionsForClip.knownActions[0];
			}
			if (js.Lib.isUndefined(clipObject)) {
				clipObject = prototypeAction?._clip;
			}
		}
		if (js.Lib.isUndefined(clipObject)) {
			return null;
		}
		var newAction = new AnimationAction(this, clipObject, optionalAction(this, clipObject, optionalRoot, blendMode));
		this._bindAction(newAction, prototypeAction);
		this._addInactiveAction(newAction, clipUuid, rootUuid);
		return newAction;
	}
	public function existingAction(clip : Dynamic, optionalRoot : InteractiveObject) : AnimationAction {
		var root = optionalRoot ?? this._root;
		var rootUuid = root.uuid;
		var clipObject = Std.is(clip, String) ? AnimationClip.findByName(root, clip) : clip;
		var clipUuid = clipObject != null ? clipObject.uuid : clip;
		var actionsForClip = this._actionsByClip[clipUuid];
		if (!js.Lib.isUndefined(actionsForClip)) {
			return actionsForClip.actionByRoot[rootUuid] ?? null;
		}
		return null;
	}
	public function stopAllAction() : AnimationMixer {
		var actions = this._actions;
		var nActions = this._nActiveActions;
		var i = nActions - 1;
		while (i >= 0) {
			actions[i].stop();
			i--;
		}
		return this;
	}
	public function update(deltaTime : Float) : AnimationMixer {
		deltaTime *= this.timeScale;
		var actions = this._actions;
		var nActions = this._nActiveActions;
		var time = this.time += deltaTime;
		var timeDirection = Math.sign(deltaTime);
		var accuIndex = this._accuIndex ^ 1;
		var i = 0;
		while (i < nActions) {
			var action = actions[i];
			action._update(time, deltaTime, timeDirection, accuIndex);
			i++;
		}
		var bindings = this._bindings;
		var nBindings = this._nActiveBindings;
		var j = 0;
		while (j < nBindings) {
			bindings[j].apply(accuIndex);
			j++;
		}
		return this;
	}
	public function setTime(timeInSeconds : Float) : AnimationMixer {
		this.time = 0;
		var i = 0;
		while (i < this._actions.length) {
			this._actions[i].time = 0;
			i++;
		}
		return this.update(timeInSeconds);
	}
	public function getRoot() : InteractiveObject {
		return this._root;
	}
	public function uncacheClip(clip : AnimationClip) : Void {
		var actions = this._actions;
		var clipUuid = clip.uuid;
		var actionsByClip = this._actionsByClip;
		var actionsForClip = actionsByClip[clipUuid];
		if (!js.Lib.isUndefined(actionsForClip)) {
			var actionsToRemove = actionsForClip.knownActions;
			var i = 0;
			while (i < actionsToRemove.length) {
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
				i++;
			}
			delete actionsByClip[clipUuid];
		}
	}
	public function uncacheRoot(root : InteractiveObject) : Void {
		var rootUuid = root.uuid;
		var actionsByClip = this._actionsByClip;
		var clipUuid = actionsByClip[clipUuid];
		var actionByRoot = actionsByClip.actionByRoot;
		var action = actionByRoot[rootUuid];
		if (!js.Lib.isUndefined(action)) {
			this._deactivateAction(action);
			this._removeInactiveAction(action);
		}
		var bindingsByRoot = this._bindingsByRootAndName;
		var bindingByName = bindingsByRoot[rootUuid];
		if (!js.Lib.isUndefined(bindingByName)) {
			var trackName = bindingByName.trackName;
			var binding = bindingByName[trackName];
			binding.restoreOriginalState();
			this._removeInactiveBinding(binding);
		}
	}
	public function uncacheAction(clip : Dynamic, optionalRoot : InteractiveObject) : Void {
		var action = this.existingAction(clip, optionalRoot);
		if (!js.Lib.isUndefined(action)) {
			this._deactivateAction(action);
			this._removeInactiveAction(action);
		}
	}
}