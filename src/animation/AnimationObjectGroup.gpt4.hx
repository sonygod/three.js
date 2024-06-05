import MathUtils from "../math/MathUtils";
import PropertyBinding from "./PropertyBinding";

/**
 *
 * A group of objects that receives a shared animation state.
 *
 * Usage:
 *
 *  - Add objects you would otherwise pass as 'root' to the
 *    constructor or the .clipAction method of AnimationMixer.
 *
 *  - Instead pass this object as 'root'.
 *
 *  - You can also add and remove objects later when the mixer
 *    is running.
 *
 * Note:
 *
 *    Objects of this class appear as one object to the mixer,
 *    so cache control of the individual objects must be done
 *    on the group.
 *
 * Limitation:
 *
 *  - The animated properties must be compatible among the
 *    all objects in the group.
 *
 *  - A single property can either be controlled through a
 *    target group or directly, but not both.
 */
class AnimationObjectGroup {
	public isAnimationObjectGroup:Bool = true;
	public uuid:String;
	private _objects:Array<Dynamic>;
	private nCachedObjects_:Int;
	private _indicesByUUID:Map<String, Int>;
	private _paths:Array<String>;
	private _parsedPaths:Array<Dynamic>;
	private _bindings:Array<Array<PropertyBinding>>;
	private _bindingsIndicesByPath:Map<String, Int>;

	public get stats() {
		return {
			objects: {
				get total() {
					return this._objects.length;
				},
				get inUse() {
					return this.total - this.nCachedObjects_;
				}
			},
			get bindingsPerObject() {
				return this._bindings.length;
			}
		};
	}

	public constructor(...objects:Array<Dynamic>) {
		this.uuid = MathUtils.generateUUID();
		this._objects = objects.copy();
		this.nCachedObjects_ = 0;
		this._indicesByUUID = new Map();
		for (var i = 0; i < objects.length; i++) {
			this._indicesByUUID.set(objects[i].uuid, i);
		}
		this._paths = [];
		this._parsedPaths = [];
		this._bindings = [];
		this._bindingsIndicesByPath = new Map();
	}

	public add(...objects:Array<Dynamic>):Void {
		var objects = this._objects;
		var indicesByUUID = this._indicesByUUID;
		var paths = this._paths;
		var parsedPaths = this._parsedPaths;
		var bindings = this._bindings;
		var nBindings = bindings.length;
		var knownObject = null;
		var nObjects = objects.length;
		var nCachedObjects = this.nCachedObjects_;
		for (var i = 0; i < objects.length; i++) {
			var object = objects[i];
			var uuid = object.uuid;
			var index = indicesByUUID.get(uuid);
			if (index == null) {
				// unknown object -> add it to the ACTIVE region
				index = nObjects++;
				indicesByUUID.set(uuid, index);
				objects.push(object);
				// accounting is done, now do the same for all bindings
				for (var j = 0; j < nBindings; j++) {
					bindings[j].push(new PropertyBinding(object, paths[j], parsedPaths[j]));
				}
			} else if (index < nCachedObjects) {
				knownObject = objects[index];
				// move existing object to the ACTIVE region
				var firstActiveIndex = --nCachedObjects;
				var lastCachedObject = objects[firstActiveIndex];
				indicesByUUID.set(lastCachedObject.uuid, index);
				objects[index] = lastCachedObject;
				indicesByUUID.set(uuid, firstActiveIndex);
				objects[firstActiveIndex] = object;
				// accounting is done, now do the same for all bindings
				for (var j = 0; j < nBindings; j++) {
					var bindingsForPath = bindings[j];
					var lastCached = bindingsForPath[firstActiveIndex];
					var binding = bindingsForPath[index];
					bindingsForPath[index] = lastCached;
					if (binding == null) {
						// since we do not bother to create new bindings
						// for objects that are cached, the binding may
						// or may not exist
						binding = new PropertyBinding(object, paths[j], parsedPaths[j]);
					}
					bindingsForPath[firstActiveIndex] = binding;
				}
			} else if (objects[index] != knownObject) {
				console.error('THREE.AnimationObjectGroup: Different objects with the same UUID ' +
					'detected. Clean the caches or recreate your infrastructure when reloading scenes.');
			}
		}
		this.nCachedObjects_ = nCachedObjects;
	}

