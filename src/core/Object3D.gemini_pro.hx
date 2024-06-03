import haxe.ds.Vector;
import haxe.extern.Rest;
import three.core.EventDispatcher;
import three.math.Euler;
import three.math.Layers;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;
import three.math.MathUtils;

class Object3D extends EventDispatcher {

	public static DEFAULT_UP:Vector3 = new Vector3(0, 1, 0);
	public static DEFAULT_MATRIX_AUTO_UPDATE:Bool = true;
	public static DEFAULT_MATRIX_WORLD_AUTO_UPDATE:Bool = true;

	private static _object3DId:Int = 0;
	private static _v1:Vector3 = new Vector3();
	private static _q1:Quaternion = new Quaternion();
	private static _m1:Matrix4 = new Matrix4();
	private static _target:Vector3 = new Vector3();
	private static _position:Vector3 = new Vector3();
	private static _scale:Vector3 = new Vector3();
	private static _quaternion:Quaternion = new Quaternion();
	private static _xAxis:Vector3 = new Vector3(1, 0, 0);
	private static _yAxis:Vector3 = new Vector3(0, 1, 0);
	private static _zAxis:Vector3 = new Vector3(0, 0, 1);
	private static _addedEvent:Dynamic = { type: 'added' };
	private static _removedEvent:Dynamic = { type: 'removed' };
	private static _childaddedEvent:Dynamic = { type: 'childadded', child: null };
	private static _childremovedEvent:Dynamic = { type: 'childremoved', child: null };

	public isObject3D:Bool;
	public id:Int;
	public uuid:String;
	public name:String;
	public type:String;
	public parent:Object3D;
	public children:Array<Object3D>;
	public up:Vector3;
	public position:Vector3;
	public rotation:Euler;
	public quaternion:Quaternion;
	public scale:Vector3;
	public modelViewMatrix:Matrix4;
	public normalMatrix:Matrix3;
	public matrix:Matrix4;
	public matrixWorld:Matrix4;
	public matrixAutoUpdate:Bool;
	public matrixWorldAutoUpdate:Bool;
	public matrixWorldNeedsUpdate:Bool;
	public layers:Layers;
	public visible:Bool;
	public castShadow:Bool;
	public receiveShadow:Bool;
	public frustumCulled:Bool;
	public renderOrder:Int;
	public animations:Array<Dynamic>;
	public userData:Dynamic;

	public function new() {
		super();

		this.isObject3D = true;
		this.id = Object3D._object3DId++;
		this.uuid = MathUtils.generateUUID();
		this.name = "";
		this.type = "Object3D";
		this.parent = null;
		this.children = new Array<Object3D>();
		this.up = Object3D.DEFAULT_UP.clone();
		this.position = new Vector3();
		this.rotation = new Euler();
		this.quaternion = new Quaternion();
		this.scale = new Vector3(1, 1, 1);
		this.modelViewMatrix = new Matrix4();
		this.normalMatrix = new Matrix3();
		this.matrix = new Matrix4();
		this.matrixWorld = new Matrix4();
		this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
		this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE;
		this.matrixWorldNeedsUpdate = false;
		this.layers = new Layers();
		this.visible = true;
		this.castShadow = false;
		this.receiveShadow = false;
		this.frustumCulled = true;
		this.renderOrder = 0;
		this.animations = new Array<Dynamic>();
		this.userData = {};

		var onRotationChange = function() {
			this.quaternion.setFromEuler(this.rotation, false);
		};
		var onQuaternionChange = function() {
			this.rotation.setFromQuaternion(this.quaternion, undefined, false);
		};
		this.rotation.onChange(onRotationChange);
		this.quaternion.onChange(onQuaternionChange);
	}

	public function onBeforeShadow(renderer:Dynamic, object:Dynamic, camera:Dynamic, shadowCamera:Dynamic, geometry:Dynamic, depthMaterial:Dynamic, group:Dynamic):Void {
	}

