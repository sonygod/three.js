package three.js.src.animation;

import three.js.src.math.MathUtils;
import three.js.src.animation.PropertyBinding;

class AnimationObjectGroup {

	var isAnimationObjectGroup:Bool;
	var uuid:String;
	var _objects:Array<Dynamic>;
	var nCachedObjects_:Int;
	var _indicesByUUID:Map<String, Int>;
	var _paths:Array<String>;
	var _parsedPaths:Array<Dynamic>;
	var _bindings:Array<Array<PropertyBinding>>;
	var _bindingsIndicesByPath:Map<String, Int>;
	var stats:{
		objects:{
			get():Int;
			get():Int;
		}
		get():Int;
	}

	public function new() {
		isAnimationObjectGroup = true;
		uuid = MathUtils.generateUUID();
		_objects = [].concat(arguments);
		nCachedObjects_ = 0;
		_indicesByUUID = {};
		for (i in arguments) {
			_indicesByUUID[arguments[i].uuid] = i;
		}
		_paths = [];
		_parsedPaths = [];
		_bindings = [];
		_bindingsIndicesByPath = {};
		stats = {
			objects: {
				get total() {
					return _objects.length;
				},
				get inUse() {
					return this.total - nCachedObjects_;
				}
			},
			get bindingsPerObject() {
				return _bindings.length;
			}
		};
	}

	public function add() {
		var objects = _objects;
		var indicesByUUID = _indicesByUUID;
		var paths = _paths;
		var parsedPaths = _parsedPaths;
		var bindings = _bindings;
		var nBindings = bindings.length;
		var knownObject = null;
		var nObjects = objects.length;
		var nCachedObjects = nCachedObjects_;
		for (i in arguments) {
			var object = arguments[i];
			var uuid = object.uuid;
			var index = indicesByUUID[uuid];
			if (index == null) {
				index = nObjects++;
				indicesByUUID[uuid] = index;
				objects.push(object);
				for (j in bindings) {
					bindings[j].push(new PropertyBinding(object, paths[j], parsedPaths[j]));
				}
			} else if (index < nCachedObjects) {
				knownObject = objects[index];
				var firstActiveIndex = --nCachedObjects;
				var lastCachedObject = objects[firstActiveIndex];
				indicesByUUID[lastCachedObject.uuid] = index;
				objects[index] = lastCachedObject;
				indicesByUUID[uuid] = firstActiveIndex;
				objects[firstActiveIndex] = object;
				for (j in bindings) {
					var bindingsForPath = bindings[j];
					var lastCached = bindingsForPath[firstActiveIndex];
					var binding = bindingsForPath[index];
					bindingsForPath[index] = lastCached;
					if (binding == null) {
						binding = new PropertyBinding(object, paths[j], parsedPaths[j]);
					}
					bindingsForPath[firstActiveIndex] = binding;
				}
			} else if (objects[index] != knownObject) {
				trace('THREE.AnimationObjectGroup: Different objects with the same UUID detected. Clean the caches or recreate your infrastructure when reloading scenes.');
			}
		}
		nCachedObjects_ = nCachedObjects;
	}

	public function remove() {
		var objects = _objects;
		var indicesByUUID = _indicesByUUID;
		var bindings = _bindings;
		var nBindings = bindings.length;
		var nCachedObjects = nCachedObjects_;
		for (i in arguments) {
			var object = arguments[i];
			var uuid = object.uuid;
			var index = indicesByUUID[uuid];
			if (index != null && index >= nCachedObjects) {
				var firstActiveIndex = nCachedObjects++;
				var firstActiveObject = objects[firstActiveIndex];
				indicesByUUID[firstActiveObject.uuid] = index;
				objects[index] = firstActiveObject;
				indicesByUUID[uuid] = firstActiveIndex;
				objects[firstActiveIndex] = object;
				objects.pop();
				for (j in bindings) {
					var bindingsForPath = bindings[j];
					var firstActive = bindingsForPath[firstActiveIndex];
					var binding = bindingsForPath[index];
					bindingsForPath[index] = firstActive;
					bindingsForPath[firstActiveIndex] = binding;
					bindingsForPath.pop();
				}
			}
		}
		nCachedObjects_ = nCachedObjects;
	}

	public function uncache() {
		var objects = _objects;
		var indicesByUUID = _indicesByUUID;
		var bindings = _bindings;
		var nBindings = bindings.length;
		var nCachedObjects = nCachedObjects_;
		var nObjects = objects.length;
		for (i in arguments) {
			var object = arguments[i];
			var uuid = object.uuid;
			var index = indicesByUUID[uuid];
			if (index != null) {
				delete indicesByUUID[uuid];
				if (index < nCachedObjects) {
					var firstActiveIndex = --nCachedObjects;
					var lastCachedObject = objects[firstActiveIndex];
					var lastIndex = --nObjects;
					var lastObject = objects[lastIndex];
					indicesByUUID[lastCachedObject.uuid] = index;
					objects[index] = lastCachedObject;
					if (lastIndex > 0) {
						indicesByUUID[lastObject.uuid] = firstActiveIndex;
					}
					objects[firstActiveIndex] = lastObject;
					objects.pop();
					for (j in bindings) {
						var bindingsForPath = bindings[j];
						var lastCached = bindingsForPath[firstActiveIndex];
						var last = bindingsForPath[lastIndex];
						bindingsForPath[index] = lastCached;
						bindingsForPath[firstActiveIndex] = last;
						bindingsForPath.pop();
					}
				} else {
					var lastIndex = --nObjects;
					var lastObject = objects[lastIndex];
					if (lastIndex > 0) {
						indicesByUUID[lastObject.uuid] = index;
					}
					objects[index] = lastObject;
					objects.pop();
					for (j in bindings) {
						var bindingsForPath = bindings[j];
						bindingsForPath[index] = bindingsForPath[lastIndex];
						bindingsForPath.pop();
					}
				}
			}
		}
		nCachedObjects_ = nCachedObjects;
	}

	public function subscribe_(path:String, parsedPath:Dynamic):Array<PropertyBinding> {
		var indicesByPath = _bindingsIndicesByPath;
		var index = indicesByPath[path];
		var bindings = _bindings;
		if (index != null) return bindings[index];
		var paths = _paths;
		var parsedPaths = _parsedPaths;
		var objects = _objects;
		var nObjects = objects.length;
		var bindingsForPath = new Array(nObjects);
		index = bindings.length;
		indicesByPath[path] = index;
		paths.push(path);
		parsedPaths.push(parsedPath);
		bindings.push(bindingsForPath);
		for (i in objects) {
			bindingsForPath[i] = new PropertyBinding(objects[i], path, parsedPath);
		}
		return bindingsForPath;
	}

	public function unsubscribe_(path:String) {
		var indicesByPath = _bindingsIndicesByPath;
		var index = indicesByPath[path];
		if (index != null) {
			var paths = _paths;
			var parsedPaths = _parsedPaths;
			var bindings = _bindings;
			var lastBindingsIndex = bindings.length - 1;
			var lastBindings = bindings[lastBindingsIndex];
			var lastBindingsPath = paths[lastBindingsIndex];
			indicesByPath[lastBindingsPath] = index;
			bindings[index] = lastBindings;
			bindings.pop();
			parsedPaths[index] = parsedPaths[lastBindingsIndex];
			parsedPaths.pop();
			paths[index] = paths[lastBindingsIndex];
			paths.pop();
		}
	}
}