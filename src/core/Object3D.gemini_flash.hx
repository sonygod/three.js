package three;

import three.math.Euler;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;
import three.math.MathUtils;
import three.core.Layers;
import three.core.EventDispatcher;

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
	public var userData:Dynamic;

	public function new() {
		super();
		id = _object3DId++;
		uuid = MathUtils.generateUUID();
		name = "";
		type = "Object3D";
		parent = null;
		children = new Array<Object3D>();
		up = Object3D.DEFAULT_UP.clone();
		position = new Vector3();
		rotation = new Euler();
		quaternion = new Quaternion();
		scale = new Vector3(1, 1, 1);

		rotation.onChange = onRotationChange;
		quaternion.onChange = onQuaternionChange;

		modelViewMatrix = new Matrix4();
		normalMatrix = new Matrix3();

		matrix = new Matrix4();
		matrixWorld = new Matrix4();
		matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
		matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE;
		matrixWorldNeedsUpdate = false;
		layers = new Layers();
		visible = true;
		castShadow = false;
		receiveShadow = false;
		frustumCulled = true;
		renderOrder = 0;
		animations = new Array<Dynamic>();
		userData = {};
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
		if (matrixAutoUpdate) updateMatrix();
		this.matrix.premultiply(matrix);
		this.matrix.decompose(this.position, this.quaternion, this.scale);
	}

	public function applyQuaternion(q:Quaternion):Object3D {
		quaternion.premultiply(q);
		return this;
	}

	public function setRotationFromAxisAngle(axis:Vector3, angle:Float):Void {
		quaternion.setFromAxisAngle(axis, angle);
	}

	public function setRotationFromEuler(euler:Euler):Void {
		quaternion.setFromEuler(euler, true);
	}

	public function setRotationFromMatrix(m:Matrix4):Void {
		quaternion.setFromRotationMatrix(m);
	}

	public function setRotationFromQuaternion(q:Quaternion):Void {
		quaternion.copy(q);
	}

	public function rotateOnAxis(axis:Vector3, angle:Float):Object3D {
		_q1.setFromAxisAngle(axis, angle);
		quaternion.multiply(_q1);
		return this;
	}

	public function rotateOnWorldAxis(axis:Vector3, angle:Float):Object3D {
		_q1.setFromAxisAngle(axis, angle);
		quaternion.premultiply(_q1);
		return this;
	}

	public function rotateX(angle:Float):Object3D {
		return rotateOnAxis(_xAxis, angle);
	}

	public function rotateY(angle:Float):Object3D {
		return rotateOnAxis(_yAxis, angle);
	}

	public function rotateZ(angle:Float):Object3D {
		return rotateOnAxis(_zAxis, angle);
	}

	public function translateOnAxis(axis:Vector3, distance:Float):Object3D {
		_v1.copy(axis).applyQuaternion(quaternion);
		position.add(_v1.multiplyScalar(distance));
		return this;
	}

	public function translateX(distance:Float):Object3D {
		return translateOnAxis(_xAxis, distance);
	}

	public function translateY(distance:Float):Object3D {
		return translateOnAxis(_yAxis, distance);
	}

	public function translateZ(distance:Float):Object3D {
		return translateOnAxis(_zAxis, distance);
	}

	public function localToWorld(vector:Vector3):Vector3 {
		updateWorldMatrix(true, false);
		return vector.applyMatrix4(matrixWorld);
	}

	public function worldToLocal(vector:Vector3):Vector3 {
		updateWorldMatrix(true, false);
		return vector.applyMatrix4(_m1.copy(matrixWorld).invert());
	}

	public function lookAt(x:Dynamic, y:Dynamic, z:Dynamic):Void {
		if (cast(x, Vector3)) {
			_target.copy(x);
		} else {
			_target.set(x, y, z);
		}

		var parent = this.parent;

		updateWorldMatrix(true, false);
		_position.setFromMatrixPosition(matrixWorld);

		if (isCamera || isLight) {
			_m1.lookAt(_position, _target, up);
		} else {
			_m1.lookAt(_target, _position, up);
		}

		quaternion.setFromRotationMatrix(_m1);

		if (parent != null) {
			_m1.extractRotation(parent.matrixWorld);
			_q1.setFromRotationMatrix(_m1);
			quaternion.premultiply(_q1.invert());
		}
	}

	public function add(object:Object3D):Object3D {
		if (object == this) {
			console.error("THREE.Object3D.add: object can't be added as a child of itself.", object);
			return this;
		}
		if (object != null && object.isObject3D) {
			object.removeFromParent();
			object.parent = this;
			children.push(object);
			object.dispatchEvent(_addedEvent);
			_childaddedEvent.child = object;
			dispatchEvent(_childaddedEvent);
			_childaddedEvent.child = null;
		} else {
			console.error("THREE.Object3D.add: object not an instance of THREE.Object3D.", object);
		}
		return this;
	}

	public function remove(object:Object3D):Object3D {
		var index = children.indexOf(object);
		if (index != -1) {
			object.parent = null;
			children.splice(index, 1);
			object.dispatchEvent(_removedEvent);
			_childremovedEvent.child = object;
			dispatchEvent(_childremovedEvent);
			_childremovedEvent.child = null;
		}
		return this;
	}

	public function removeFromParent():Object3D {
		if (parent != null) {
			parent.remove(this);
		}
		return this;
	}

	public function clear():Object3D {
		for (child in children) remove(child);
		return this;
	}

	public function attach(object:Object3D):Object3D {
		updateWorldMatrix(true, false);
		_m1.copy(matrixWorld).invert();
		if (object.parent != null) {
			object.parent.updateWorldMatrix(true, false);
			_m1.multiply(object.parent.matrixWorld);
		}
		object.applyMatrix4(_m1);
		object.removeFromParent();
		object.parent = this;
		children.push(object);
		object.updateWorldMatrix(false, true);
		object.dispatchEvent(_addedEvent);
		_childaddedEvent.child = object;
		dispatchEvent(_childaddedEvent);
		_childaddedEvent.child = null;
		return this;
	}

	public function getObjectById(id:Int):Object3D {
		return getObjectByProperty("id", id);
	}

	public function getObjectByName(name:String):Object3D {
		return getObjectByProperty("name", name);
	}

	public function getObjectByProperty(name:String, value:Dynamic):Object3D {
		if (this[name] == value) {
			return this;
		}
		for (child in children) {
			var object = child.getObjectByProperty(name, value);
			if (object != null) {
				return object;
			}
		}
		return null;
	}

	public function getObjectsByProperty(name:String, value:Dynamic, result:Array<Object3D> = new Array<Object3D>()):Array<Object3D> {
		if (this[name] == value) {
			result.push(this);
		}
		for (child in children) {
			child.getObjectsByProperty(name, value, result);
		}
		return result;
	}

	public function getWorldPosition(target:Vector3):Vector3 {
		updateWorldMatrix(true, false);
		return target.setFromMatrixPosition(matrixWorld);
	}

	public function getWorldQuaternion(target:Quaternion):Quaternion {
		updateWorldMatrix(true, false);
		matrixWorld.decompose(_position, target, _scale);
		return target;
	}

	public function getWorldScale(target:Vector3):Vector3 {
		updateWorldMatrix(true, false);
		matrixWorld.decompose(_position, _quaternion, target);
		return target;
	}

	public function getWorldDirection(target:Vector3):Vector3 {
		updateWorldMatrix(true, false);
		var e = matrixWorld.elements;
		return target.set(e[8], e[9], e[10]).normalize();
	}

	public function raycast(raycaster:Dynamic, intersects:Dynamic):Void {
	}

	public function traverse(callback:Dynamic):Void {
		callback(this);
		for (child in children) child.traverse(callback);
	}

	public function traverseVisible(callback:Dynamic):Void {
		if (visible == false) {
			return;
		}
		callback(this);
		for (child in children) child.traverseVisible(callback);
	}

	public function traverseAncestors(callback:Dynamic):Void {
		if (parent != null) {
			callback(parent);
			parent.traverseAncestors(callback);
		}
	}

	public function updateMatrix():Void {
		matrix.compose(position, quaternion, scale);
		matrixWorldNeedsUpdate = true;
	}

	public function updateMatrixWorld(force:Bool = false):Void {
		if (matrixAutoUpdate) updateMatrix();
		if (matrixWorldNeedsUpdate || force) {
			if (parent == null) {
				matrixWorld.copy(matrix);
			} else {
				matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
			}
			matrixWorldNeedsUpdate = false;
			force = true;
		}
		for (child in children) {
			if (child.matrixWorldAutoUpdate || force) {
				child.updateMatrixWorld(force);
			}
		}
	}

	public function updateWorldMatrix(updateParents:Bool = false, updateChildren:Bool = false):Void {
		if (updateParents && parent != null && parent.matrixWorldAutoUpdate) {
			parent.updateWorldMatrix(true, false);
		}
		if (matrixAutoUpdate) updateMatrix();
		if (parent == null) {
			matrixWorld.copy(matrix);
		} else {
			matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
		}
		if (updateChildren) {
			for (child in children) {
				if (child.matrixWorldAutoUpdate) {
					child.updateWorldMatrix(false, true);
				}
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = (meta == null || typeof(meta) == "String");
		var output:Dynamic = {};
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
				type: "Object",
				generator: "Object3D.toJSON"
			};
		}
		var object:Dynamic = {
			uuid: uuid,
			type: type
		};
		if (name != "") object.name = name;
		if (castShadow) object.castShadow = true;
		if (receiveShadow) object.receiveShadow = true;
		if (visible == false) object.visible = false;
		if (frustumCulled == false) object.frustumCulled = false;
		if (renderOrder != 0) object.renderOrder = renderOrder;
		if (Reflect.fields(userData).length > 0) object.userData = userData;
		object.layers = layers.mask;
		object.matrix = matrix.toArray();
		object.up = up.toArray();
		if (matrixAutoUpdate == false) object.matrixAutoUpdate = false;
		if (isScene) {
			if (background != null) {
				if (cast(background, Color)) {
					object.background = background.toJSON();
				} else if (cast(background, Texture)) {
					object.background = background.toJSON(meta).uuid;
				}
			}
			if (environment != null && cast(environment, Texture) && cast(environment, RenderTargetTexture) == false) {
				object.environment = environment.toJSON(meta).uuid;
			}
		} else if (isMesh || isLine || isPoints) {
			object.geometry = serialize(meta.geometries, cast(geometry, Geometry));
			var parameters = cast(geometry, Geometry).parameters;
			if (parameters != null && parameters.shapes != null) {
				var shapes = parameters.shapes;
				if (cast(shapes, Array<Dynamic>)) {
					for (shape in shapes) {
						serialize(meta.shapes, shape);
					}
				} else {
					serialize(meta.shapes, shapes);
				}
			}
		}
		if (isSkinnedMesh) {
			object.bindMode = bindMode;
			object.bindMatrix = bindMatrix.toArray();
			if (skeleton != null) {
				serialize(meta.skeletons, skeleton);
				object.skeleton = skeleton.uuid;
			}
		}
		if (material != null) {
			if (cast(material, Array<Dynamic>)) {
				var uuids:Array<String> = new Array<String>();
				for (mat in material) {
					uuids.push(serialize(meta.materials, mat));
				}
				object.material = uuids;
			} else {
				object.material = serialize(meta.materials, material);
			}
		}
		if (children.length > 0) {
			object.children = new Array<Dynamic>();
			for (child in children) {
				object.children.push(child.toJSON(meta).object);
			}
		}
		if (animations.length > 0) {
			object.animations = new Array<Dynamic>();
			for (animation in animations) {
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
		function serialize(library:Dynamic, element:Dynamic):String {
			if (library[element.uuid] == null) {
				library[element.uuid] = element.toJSON(meta);
			}
			return element.uuid;
		}
		function extractFromCache(cache:Dynamic):Array<Dynamic> {
			var values:Array<Dynamic> = new Array<Dynamic>();
			for (key in Reflect.fields(cache)) {
				var data = cache[key];
				Reflect.deleteField(data, "metadata");
				values.push(data);
			}
			return values;
		}
	}

	public function clone(recursive:Bool = true):Object3D {
		return new Object3D().copy(this, recursive);
	}

	public function copy(source:Object3D, recursive:Bool = true):Object3D {
		name = source.name;
		up.copy(source.up);
		position.copy(source.position);
		rotation.order = source.rotation.order;
		quaternion.copy(source.quaternion);
		scale.copy(source.scale);
		matrix.copy(source.matrix);
		matrixWorld.copy(source.matrixWorld);
		matrixAutoUpdate = source.matrixAutoUpdate;
		matrixWorldAutoUpdate = source.matrixWorldAutoUpdate;
		matrixWorldNeedsUpdate = source.matrixWorldNeedsUpdate;
		layers.mask = source.layers.mask;
		visible = source.visible;
		castShadow = source.castShadow;
		receiveShadow = source.receiveShadow;
		frustumCulled = source.frustumCulled;
		renderOrder = source.renderOrder;
		animations = source.animations.copy();
		userData = Reflect.copy(source.userData);
		if (recursive) {
			for (child in source.children) {
				add(child.clone());
			}
		}
		return this;
	}

	private function onRotationChange():Void {
		quaternion.setFromEuler(rotation, false);
	}

	private function onQuaternionChange():Void {
		rotation.setFromQuaternion(quaternion, undefined, false);
	}

	private static var _object3DId:Int = 0;
	private static var _v1:Vector3 = new Vector3();
	private static var _q1:Quaternion = new Quaternion();
	private static var _m1:Matrix4 = new Matrix4();
	private static var _target:Vector3 = new Vector3();
	private static var _position:Vector3 = new Vector3();
	private static var _scale:Vector3 = new Vector3();
	private static var _quaternion:Quaternion = new Quaternion();
	private static var _xAxis:Vector3 = new Vector3(1, 0, 0);
	private static var _yAxis:Vector3 = new Vector3(0, 1, 0);
	private static var _zAxis:Vector3 = new Vector3(0, 0, 1);
	private static var _addedEvent:Dynamic = { type: "added" };
	private static var _removedEvent:Dynamic = { type: "removed" };
	private static var _childaddedEvent:Dynamic = { type: "childadded", child: null };
	private static var _childremovedEvent:Dynamic = { type: "childremoved", child: null };

	public static var DEFAULT_UP:Vector3 = new Vector3(0, 1, 0);
	public static var DEFAULT_MATRIX_AUTO_UPDATE:Bool = true;
	public static var DEFAULT_MATRIX_WORLD_AUTO_UPDATE:Bool = true;
}