import haxe.ds.StringMap;
import haxe.ds.Vector;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.ComplexType;
import haxe.macro.ExprOps;
import haxe.macro.Constant;
import haxe.macro.ComplexType.Field;
import haxe.macro.ComplexType.Enum;
import haxe.macro.ComplexType.Interface;

import three.math.MathUtils;
import three.PropertyBinding;

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

	// cached objects followed by the active ones
	private var _objects:Vector<Dynamic>;

	public var nCachedObjects_:Int = 0; // threshold
	// note: read by PropertyBinding.Composite

	private var _indicesByUUID:StringMap<Int>;

	private var _paths:Vector<String>;

	private var _parsedPaths:Vector<Dynamic>;

	private var _bindings:Vector<Vector<PropertyBinding>>;

	private var _bindingsIndicesByPath:StringMap<Int>;

	public var stats:Stats;

	public function new(?objects:Array<Dynamic>) {

		this.isAnimationObjectGroup = true;

		this.uuid = MathUtils.generateUUID();

		this._objects = new Vector();
		if (objects != null) {
			this._objects.push(objects);
		}

		this.nCachedObjects_ = 0;

		this._indicesByUUID = new StringMap();

		this._paths = new Vector();

		this._parsedPaths = new Vector();

		this._bindings = new Vector();

		this._bindingsIndicesByPath = new StringMap();

		this.stats = new Stats(this);

	}

	public function add(?objects:Array<Dynamic>):Void {

		if (objects == null) return;

		var objects = this._objects;
		var indicesByUUID = this._indicesByUUID;
		var paths = this._paths;
		var parsedPaths = this._parsedPaths;
		var bindings = this._bindings;
		var nBindings = bindings.length;

		var knownObject:Dynamic = null;
		var nObjects = objects.length;
		var nCachedObjects = this.nCachedObjects_;

		for (object in objects) {

			var uuid = object.uuid;
			var index = indicesByUUID.get(uuid);

			if (index == null) {

				// unknown object -> add it to the ACTIVE region

				index = nObjects ++;
				indicesByUUID.set(uuid, index);
				objects.push(object);

				// accounting is done, now do the same for all bindings

				for (j in 0...nBindings) {

					bindings[j].push(new PropertyBinding(object, paths[j], parsedPaths[j]));

				}

			} else if (index < nCachedObjects) {

				knownObject = objects[index];

				// move existing object to the ACTIVE region

				var firstActiveIndex = -- nCachedObjects;
				var lastCachedObject = objects[firstActiveIndex];

				indicesByUUID.set(lastCachedObject.uuid, index);
				objects[index] = lastCachedObject;

				indicesByUUID.set(uuid, firstActiveIndex);
				objects[firstActiveIndex] = object;

				// accounting is done, now do the same for all bindings

				for (j in 0...nBindings) {

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

				console.error("THREE.AnimationObjectGroup: Different objects with the same UUID " +
					"detected. Clean the caches or recreate your infrastructure when reloading scenes.");

			} // else the object is already where we want it to be

		} // for arguments

		this.nCachedObjects_ = nCachedObjects;

	}

	public function remove(?objects:Array<Dynamic>):Void {

		if (objects == null) return;

		var objects = this._objects;
		var indicesByUUID = this._indicesByUUID;
		var bindings = this._bindings;
		var nBindings = bindings.length;

		var nCachedObjects = this.nCachedObjects_;

		for (object in objects) {

			var uuid = object.uuid;
			var index = indicesByUUID.get(uuid);

			if (index != null && index >= nCachedObjects) {

				// move existing object into the CACHED region

				var lastCachedIndex = nCachedObjects ++;
				var firstActiveObject = objects[lastCachedIndex];

				indicesByUUID.set(firstActiveObject.uuid, index);
				objects[index] = firstActiveObject;

				indicesByUUID.set(uuid, lastCachedIndex);
				objects[lastCachedIndex] = object;

				// accounting is done, now do the same for all bindings

				for (j in 0...nBindings) {

					var bindingsForPath = bindings[j];
					var firstActive = bindingsForPath[lastCachedIndex];
					var binding = bindingsForPath[index];

					bindingsForPath[index] = firstActive;
					bindingsForPath[lastCachedIndex] = binding;

				}

			}

		} // for arguments

		this.nCachedObjects_ = nCachedObjects;

	}

	// remove & forget
	public function uncache(?objects:Array<Dynamic>):Void {

		if (objects == null) return;

		var objects = this._objects;
		var indicesByUUID = this._indicesByUUID;
		var bindings = this._bindings;
		var nBindings = bindings.length;

		var nCachedObjects = this.nCachedObjects_;
		var nObjects = objects.length;

		for (object in objects) {

			var uuid = object.uuid;
			var index = indicesByUUID.get(uuid);

			if (index != null) {

				indicesByUUID.remove(uuid);

				if (index < nCachedObjects) {

					// object is cached, shrink the CACHED region

					var firstActiveIndex = -- nCachedObjects;
					var lastCachedObject = objects[firstActiveIndex];
					var lastIndex = -- nObjects;
					var lastObject = objects[lastIndex];

					// last cached object takes this object's place
					indicesByUUID.set(lastCachedObject.uuid, index);
					objects[index] = lastCachedObject;

					// last object goes to the activated slot and pop
					indicesByUUID.set(lastObject.uuid, firstActiveIndex);
					objects[firstActiveIndex] = lastObject;
					objects.pop();

					// accounting is done, now do the same for all bindings

					for (j in 0...nBindings) {

						var bindingsForPath = bindings[j];
						var lastCached = bindingsForPath[firstActiveIndex];
						var last = bindingsForPath[lastIndex];

						bindingsForPath[index] = lastCached;
						bindingsForPath[firstActiveIndex] = last;
						bindingsForPath.pop();

					}

				} else {

					// object is active, just swap with the last and pop

					var lastIndex = -- nObjects;
					var lastObject = objects[lastIndex];

					if (lastIndex > 0) {

						indicesByUUID.set(lastObject.uuid, index);

					}

					objects[index] = lastObject;
					objects.pop();

					// accounting is done, now do the same for all bindings

					for (j in 0...nBindings) {

						var bindingsForPath = bindings[j];

						bindingsForPath[index] = bindingsForPath[lastIndex];
						bindingsForPath.pop();

					}

				} // cached or active

			} // if object is known

		} // for arguments

		this.nCachedObjects_ = nCachedObjects;

	}

	// Internal interface used by befriended PropertyBinding.Composite:

	public function subscribe_(path:String, parsedPath:Dynamic):Vector<PropertyBinding> {

		// returns an array of bindings for the given path that is changed
		// according to the contained objects in the group

		var indicesByPath = this._bindingsIndicesByPath;
		var index = indicesByPath.get(path);
		var bindings = this._bindings;

		if (index != null) return bindings[index];

		var paths = this._paths;
		var parsedPaths = this._parsedPaths;
		var objects = this._objects;
		var nObjects = objects.length;
		var nCachedObjects = this.nCachedObjects_;
		var bindingsForPath:Vector<PropertyBinding> = new Vector();

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

class Stats {

	private var _scope:AnimationObjectGroup;

	public function new(scope:AnimationObjectGroup) {
		this._scope = scope;
	}

	public var objects:Objects;

	public function get bindingsPerObject():Int {
		return _scope._bindings.length;
	}

	class Objects {

		private var _scope:Stats;

		public function new(scope:Stats) {
			this._scope = scope;
		}

		public function get total():Int {
			return _scope._scope._objects.length;
		}

		public function get inUse():Int {
			return this.total - _scope._scope.nCachedObjects_;
		}

	}

}