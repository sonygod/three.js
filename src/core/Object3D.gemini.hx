import haxe.ds.StringMap;
import three.math.Euler;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;
import three.core.EventDispatcher;
import three.core.Layers;
import three.math.MathUtils;

class Object3D extends EventDispatcher {

	public var isObject3D:Bool = true;
	public var id:Int;
	public var uuid:String;
	public var name:String;
	public var type:String;
	public var parent:Object3D;
	public var children:Array<Object3D>;
	public var up:Vector3;
	public var position:Vector3;
	public var rotation:Euler;
	public var quaternion:Quaternion;
	public var scale:Vector3;
	public var modelViewMatrix:Matrix4;
	public var normalMatrix:Matrix3;
	public var matrix:Matrix4;
	public var matrixWorld:Matrix4;
	public var matrixAutoUpdate:Bool;
	public var matrixWorldAutoUpdate:Bool;
	public var matrixWorldNeedsUpdate:Bool;
	public var layers:Layers;
	public var visible:Bool;
	public var castShadow:Bool;
	public var receiveShadow:Bool;
	public var frustumCulled:Bool;
	public var renderOrder:Int;
	public var animations:Array<Dynamic>;
	public var userData:StringMap<Dynamic>;

	static public var DEFAULT_UP:Vector3 = new Vector3(0, 1, 0);
	static public var DEFAULT_MATRIX_AUTO_UPDATE:Bool = true;
	static public var DEFAULT_MATRIX_WORLD_AUTO_UPDATE:Bool = true;

	public function new() {
		super();
		this.id = _object3DId++;
		this.uuid = MathUtils.generateUUID();
		this.name = "";
		this.type = "Object3D";
		this.parent = null;
		this.children = [];
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
		this.animations = [];
		this.userData = new StringMap();
		this.rotation.onChange(this.onRotationChange);
		this.quaternion.onChange(this.onQuaternionChange);
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
		var _q1 = new Quaternion();
		_q1.setFromAxisAngle(axis, angle);
		this.quaternion.multiply(_q1);
		return this;
	}

	public function rotateOnWorldAxis(axis:Vector3, angle:Float):Object3D {
		var _q1 = new Quaternion();
		_q1.setFromAxisAngle(axis, angle);
		this.quaternion.premultiply(_q1);
		return this;
	}

	public function rotateX(angle:Float):Object3D {
		return this.rotateOnAxis(_xAxis, angle);
	}

	public function rotateY(angle:Float):Object3D {
		return this.rotateOnAxis(_yAxis, angle);
	}

	public function rotateZ(angle:Float):Object3D {
		return this.rotateOnAxis(_zAxis, angle);
	}

	public function translateOnAxis(axis:Vector3, distance:Float):Object3D {
		var _v1 = new Vector3();
		_v1.copy(axis).applyQuaternion(this.quaternion);
		this.position.add(_v1.multiplyScalar(distance));
		return this;
	}

	public function translateX(distance:Float):Object3D {
		return this.translateOnAxis(_xAxis, distance);
	}

	public function translateY(distance:Float):Object3D {
		return this.translateOnAxis(_yAxis, distance);
	}

	public function translateZ(distance:Float):Object3D {
		return this.translateOnAxis(_zAxis, distance);
	}

	public function localToWorld(vector:Vector3):Vector3 {
		this.updateWorldMatrix(true, false);
		return vector.applyMatrix4(this.matrixWorld);
	}

	public function worldToLocal(vector:Vector3):Vector3 {
		this.updateWorldMatrix(true, false);
		var _m1 = new Matrix4();
		return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
	}

	public function lookAt(x:Dynamic, y:Dynamic, z:Dynamic):Void {
		var _target = new Vector3();
		if (cast x.isVector3) {
			_target.copy(x);
		} else {
			_target.set(x, y, z);
		}
		var parent = this.parent;
		this.updateWorldMatrix(true, false);
		var _position = new Vector3();
		_position.setFromMatrixPosition(this.matrixWorld);
		if (this.isCamera || this.isLight) {
			var _m1 = new Matrix4();
			_m1.lookAt(_position, _target, this.up);
		} else {
			var _m1 = new Matrix4();
			_m1.lookAt(_target, _position, this.up);
		}
		this.quaternion.setFromRotationMatrix(_m1);
		if (parent != null) {
			var _m1 = new Matrix4();
			_m1.extractRotation(parent.matrixWorld);
			var _q1 = new Quaternion();
			_q1.setFromRotationMatrix(_m1);
			this.quaternion.premultiply(_q1.invert());
		}
	}

