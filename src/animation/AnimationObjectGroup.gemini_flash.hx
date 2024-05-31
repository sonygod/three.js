import three.math.MathUtils;
import three.animation.PropertyBinding;

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
	public var isAnimationObjectGroup:Bool = true;
	public var uuid:String;
	public var _objects:Array<Dynamic>;
	public var nCachedObjects_:Int = 0;
	public var _indicesByUUID:Map<String, Int>;
	public var _paths:Array<String> = [];
	public var _parsedPaths:Array<Dynamic> = [];
	public var _bindings:Array<Array<PropertyBinding>> = [];
	public var _bindingsIndicesByPath:Map<String, Int> = [];
	public var stats:Stats;

	public function new(?objects:Array<Dynamic>) {
		this.uuid = MathUtils.generateUUID();
		this._objects = objects != null ? objects : [];
		this._indicesByUUID = new Map<String, Int>();

		// Add initial objects to the indices map
		for (i in 0..._objects.length) {
			_indicesByUUID[_objects[i].uuid] = i;
		}

		this.stats = {
			get objects() {
				return {
					get total() {
						return _objects.length;
					},
					get inUse() {
						return this.total - nCachedObjects_;
					}
				};
			},
			get bindingsPerObject() {
				return _bindings.length;
			}
		};
	}

	public function add(?objects:Array<Dynamic>) {
		if (objects == null) return;

		var _objects = this._objects;
		var _indicesByUUID = this._indicesByUUID;
		var _paths = this._paths;
		var _parsedPaths = this._parsedPaths;
		var _bindings = this._bindings;
		var nBindings = _bindings.length;

		var knownObject:Dynamic = null;
		var nObjects = _objects.length;
		var nCachedObjects = this.nCachedObjects_;

		for (object in objects) {
			var uuid = object.uuid;
			var index = _indicesByUUID.get(uuid);

			if (index == null) {
				// unknown object -> add it to the ACTIVE region
				index = nObjects++;
				_indicesByUUID.set(uuid, index);
				_objects.push(object);

				// accounting is done, now do the same for all bindings
				for (j in 0...nBindings) {
					_bindings[j].push(new PropertyBinding(object, _paths[j], _parsedPaths[j]));
				}

			} else if (index < nCachedObjects) {
				knownObject = _objects[index];

				// move existing object to the ACTIVE region
				var firstActiveIndex = --nCachedObjects;
				var lastCachedObject = _objects[firstActiveIndex];

				_indicesByUUID.set(lastCachedObject.uuid, index);
				_objects[index] = lastCachedObject;

				_indicesByUUID.set(uuid, firstActiveIndex);
				_objects[firstActiveIndex] = object;

				// accounting is done, now do the same for all bindings
				for (j in 0...nBindings) {
					var bindingsForPath = _bindings[j];
					var lastCached = bindingsForPath[firstActiveIndex];
					var binding = bindingsForPath[index];

					bindingsForPath[index] = lastCached;

					if (binding == null) {
						// since we do not bother to create new bindings
						// for objects that are cached, the binding may
						// or may not exist
						binding = new PropertyBinding(object, _paths[j], _parsedPaths[j]);
					}

					bindingsForPath[firstActiveIndex] = binding;
				}

			} else if (_objects[index] != knownObject) {
				console.error("THREE.AnimationObjectGroup: Different objects with the same UUID " +
					"detected. Clean the caches or recreate your infrastructure when reloading scenes.");
			} // else the object is already where we want it to be
		}

		this.nCachedObjects_ = nCachedObjects;
	}

	public function remove(?objects:Array<Dynamic>) {
		if (objects == null) return;

		var _objects = this._objects;
		var _indicesByUUID = this._indicesByUUID;
		var _bindings = this._bindings;
		var nBindings = _bindings.length;

		var nCachedObjects = this.nCachedObjects_;

		for (object in objects) {
			var uuid = object.uuid;
			var index = _indicesByUUID.get(uuid);

			if (index != null && index >= nCachedObjects) {
				// move existing object into the CACHED region
				var lastCachedIndex = nCachedObjects++;
				var firstActiveObject = _objects[lastCachedIndex];

				_indicesByUUID.set(firstActiveObject.uuid, index);
				_objects[index] = firstActiveObject;

				_indicesByUUID.set(uuid, lastCachedIndex);
				_objects[lastCachedIndex] = object;

				// accounting is done, now do the same for all bindings
				for (j in 0...nBindings) {
					var bindingsForPath = _bindings[j];
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
	public function uncache(?objects:Array<Dynamic>) {
		if (objects == null) return;

		var _objects = this._objects;
		var _indicesByUUID = this._indicesByUUID;
		var _bindings = this._bindings;
		var nBindings = _bindings.length;

		var nCachedObjects = this.nCachedObjects_;
		var nObjects = _objects.length;

		for (object in objects) {
			var uuid = object.uuid;
			var index = _indicesByUUID.get(uuid);

			if (index != null) {
				_indicesByUUID.remove(uuid);

				if (index < nCachedObjects) {
					// object is cached, shrink the CACHED region
					var firstActiveIndex = --nCachedObjects;
					var lastCachedObject = _objects[firstActiveIndex];
					var lastIndex = --nObjects;
					var lastObject = _objects[lastIndex];

					// last cached object takes this object's place
					_indicesByUUID.set(lastCachedObject.uuid, index);
					_objects[index] = lastCachedObject;

					// last object goes to the activated slot and pop
					_indicesByUUID.set(lastObject.uuid, firstActiveIndex);
					_objects[firstActiveIndex] = lastObject;
					_objects.pop();

					// accounting is done, now do the same for all bindings
					for (j in 0...nBindings) {
						var bindingsForPath = _bindings[j];
						var lastCached = bindingsForPath[firstActiveIndex];
						var last = bindingsForPath[lastIndex];

						bindingsForPath[index] = lastCached;
						bindingsForPath[firstActiveIndex] = last;
						bindingsForPath.pop();
					}

				} else {
					// object is active, just swap with the last and pop
					var lastIndex = --nObjects;
					var lastObject = _objects[lastIndex];

					if (lastIndex > 0) {
						_indicesByUUID.set(lastObject.uuid, index);
					}

					_objects[index] = lastObject;
					_objects.pop();

					// accounting is done, now do the same for all bindings
					for (j in 0...nBindings) {
						var bindingsForPath = _bindings[j];

						bindingsForPath[index] = bindingsForPath[lastIndex];
						bindingsForPath.pop();
					}
				} // cached or active
			} // if object is known
		}

		this.nCachedObjects_ = nCachedObjects;
	}

	// Internal interface used by befriended PropertyBinding.Composite:
	public function subscribe_(path:String, parsedPath:Dynamic):Array<PropertyBinding> {
		// returns an array of bindings for the given path that is changed
		// according to the contained objects in the group

		var _bindingsIndicesByPath = this._bindingsIndicesByPath;
		var index = _bindingsIndicesByPath.get(path);
		var _bindings = this._bindings;

		if (index != null) return _bindings[index];

		var _paths = this._paths;
		var _parsedPaths = this._parsedPaths;
		var _objects = this._objects;
		var nObjects = _objects.length;
		var nCachedObjects = this.nCachedObjects_;
		var bindingsForPath = new Array<PropertyBinding>(nObjects);

		index = _bindings.length;

		_bindingsIndicesByPath.set(path, index);

		_paths.push(path);
		_parsedPaths.push(parsedPath);
		_bindings.push(bindingsForPath);

		for (i in nCachedObjects...nObjects) {
			var object = _objects[i];
			bindingsForPath[i] = new PropertyBinding(object, path, parsedPath);
		}

		return bindingsForPath;
	}

	public function unsubscribe_(path:String) {
		// tells the group to forget about a property path and no longer
		// update the array previously obtained with 'subscribe_'

		var _bindingsIndicesByPath = this._bindingsIndicesByPath;
		var index = _bindingsIndicesByPath.get(path);

		if (index != null) {
			var _paths = this._paths;
			var _parsedPaths = this._parsedPaths;
			var _bindings = this._bindings;
			var lastBindingsIndex = _bindings.length - 1;
			var lastBindings = _bindings[lastBindingsIndex];
			var lastBindingsPath = _paths[lastBindingsIndex];

			_bindingsIndicesByPath.set(lastBindingsPath, index);

			_bindings[index] = lastBindings;
			_bindings.pop();

			_parsedPaths[index] = _parsedPaths[lastBindingsIndex];
			_parsedPaths.pop();

			_paths[index] = _paths[lastBindingsIndex];
			_paths.pop();
		}
	}
}

typedef Stats = {
	var objects:ObjectsStats;
	var bindingsPerObject:Int;
};

typedef ObjectsStats = {
	var total:Int;
	var inUse:Int;
};