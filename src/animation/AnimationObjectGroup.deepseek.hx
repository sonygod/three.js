import js.Browser.Math;
import js.Browser.window;

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
	var stats:Stats;

	public function new() {
		this.isAnimationObjectGroup = true;
		this.uuid = Math.random().toString();
		this._objects = [];
		this.nCachedObjects_ = 0;
		this._indicesByUUID = new Map();
		this._paths = [];
		this._parsedPaths = [];
		this._bindings = [];
		this._bindingsIndicesByPath = new Map();
		this.stats = new Stats();
	}

	public function add(objects:Array<Dynamic>):Void {
		var knownObject:Dynamic = null;
		var nObjects = this._objects.length;
		var nCachedObjects = this.nCachedObjects_;
		var indicesByUUID = this._indicesByUUID;
		var paths = this._paths;
		var parsedPaths = this._parsedPaths;
		var bindings = this._bindings;
		var nBindings = bindings.length;

		for (object in objects) {
			var uuid = object.uuid;
			var index = indicesByUUID.get(uuid);

			if (index == null) {
				index = nObjects++;
				indicesByUUID.set(uuid, index);
				this._objects.push(object);

				for (i in 0...nBindings) {
					var bindingsForPath = bindings[i];
					bindingsForPath.push(new PropertyBinding(object, paths[i], parsedPaths[i]));
				}
			} else if (index < nCachedObjects) {
				knownObject = this._objects[index];
				var firstActiveIndex = --nCachedObjects;
				var lastCachedObject = this._objects[firstActiveIndex];
				indicesByUUID.set(lastCachedObject.uuid, index);
				this._objects[index] = lastCachedObject;
				indicesByUUID.set(uuid, firstActiveIndex);
				this._objects[firstActiveIndex] = object;

				for (i in 0...nBindings) {
					var bindingsForPath = bindings[i];
					var lastCached = bindingsForPath[firstActiveIndex];
					var binding = bindingsForPath[index];
					bindingsForPath[index] = lastCached;
					if (binding == null) {
						binding = new PropertyBinding(object, paths[i], parsedPaths[i]);
					}
					bindingsForPath[firstActiveIndex] = binding;
				}
			} else if (this._objects[index] != knownObject) {
				trace('THREE.AnimationObjectGroup: Different objects with the same UUID detected. Clean the caches or recreate your infrastructure when reloading scenes.');
			}
		}

		this.nCachedObjects_ = nCachedObjects;
	}

	public function remove(objects:Array<Dynamic>):Void {
		var indicesByUUID = this._indicesByUUID;
		var bindings = this._bindings;
		var nBindings = bindings.length;
		var nCachedObjects = this.nCachedObjects_;
		var nObjects = this._objects.length;

		for (object in objects) {
			var uuid = object.uuid;
			var index = indicesByUUID.get(uuid);

			if (index != null && index >= nCachedObjects) {
				var lastCachedIndex = nCachedObjects++;
				var firstActiveObject = this._objects[lastCachedIndex];
				indicesByUUID.set(firstActiveObject.uuid, index);
				this._objects[index] = firstActiveObject;
				indicesByUUID.set(uuid, lastCachedIndex);
				this._objects[lastCachedIndex] = object;
				this._objects.splice(nObjects - 1, 1);

				for (i in 0...nBindings) {
					var bindingsForPath = bindings[i];
					var firstActive = bindingsForPath[lastCachedIndex];
					var binding = bindingsForPath[index];
					bindingsForPath[index] = firstActive;
					bindingsForPath[lastCachedIndex] = binding;
					bindingsForPath.splice(nObjects - 1, 1);
				}
			}
		}

		this.nCachedObjects_ = nCachedObjects;
	}

	public function uncache(objects:Array<Dynamic>):Void {
		var indicesByUUID = this._indicesByUUID;
		var bindings = this._bindings;
		var nBindings = bindings.length;
		var nCachedObjects = this.nCachedObjects_;
		var nObjects = this._objects.length;

		for (object in objects) {
			var uuid = object.uuid;
			var index = indicesByUUID.get(uuid);

			if (index != null) {
				indicesByUUID.delete(uuid);

				if (index < nCachedObjects) {
					var firstActiveIndex = --nCachedObjects;
					var lastCachedObject = this._objects[firstActiveIndex];
					var lastIndex = --nObjects;
					var lastObject = this._objects[lastIndex];
					indicesByUUID.set(lastCachedObject.uuid, index);
					this._objects[index] = lastCachedObject;
					if (lastIndex > 0) {
						indicesByUUID.set(lastObject.uuid, firstActiveIndex);
					}
					this._objects[firstActiveIndex] = lastObject;
					this._objects.splice(lastIndex, 1);

					for (i in 0...nBindings) {
						var bindingsForPath = bindings[i];
						var lastCached = bindingsForPath[firstActiveIndex];
						var last = bindingsForPath[lastIndex];
						bindingsForPath[index] = lastCached;
						bindingsForPath[firstActiveIndex] = last;
						bindingsForPath.splice(lastIndex, 1);
					}
				} else {
					var lastIndex = --nObjects;
					var lastObject = this._objects[lastIndex];
					if (lastIndex > 0) {
						indicesByUUID.set(lastObject.uuid, index);
					}
					this._objects[index] = lastObject;
					this._objects.splice(lastIndex, 1);

					for (i in 0...nBindings) {
						var bindingsForPath = bindings[i];
						bindingsForPath[index] = bindingsForPath[lastIndex];
						bindingsForPath.splice(lastIndex, 1);
					}
				}
			}
		}

		this.nCachedObjects_ = nCachedObjects;
	}

	public function subscribe_(path:String, parsedPath:Dynamic):Array<PropertyBinding> {
		var indicesByPath = this._bindingsIndicesByPath;
		var index = indicesByPath.get(path);
		var bindings = this._bindings;

		if (index != null) return bindings[index];

		var paths = this._paths;
		var parsedPaths = this._parsedPaths;
		var objects = this._objects;
		var nObjects = objects.length;
		var nCachedObjects = this.nCachedObjects_;
		var bindingsForPath = new Array();

		index = bindings.length;
		indicesByPath.set(path, index);
		paths.push(path);
		parsedPaths.push(parsedPath);
		bindings.push(bindingsForPath);

		for (i in nCachedObjects...nObjects) {
			var object = objects[i];
			bindingsForPath.push(new PropertyBinding(object, path, parsedPath));
		}

		return bindingsForPath;
	}

	public function unsubscribe_(path:String):Void {
		var indicesByPath = this._bindingsIndicesByPath;
		var index = indicesByPath.get(path);

		if (index != null) {
			var paths = this._paths;
			var parsedPaths = this._parsedPaths;
			var bindings = this._bindings;
			var lastBindingsIndex = bindings.length - 1;
			var lastBindings = bindings[lastBindingsIndex];
			var lastBindingsPath = paths[lastBindingsIndex];

			indicesByPath.set(lastBindingsPath, index);
			bindings[index] = lastBindings;
			bindings.splice(lastBindingsIndex, 1);
			parsedPaths[index] = parsedPaths[lastBindingsIndex];
			parsedPaths.splice(lastBindingsIndex, 1);
			paths[index] = paths[lastBindingsIndex];
			paths.splice(lastBindingsIndex, 1);
		}
	}
}

class Stats {
	public function new() {
	}

	public inline function get total():Int {
		return AnimationObjectGroup._objects.length;
	}

	public inline function get inUse():Int {
		return this.total - AnimationObjectGroup.nCachedObjects_;
	}

	public inline function get bindingsPerObject():Int {
		return AnimationObjectGroup._bindings.length;
	}
}

class PropertyBinding {
	public function new(object:Dynamic, path:String, parsedPath:Dynamic) {
	}
}