	public remove(...objects:Array<Dynamic>):Void {
		var objects = this._objects;
		var indicesByUUID = this._indicesByUUID;
		var bindings = this._bindings;
		var nBindings = bindings.length;
		var nCachedObjects = this.nCachedObjects_;
		for (var i = 0; i < objects.length; i++) {
			var object = objects[i];
			var uuid = object.uuid;
			var index = indicesByUUID.get(uuid);
			if (index != null && index >= nCachedObjects) {
				// move existing object into the CACHED region
				var lastCachedIndex = nCachedObjects++;
				var firstActiveObject = objects[lastCachedIndex];
				indicesByUUID.set(firstActiveObject.uuid, index);
				objects[index] = firstActiveObject;
				indicesByUUID.set(uuid, lastCachedIndex);
				objects[lastCachedIndex] = object;
				// accounting is done, now do the same for all bindings
				for (var j = 0; j < nBindings; j++) {
					var bindingsForPath = bindings[j];
					var firstActive = bindingsForPath[lastCachedIndex];
					var binding = bindingsForPath[index];
					bindingsForPath[index] = firstActive;
					bindingsForPath[lastCachedIndex] = binding;
				}
			}
		}
		this.nCachedObjects_ = nCachedObjects;
	}

	// remove & forget
	public uncache(...objects:Array<Dynamic>):Void {
		var objects = this._objects;
		var indicesByUUID = this._indicesByUUID;
		var bindings = this._bindings;
		var nBindings = bindings.length;
		var nCachedObjects = this.nCachedObjects_;
		var nObjects = objects.length;
		for (var i = 0; i < objects.length; i++) {
			var object = objects[i];
			var uuid = object.uuid;
			var index = indicesByUUID.get(uuid);
			if (index != null) {
				indicesByUUID.remove(uuid);
				if (index < nCachedObjects) {
					// object is cached, shrink the CACHED region
					var firstActiveIndex = --nCachedObjects;
					var lastCachedObject = objects[firstActiveIndex];
					var lastIndex = --nObjects;
					var lastObject = objects[lastIndex];
					// last cached object takes this object's place
					indicesByUUID.set(lastCachedObject.uuid, index);
					objects[index] = lastCachedObject;
					// last object goes to the activated slot and pop
					indicesByUUID.set(lastObject.uuid, firstActiveIndex);
					objects[firstActiveIndex] = lastObject;
					objects.pop();
					// accounting is done, now do the same for all bindings
					for (var j = 0; j < nBindings; j++) {
						var bindingsForPath = bindings[j];
						var lastCached = bindingsForPath[firstActiveIndex];
						var last = bindingsForPath[lastIndex];
						bindingsForPath[index] = lastCached;
						bindingsForPath[firstActiveIndex] = last;
						bindingsForPath.pop();
					}
				} else {
					// object is active, just swap with the last and pop
					var lastIndex = --nObjects;
					var lastObject = objects[lastIndex];
					if (lastIndex > 0) {
						indicesByUUID.set(lastObject.uuid, index);
					}
					objects[index] = lastObject;
					objects.pop();
					// accounting is done, now do the same for all bindings
					for (var j = 0; j < nBindings; j++) {
						var bindingsForPath = bindings[j];
						bindingsForPath[index] = bindingsForPath[lastIndex];
						bindingsForPath.pop();
					}
				}
			}
		}
		this.nCachedObjects_ = nCachedObjects;
	}

	// Internal interface used by befriended PropertyBinding.Composite:
	public subscribe_(path:String, parsedPath:Dynamic):Array<PropertyBinding> {
		// returns an array of bindings for the given path that is changed
		// according to the contained objects in the group
		var indicesByPath = this._bindingsIndicesByPath;
		var index = indicesByPath.get(path);
		var bindings = this._bindings;
		if (index != null) {
			return bindings[index];
		}
		var paths = this._paths;
		var parsedPaths = this._parsedPaths;
		var objects = this._objects;
		var nObjects = objects.length;
		var nCachedObjects = this.nCachedObjects_;
		var bindingsForPath = new Array<PropertyBinding>(nObjects);
		index = bindings.length;
		indicesByPath.set(path, index);
		paths.push(path);
		parsedPaths.push(parsedPath);
		bindings.push(bindingsForPath);
		for (var i = nCachedObjects; i < nObjects; i++) {
			var object = objects[i];
			bindingsForPath[i] = new PropertyBinding(object, path, parsedPath);
		}
		return bindingsForPath;
	}

	public unsubscribe_(path:String):Void {
		// tells the group to forget about a property path and no longer
		// update the array previously obtained with 'subscribe_'
		var indicesByPath = this._bindingsIndicesByPath;
		var index = indicesByPath.get(path);
		if (index != null) {
			var paths = this._paths;
			var parsedPaths = this._parsedPaths;
			var bindings = this._bindings;
			var lastBindingsIndex = bindings.length - 1;
			var lastBindings = bindings[lastBindingsIndex];
			var lastBindingsPath = path[lastBindingsIndex];
			indicesByPath.set(lastBindingsPath, index);
			bindings[index] = lastBindings;
			bindings.pop();
			parsedPaths[index] = parsedPaths[lastBindingsIndex];
			parsedPaths.pop();
			paths[index] = paths[lastBindingsIndex];
			paths.pop();
		}
	}
}

export default AnimationObjectGroup;