	public function onAfterShadow(renderer:Dynamic, object:Dynamic, camera:Dynamic, shadowCamera:Dynamic, geometry:Dynamic, depthMaterial:Dynamic, group:Dynamic):Void {
	}

	public function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, material:Dynamic, group:Dynamic):Void {
	}

	public function onAfterRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, material:Dynamic, group:Dynamic):Void {
	}

	public function applyMatrix4(matrix:Matrix4):Void {
		if (this.matrixAutoUpdate) this.updateMatrix();
		this.matrix.premultiply(matrix);
		this.matrix.decompose(this.position, this.quaternion, this.scale);
	}

	public function applyQuaternion(q:Quaternion):Object3D {
		this.quaternion.premultiply(q);
		return this;
	}

	public function setRotationFromAxisAngle(axis:Vector3, angle:Float):Void {
		this.quaternion.setFromAxisAngle(axis, angle);
	}

	public function setRotationFromEuler(euler:Euler):Void {
		this.quaternion.setFromEuler(euler, true);
	}

	public function setRotationFromMatrix(m:Matrix4):Void {
		this.quaternion.setFromRotationMatrix(m);
	}

	public function setRotationFromQuaternion(q:Quaternion):Void {
		this.quaternion.copy(q);
	}

	public function rotateOnAxis(axis:Vector3, angle:Float):Object3D {
		Object3D._q1.setFromAxisAngle(axis, angle);
		this.quaternion.multiply(Object3D._q1);
		return this;
	}

	public function rotateOnWorldAxis(axis:Vector3, angle:Float):Object3D {
		Object3D._q1.setFromAxisAngle(axis, angle);
		this.quaternion.premultiply(Object3D._q1);
		return this;
	}

	public function rotateX(angle:Float):Object3D {
		return this.rotateOnAxis(Object3D._xAxis, angle);
	}

	public function rotateY(angle:Float):Object3D {
		return this.rotateOnAxis(Object3D._yAxis, angle);
	}

	public function rotateZ(angle:Float):Object3D {
		return this.rotateOnAxis(Object3D._zAxis, angle);
	}

	public function translateOnAxis(axis:Vector3, distance:Float):Object3D {
		Object3D._v1.copy(axis).applyQuaternion(this.quaternion);
		this.position.add(Object3D._v1.multiplyScalar(distance));
		return this;
	}

	public function translateX(distance:Float):Object3D {
		return this.translateOnAxis(Object3D._xAxis, distance);
	}

	public function translateY(distance:Float):Object3D {
		return this.translateOnAxis(Object3D._yAxis, distance);
	}

	public function translateZ(distance:Float):Object3D {
		return this.translateOnAxis(Object3D._zAxis, distance);
	}

	public function localToWorld(vector:Vector3):Vector3 {
		this.updateWorldMatrix(true, false);
		return vector.applyMatrix4(this.matrixWorld);
	}

	public function worldToLocal(vector:Vector3):Vector3 {
		this.updateWorldMatrix(true, false);
		return vector.applyMatrix4(Object3D._m1.copy(this.matrixWorld).invert());
	}

	public function lookAt(x:Dynamic, y:Dynamic, z:Dynamic):Void {
		if (Rest.isVector3(x)) {
			Object3D._target.copy(x);
		} else {
			Object3D._target.set(x, y, z);
		}
		var parent = this.parent;
		this.updateWorldMatrix(true, false);
		Object3D._position.setFromMatrixPosition(this.matrixWorld);
		if (this.isCamera || this.isLight) {
			Object3D._m1.lookAt(Object3D._position, Object3D._target, this.up);
		} else {
			Object3D._m1.lookAt(Object3D._target, Object3D._position, this.up);
		}
		this.quaternion.setFromRotationMatrix(Object3D._m1);
		if (parent != null) {
			Object3D._m1.extractRotation(parent.matrixWorld);
			Object3D._q1.setFromRotationMatrix(Object3D._m1);
			this.quaternion.premultiply(Object3D._q1.invert());
		}
	}

	public function add(object:Object3D):Object3D {
		if (arguments.length > 1) {
			for (i in 0...arguments.length) {
				this.add(arguments[i]);
			}
			return this;
		}
		if (object == this) {
			throw "THREE.Object3D.add: object can't be added as a child of itself.";
		}
		if (object != null && object.isObject3D) {
			object.removeFromParent();
			object.parent = this;
			this.children.push(object);
			object.dispatchEvent(Object3D._addedEvent);
			Object3D._childaddedEvent.child = object;
			this.dispatchEvent(Object3D._childaddedEvent);
			Object3D._childaddedEvent.child = null;
		} else {
			throw "THREE.Object3D.add: object not an instance of THREE.Object3D.";
		}
		return this;
	}

	public function remove(object:Object3D):Object3D {
		if (arguments.length > 1) {
			for (i in 0...arguments.length) {
				this.remove(arguments[i]);
			}
			return this;
		}
		var index = this.children.indexOf(object);
		if (index != -1) {
			object.parent = null;
			this.children.splice(index, 1);
			object.dispatchEvent(Object3D._removedEvent);
			Object3D._childremovedEvent.child = object;
			this.dispatchEvent(Object3D._childremovedEvent);
			Object3D._childremovedEvent.child = null;
		}
		return this;
	}

	public function removeFromParent():Object3D {
		var parent = this.parent;
		if (parent != null) {
			parent.remove(this);
		}
		return this;
	}

	public function clear():Object3D {
		return this.remove(...this.children);
	}

	public function attach(object:Object3D):Object3D {
		this.updateWorldMatrix(true, false);
		Object3D._m1.copy(this.matrixWorld).invert();
		if (object.parent != null) {
			object.parent.updateWorldMatrix(true, false);
			Object3D._m1.multiply(object.parent.matrixWorld);
		}
		object.applyMatrix4(Object3D._m1);
		object.removeFromParent();
		object.parent = this;
		this.children.push(object);
		object.updateWorldMatrix(false, true);
		object.dispatchEvent(Object3D._addedEvent);
		Object3D._childaddedEvent.child = object;
		this.dispatchEvent(Object3D._childaddedEvent);
		Object3D._childaddedEvent.child = null;
		return this;
	}

	public function getObjectById(id:Int):Object3D {
		return this.getObjectByProperty('id', id);
	}

	public function getObjectByName(name:String):Object3D {
		return this.getObjectByProperty('name', name);
	}

	public function getObjectByProperty(name:String, value:Dynamic):Object3D {
		if (this[name] == value) return this;
		for (i in 0...this.children.length) {
			var child = this.children[i];
			var object = child.getObjectByProperty(name, value);
			if (object != null) {
				return object;
			}
		}
		return null;
	}

	public function getObjectsByProperty(name:String, value:Dynamic, result:Array<Object3D> = new Array<Object3D>()):Array<Object3D> {
		if (this[name] == value) result.push(this);
		for (i in 0...this.children.length) {
			this.children[i].getObjectsByProperty(name, value, result);
		}
		return result;
	}

	public function getWorldPosition(target:Vector3):Vector3 {
		this.updateWorldMatrix(true, false);
		return target.setFromMatrixPosition(this.matrixWorld);
	}

	public function getWorldQuaternion(target:Quaternion):Quaternion {
		this.updateWorldMatrix(true, false);
		this.matrixWorld.decompose(Object3D._position, target, Object3D._scale);
		return target;
	}

	public function getWorldScale(target:Vector3):Vector3 {
		this.updateWorldMatrix(true, false);
		this.matrixWorld.decompose(Object3D._position, Object3D._quaternion, target);
		return target;
	}

	public function getWorldDirection(target:Vector3):Vector3 {
		this.updateWorldMatrix(true, false);
		var e = this.matrixWorld.elements;
		return target.set(e[8], e[9], e[10]).normalize();
	}

	public function raycast(raycaster:Dynamic, intersects:Dynamic):Void {
	}

	public function traverse(callback:Dynamic):Void {
		callback(this);
		for (i in 0...this.children.length) {
			this.children[i].traverse(callback);
		}
	}

	public function traverseVisible(callback:Dynamic):Void {
		if (!this.visible) return;
		callback(this);
		for (i in 0...this.children.length) {
			this.children[i].traverseVisible(callback);
		}
	}

	public function traverseAncestors(callback:Dynamic):Void {
		var parent = this.parent;
		if (parent != null) {
			callback(parent);
			parent.traverseAncestors(callback);
		}
	}

	public function updateMatrix():Void {
		this.matrix.compose(this.position, this.quaternion, this.scale);
		this.matrixWorldNeedsUpdate = true;
	}

	public function updateMatrixWorld(force:Bool = false):Void {
		if (this.matrixAutoUpdate) this.updateMatrix();
		if (this.matrixWorldNeedsUpdate || force) {
			if (this.parent == null) {
				this.matrixWorld.copy(this.matrix);
			} else {
				this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
			}
			this.matrixWorldNeedsUpdate = false;
			force = true;
		}
		for (i in 0...this.children.length) {
			var child = this.children[i];
			if (child.matrixWorldAutoUpdate || force) {
				child.updateMatrixWorld(force);
			}
		}
	}

	public function updateWorldMatrix(updateParents:Bool = false, updateChildren:Bool = false):Void {
		var parent = this.parent;
		if (updateParents && parent != null && parent.matrixWorldAutoUpdate) {
			parent.updateWorldMatrix(true, false);
		}
		if (this.matrixAutoUpdate) this.updateMatrix();
		if (this.parent == null) {
			this.matrixWorld.copy(this.matrix);
		} else {
			this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
		}
		if (updateChildren) {
			for (i in 0...this.children.length) {
				var child = this.children[i];
				if (child.matrixWorldAutoUpdate) {
					child.updateWorldMatrix(false, true);
				}
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = (meta == null || typeof(meta) == 'String');
		var output = {};
		if (isRootObject) {
			meta = {
				geometries: {},
				materials: {},
				textures: {},
				images: {},
				shapes: {},
				skeletons: {},
				animations: {},
				nodes: {}
			};
			output.metadata = {
				version: 4.6,
				type: 'Object',
				generator: 'Object3D.toJSON'
			};
		}
		var object = {};
		object.uuid = this.uuid;
		object.type = this.type;
		if (this.name != "") object.name = this.name;
		if (this.castShadow) object.castShadow = true;
		if (this.receiveShadow) object.receiveShadow = true;
		if (!this.visible) object.visible = false;
		if (!this.frustumCulled) object.frustumCulled = false;
		if (this.renderOrder != 0) object.renderOrder = this.renderOrder;
		if (Reflect.field(this.userData, 'length') > 0) object.userData = this.userData;
		object.layers = this.layers.mask;
		object.matrix = this.matrix.toArray();
		object.up = this.up.toArray();
		if (!this.matrixAutoUpdate) object.matrixAutoUpdate = false;
		if (this.isInstancedMesh) {
			object.type = 'InstancedMesh';
			object.count = this.count;
			object.instanceMatrix = this.instanceMatrix.toJSON();
			if (this.instanceColor != null) object.instanceColor = this.instanceColor.toJSON();
		}
		if (this.isBatchedMesh) {
			object.type = 'BatchedMesh';
			object.perObjectFrustumCulled = this.perObjectFrustumCulled;
			object.sortObjects = this.sortObjects;
			object.drawRanges = this._drawRanges;
			object.reservedRanges = this._reservedRanges;
			object.visibility = this._visibility;
			object.active = this._active;
			object.bounds = this._bounds.map(bound => ( {
				boxInitialized: bound.boxInitialized,
				boxMin: bound.box.min.toArray(),
				boxMax: bound.box.max.toArray(),
				sphereInitialized: bound.sphereInitialized,
				sphereRadius: bound.sphere.radius,
				sphereCenter: bound.sphere.center.toArray()
			} ) );
			object.maxGeometryCount = this._maxGeometryCount;
			object.maxVertexCount = this._maxVertexCount;
			object.maxIndexCount = this._maxIndexCount;
			object.geometryInitialized = this._geometryInitialized;
			object.geometryCount = this._geometryCount;
			object.matricesTexture = this._matricesTexture.toJSON(meta);
			if (this._colorsTexture != null) object.colorsTexture = this._colorsTexture.toJSON(meta);
			if (this.boundingSphere != null) {
				object.boundingSphere = {
					center: object.boundingSphere.center.toArray(),
					radius: object.boundingSphere.radius
				};
			}
			if (this.boundingBox != null) {
				object.boundingBox = {
					min: object.boundingBox.min.toArray(),
					max: object.boundingBox.max.toArray()
				};
			}
		}
		var serialize = function(library:Dynamic, element:Dynamic) {
			if (library[element.uuid] == null) {
				library[element.uuid] = element.toJSON(meta);
			}
			return element.uuid;
		};
		if (this.isScene) {
			if (this.background != null) {
				if (this.background.isColor) {
					object.background = this.background.toJSON();
				} else if (this.background.isTexture) {
					object.background = this.background.toJSON(meta).uuid;
				}
			}
			if (this.environment != null && this.environment.isTexture && !this.environment.isRenderTargetTexture) {
				object.environment = this.environment.toJSON(meta).uuid;
			}
		} else if (this.isMesh || this.isLine || this.isPoints) {
			object.geometry = serialize(meta.geometries, this.geometry);
			var parameters = this.geometry.parameters;
			if (parameters != null && parameters.shapes != null) {
				var shapes = parameters.shapes;
				if (Reflect.is(shapes, Array)) {
					for (i in 0...shapes.length) {
						var shape = shapes[i];
						serialize(meta.shapes, shape);
					}
				} else {
					serialize(meta.shapes, shapes);
				}
			}
		}
		if (this.isSkinnedMesh) {
			object.bindMode = this.bindMode;
			object.bindMatrix = this.bindMatrix.toArray();
			if (this.skeleton != null) {
				serialize(meta.skeletons, this.skeleton);
				object.skeleton = this.skeleton.uuid;
			}
		}
		if (this.material != null) {
			if (Reflect.is(this.material, Array)) {
				var uuids = new Array<String>();
				for (i in 0...this.material.length) {
					uuids.push(serialize(meta.materials, this.material[i]));
				}
				object.material = uuids;
			} else {
				object.material = serialize(meta.materials, this.material);
			}
		}
		if (this.children.length > 0) {
			object.children = new Array<Dynamic>();
			for (i in 0...this.children.length) {
				object.children.push(this.children[i].toJSON(meta).object);
			}
		}
		if (this.animations.length > 0) {
			object.animations = new Array<Dynamic>();
			for (i in 0...this.animations.length) {
				var animation = this.animations[i];
				object.animations.push(serialize(meta.animations, animation));
			}
		}
		if (isRootObject) {
			var geometries = extractFromCache(meta.geometries);
			var materials = extractFromCache(meta.materials);
			var textures = extractFromCache(meta.textures);
			var images = extractFromCache(meta.images);
			var shapes = extractFromCache(meta.shapes);
			var skeletons = extractFromCache(meta.skeletons);
			var animations = extractFromCache(meta.animations);
			var nodes = extractFromCache(meta.nodes);
			if (geometries.length > 0) output.geometries = geometries;
			if (materials.length > 0) output.materials = materials;
			if (textures.length > 0) output.textures = textures;
			if (images.length > 0) output.images = images;
			if (shapes.length > 0) output.shapes = shapes;
			if (skeletons.length > 0) output.skeletons = skeletons;
			if (animations.length > 0) output.animations = animations;
			if (nodes.length > 0) output.nodes = nodes;
		}
		output.object = object;
		return output;
		var extractFromCache = function(cache:Dynamic):Array<Dynamic> {
			var values = new Array<Dynamic>();
			for (key in Reflect.fields(cache)) {
				var data = cache[key];
				Reflect.deleteField(data, 'metadata');
				values.push(data);
			}
			return values;
		};
	}

	public function clone(recursive:Bool = true):Object3D {
		return new Object3D().copy(this, recursive);
	}

	public function copy(source:Object3D, recursive:Bool = true):Object3D {
		this.name = source.name;
		this.up.copy(source.up);
		this.position.copy(source.position);
		this.rotation.order = source.rotation.order;
		this.quaternion.copy(source.quaternion);
		this.scale.copy(source.scale);
		this.matrix.copy(source.matrix);
		this.matrixWorld.copy(source.matrixWorld);
		this.matrixAutoUpdate = source.matrixAutoUpdate;
		this.matrixWorldAutoUpdate = source.matrixWorldAutoUpdate;
		this.matrixWorldNeedsUpdate = source.matrixWorldNeedsUpdate;
		this.layers.mask = source.layers.mask;
		this.visible = source.visible;
		this.castShadow = source.castShadow;
		this.receiveShadow = source.receiveShadow;
		this.frustumCulled = source.frustumCulled;
		this.renderOrder = source.renderOrder;
		this.animations = source.animations.copy();
		this.userData = Reflect.copy(source.userData);
		if (recursive) {
			for (i in 0...source.children.length) {
				var child = source.children[i];
				this.add(child.clone());
			}
		}
		return this;
	}

	// --- Private/Protected ---
	// These are internal functions, but exposed for compatibility with the Three.js API.

	public function get isCamera():Bool {
		return false;
	}

	public function get isLight():Bool {
		return false;
	}

	public function get isMesh():Bool {
		return false;
	}

	public function get isLine():Bool {
		return false;
	}

	public function get isPoints():Bool {
		return false;
	}

	public function get isSkinnedMesh():Bool {
		return false;
	}

	public function get isInstancedMesh():Bool {
		return false;
	}

	public function get isScene():Bool {
		return false;
	}

	public function get isBatchedMesh():Bool {
		return false;
	}

	public function get count():Int {
		return 0;
	}

	public function get instanceMatrix():Dynamic {
		return null;
	}

	public function get instanceColor():Dynamic {
		return null;
	}

	public function get perObjectFrustumCulled():Bool {
		return false;
	}

	public function get sortObjects():Bool {
		return false;
	}

	public function get _drawRanges():Array<Dynamic> {
		return null;
	}

	public function get _reservedRanges():Array<Dynamic> {
		return null;
	}

	public function get _visibility():Array<Bool> {
		return null;
	}

	public function get _active():Array<Bool> {
		return null;
	}

	public function get _bounds():Array<Dynamic> {
		return null;
	}

	public function get _maxGeometryCount():Int {
		return 0;
	}

	public function get _maxVertexCount():Int {
		return 0;
	}

	public function get _maxIndexCount():Int {
		return 0;
	}

	public function get _geometryInitialized():Bool {
		return false;
	}

	public function get _geometryCount():Int {
		return 0;
	}

	public function get _matricesTexture():Dynamic {
		return null;
	}

	public function get _colorsTexture():Dynamic {
		return null;
	}

	public function get bindMode():String {
		return null;
	}

	public function get bindMatrix():Matrix4 {
		return null;
	}

	public function get skeleton():Dynamic {
		return null;
	}

	public function get geometry():Dynamic {
		return null;
	}

	public function get material():Dynamic {
		return null;
	}

	public function get boundingSphere():Dynamic {
		return null;
	}

	public function get boundingBox():Dynamic {
		return null;
	}

	public function get background():Dynamic {
		return null;
	}

	public function get environment():Dynamic {
		return null;
	}

}