	public function add(object:Dynamic):Object3D {
		if (object is Object3D) {
			if (object == this) {
				trace('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
				return this;
			}
			object.removeFromParent();
			object.parent = this;
			this.children.push(object);
			object.dispatchEvent(_addedEvent);
			_childaddedEvent.child = object;
			this.dispatchEvent(_childaddedEvent);
			_childaddedEvent.child = null;
			return this;
		}
		else if (cast object is Array) {
			for (i in object) {
				add(object[i]);
			}
			return this;
		}
		trace('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
		return this;
	}

	public function remove(object:Dynamic):Object3D {
		if (object is Object3D) {
			var index = this.children.indexOf(object);
			if (index != -1) {
				object.parent = null;
				this.children.splice(index, 1);
				object.dispatchEvent(_removedEvent);
				_childremovedEvent.child = object;
				this.dispatchEvent(_childremovedEvent);
				_childremovedEvent.child = null;
				return this;
			}
			return this;
		}
		else if (cast object is Array) {
			for (i in object) {
				remove(object[i]);
			}
			return this;
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
		return this.remove(this.children);
	}

	public function attach(object:Object3D):Object3D {
		this.updateWorldMatrix(true, false);
		var _m1 = new Matrix4();
		_m1.copy(this.matrixWorld).invert();
		if (object.parent != null) {
			object.parent.updateWorldMatrix(true, false);
			_m1.multiply(object.parent.matrixWorld);
		}
		object.applyMatrix4(_m1);
		object.removeFromParent();
		object.parent = this;
		this.children.push(object);
		object.updateWorldMatrix(false, true);
		object.dispatchEvent(_addedEvent);
		_childaddedEvent.child = object;
		this.dispatchEvent(_childaddedEvent);
		_childaddedEvent.child = null;
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
		for (i in this.children) {
			var child = this.children[i];
			var object = child.getObjectByProperty(name, value);
			if (object != null) {
				return object;
			}
		}
		return null;
	}

	public function getObjectsByProperty(name:String, value:Dynamic, result:Array<Object3D> = []):Array<Object3D> {
		if (this[name] == value) result.push(this);
		for (i in this.children) {
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
		this.matrixWorld.decompose(null, target, null);
		return target;
	}

	public function getWorldScale(target:Vector3):Vector3 {
		this.updateWorldMatrix(true, false);
		this.matrixWorld.decompose(null, null, target);
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
		for (i in this.children) {
			this.children[i].traverse(callback);
		}
	}

	public function traverseVisible(callback:Dynamic):Void {
		if (this.visible == false) return;
		callback(this);
		for (i in this.children) {
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
		for (i in this.children) {
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
			for (i in this.children) {
				var child = this.children[i];
				if (child.matrixWorldAutoUpdate) {
					child.updateWorldMatrix(false, true);
				}
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = (meta == null || typeof meta == "String");
		var output = new StringMap();
		if (isRootObject) {
			meta = {
				geometries: new StringMap(),
				materials: new StringMap(),
				textures: new StringMap(),
				images: new StringMap(),
				shapes: new StringMap(),
				skeletons: new StringMap(),
				animations: new StringMap(),
				nodes: new StringMap()
			};
			output.set("metadata", {
				version: 4.6,
				type: "Object",
				generator: "Object3D.toJSON"
			});
		}
		var object = new StringMap();
		object.set("uuid", this.uuid);
		object.set("type", this.type);
		if (this.name != "") object.set("name", this.name);
		if (this.castShadow) object.set("castShadow", true);
		if (this.receiveShadow) object.set("receiveShadow", true);
		if (this.visible == false) object.set("visible", false);
		if (this.frustumCulled == false) object.set("frustumCulled", false);
		if (this.renderOrder != 0) object.set("renderOrder", this.renderOrder);
		if (this.userData.keys().length > 0) object.set("userData", this.userData);
		object.set("layers", this.layers.mask);
		object.set("matrix", this.matrix.toArray());
		object.set("up", this.up.toArray());
		if (this.matrixAutoUpdate == false) object.set("matrixAutoUpdate", false);
		if (this.isInstancedMesh) {
			object.set("type", "InstancedMesh");
			object.set("count", this.count);
			object.set("instanceMatrix", this.instanceMatrix.toJSON());
			if (this.instanceColor != null) object.set("instanceColor", this.instanceColor.toJSON());
		}
		if (this.isBatchedMesh) {
			object.set("type", "BatchedMesh");
			object.set("perObjectFrustumCulled", this.perObjectFrustumCulled);
			object.set("sortObjects", this.sortObjects);
			object.set("drawRanges", this._drawRanges);
			object.set("reservedRanges", this._reservedRanges);
			object.set("visibility", this._visibility);
			object.set("active", this._active);
			object.set("bounds", this._bounds.map(function(bound) {
				return {
					boxInitialized: bound.boxInitialized,
					boxMin: bound.box.min.toArray(),
					boxMax: bound.box.max.toArray(),
					sphereInitialized: bound.sphereInitialized,
					sphereRadius: bound.sphere.radius,
					sphereCenter: bound.sphere.center.toArray()
				};
			}));
			object.set("maxGeometryCount", this._maxGeometryCount);
			object.set("maxVertexCount", this._maxVertexCount);
			object.set("maxIndexCount", this._maxIndexCount);
			object.set("geometryInitialized", this._geometryInitialized);
			object.set("geometryCount", this._geometryCount);
			object.set("matricesTexture", this._matricesTexture.toJSON(meta));
			if (this._colorsTexture != null) object.set("colorsTexture", this._colorsTexture.toJSON(meta));
			if (this.boundingSphere != null) {
				object.set("boundingSphere", {
					center: this.boundingSphere.center.toArray(),
					radius: this.boundingSphere.radius
				});
			}
			if (this.boundingBox != null) {
				object.set("boundingBox", {
					min: this.boundingBox.min.toArray(),
					max: this.boundingBox.max.toArray()
				});
			}
		}
		function serialize(library:StringMap<Dynamic>, element:Dynamic):String {
			if (library.exists(element.uuid)) {
				return element.uuid;
			}
			library.set(element.uuid, element.toJSON(meta));
			return element.uuid;
		}
		if (this.isScene) {
			if (this.background != null) {
				if (this.background.isColor) {
					object.set("background", this.background.toJSON());
				} else if (this.background.isTexture) {
					object.set("background", serialize(meta.textures, this.background).uuid);
				}
			}
			if (this.environment != null && this.environment.isTexture && this.environment.isRenderTargetTexture == false) {
				object.set("environment", serialize(meta.textures, this.environment).uuid);
			}
		} else if (this.isMesh || this.isLine || this.isPoints) {
			object.set("geometry", serialize(meta.geometries, this.geometry));
			var parameters = this.geometry.parameters;
			if (parameters != null && parameters.shapes != null) {
				var shapes = parameters.shapes;
				if (shapes is Array) {
					for (i in shapes) {
						var shape = shapes[i];
						serialize(meta.shapes, shape);
					}
				} else {
					serialize(meta.shapes, shapes);
				}
			}
		}
		if (this.isSkinnedMesh) {
			object.set("bindMode", this.bindMode);
			object.set("bindMatrix", this.bindMatrix.toArray());
			if (this.skeleton != null) {
				serialize(meta.skeletons, this.skeleton);
				object.set("skeleton", this.skeleton.uuid);
			}
		}
		if (this.material != null) {
			if (this.material is Array) {
				var uuids = new Array();
				for (i in this.material) {
					uuids.push(serialize(meta.materials, this.material[i]));
				}
				object.set("material", uuids);
			} else {
				object.set("material", serialize(meta.materials, this.material));
			}
		}
		if (this.children.length > 0) {
			var children = new Array();
			for (i in this.children) {
				children.push(this.children[i].toJSON(meta).object);
			}
			object.set("children", children);
		}
		if (this.animations.length > 0) {
			var animations = new Array();
			for (i in this.animations) {
				var animation = this.animations[i];
				animations.push(serialize(meta.animations, animation));
			}
			object.set("animations", animations);
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
			if (geometries.length > 0) output.set("geometries", geometries);
			if (materials.length > 0) output.set("materials", materials);
			if (textures.length > 0) output.set("textures", textures);
			if (images.length > 0) output.set("images", images);
			if (shapes.length > 0) output.set("shapes", shapes);
			if (skeletons.length > 0) output.set("skeletons", skeletons);
			if (animations.length > 0) output.set("animations", animations);
			if (nodes.length > 0) output.set("nodes", nodes);
		}
		output.set("object", object);
		return output;
		function extractFromCache(cache:StringMap<Dynamic>):Array<Dynamic> {
			var values = new Array();
			for (key in cache.keys()) {
				var data = cache.get(key);
				data.remove("metadata");
				values.push(data);
			}
			return values;
		}
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
		this.userData = source.userData.copy();
		if (recursive) {
			for (i in source.children) {
				var child = source.children[i];
				this.add(child.clone());
			}
		}
		return this;
	}

	private function onRotationChange():Void {
		this.quaternion.setFromEuler(this.rotation, false);
	}

	private function onQuaternionChange():Void {
		this.rotation.setFromQuaternion(this.quaternion, undefined, false);
	}
}

private var _object3DId:Int = 0;
private var _xAxis:Vector3 = new Vector3(1, 0, 0);
private var _yAxis:Vector3 = new Vector3(0, 1, 0);
private var _zAxis:Vector3 = new Vector3(0, 0, 1);
private var _addedEvent:Dynamic = {type: "added"};
private var _removedEvent:Dynamic = {type: "removed"};
private var _childaddedEvent:Dynamic = {type: "childadded", child: null};
private var _childremovedEvent:Dynamic = {type: "childremoved", child: null};