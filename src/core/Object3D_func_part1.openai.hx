import three.math.Quaternion;
import three.math.Vector3;
import three.math.Matrix4;
import three.core.EventDispatcher;
import three.math.Euler;
import three.core.Layers;
import three.math.Matrix3;
import three.math.MathUtils;

var _object3DId = 0;

var _v1 = new Vector3();
var _q1 = new Quaternion();
var _m1 = new Matrix4();
var _target = new Vector3();

var _position = new Vector3();
var _scale = new Vector3();
var _quaternion = new Quaternion();

var _xAxis = new Vector3(1, 0, 0);
var _yAxis = new Vector3(0, 1, 0);
var _zAxis = new Vector3(0, 0, 1);

var _addedEvent = { "type": "added" };
var _removedEvent = { "type": "removed" };

var _childaddedEvent = { "type": "childadded", "child": null };
var _childremovedEvent = { "type": "childremoved", "child": null };


class Object3D extends EventDispatcher {
  
  public var isObject3D: Bool = true;
  public var id: Int = _object3DId++;
  public var uuid: String = MathUtils.generateUUID();
  public var name: String = '';
  public var type: String = 'Object3D';
  public var parent: Object3D = null;
  public var children: Array<Object3D> = [];
  public var up: Vector3 = Object3D.DEFAULT_UP.clone();
  public var position: Vector3 = new Vector3();
  public var rotation: Euler = new Euler();
  public var quaternion: Quaternion = new Quaternion();
  public var scale: Vector3 = new Vector3(1, 1, 1);
  public var modelViewMatrix: Matrix4 = new Matrix4();
  public var normalMatrix: Matrix3 = new Matrix3();
  public var matrix: Matrix4 = new Matrix4();
  public var matrixWorld: Matrix4 = new Matrix4();
  public var matrixAutoUpdate: Bool = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
  public var matrixWorldAutoUpdate: Bool = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE;
  public var matrixWorldNeedsUpdate: Bool = false;
  public var layers: Layers = new Layers();
  public var visible: Bool = true;
  public var castShadow: Bool = false;
  public var receiveShadow: Bool = false;
  public var frustumCulled: Bool = true;
  public var renderOrder: Int = 0;
  public var animations: Array = [];
  public var userData: Dynamic = {};
  
  function new() {
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
    this.userData = {};
    super();
  }
  
  public function onBeforeShadow() {
    // code
  }
  
  public function onAfterShadow() {
    // code
  }
  
  public function onBeforeRender() {
    // code
  }
  
  public function onAfterRender() {
    // code
  }
  
  public function applyMatrix4(matrix: Matrix4): Void {
    if (this.matrixAutoUpdate) this.updateMatrix();
    this.matrix.premultiply(matrix);
    this.matrix.decompose(this.position, this.quaternion, this.scale);
  }
  
  public function applyQuaternion(q: Quaternion): Object3D {
    this.quaternion.premultiply(q);
    return this;
  }
  
  public function setRotationFromAxisAngle(axis: Vector3, angle: Float): Void {
    this.quaternion.setFromAxisAngle(axis, angle);
  }
  
  public function setRotationFromEuler(euler: Euler): Void {
    this.quaternion.setFromEuler(euler, true);
  }
  
  public function setRotationFromMatrix(m: Matrix4): Void {
    this.quaternion.setFromRotationMatrix(m);
  }
  
  public function setRotationFromQuaternion(q: Quaternion): Void {
    this.quaternion.copy(q);
  }
  
  public function rotateOnAxis(axis: Vector3, angle: Float): Object3D {
    _q1.setFromAxisAngle(axis, angle);
    this.quaternion.multiply(_q1);
    return this;
  }
  
  public function rotateOnWorldAxis(axis: Vector3, angle: Float): Object3D {
    _q1.setFromAxisAngle(axis, angle);
    this.quaternion.premultiply(_q1);
    return this;
  }
  
  public function rotateX(angle: Float): Object3D {
    return this.rotateOnAxis(_xAxis, angle);
  }
  
  public function rotateY(angle: Float): Object3D {
    return this.rotateOnAxis(_yAxis, angle);
  }
  
  public function rotateZ(angle: Float): Object3D {
    return this.rotateOnAxis(_zAxis, angle);
  }
  
  public function translateOnAxis(axis: Vector3, distance: Float): Object3D {
    _v1.copy(axis).applyQuaternion(this.quaternion);
    this.position.add(_v1.multiplyScalar(distance));
    return this;
  }
  
  public function translateX(distance: Float): Object3D {
    return this.translateOnAxis(_xAxis, distance);
  }
  
  public function translateY(distance: Float): Object3D {
    return this.translateOnAxis(_yAxis, distance);
  }
  
  public function translateZ(distance: Float): Object3D {
    return this.translateOnAxis(_zAxis, distance);
  }
  
  public function localToWorld(vector: Vector3): Vector3 {
    this.updateWorldMatrix(true, false);
    return vector.applyMatrix4(this.matrixWorld);
  }
  
  public function worldToLocal(vector: Vector3): Vector3 {
    this.updateWorldMatrix(true, false);
    return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
  }
  
  public function lookAt(x: Float, y: Float, z: Float): Void {
    if (x is Vector3) {
      _target.copy(x);
    } else {
      _target.set(x, y, z);
    }
    var parent = this.parent;
    this.updateWorldMatrix(true, false);
    _position.setFromMatrixPosition(this.matrixWorld);
    if (this.isCamera || this.isLight) {
      _m1.lookAt(_position, _target, this.up);
    } else {
      _m1.lookAt(_target, _position, this.up);
    }
    this.quaternion.setFromRotationMatrix(_m1);
    if (parent) {
      _m1.extractRotation(parent.matrixWorld);
      _q1.setFromRotationMatrix(_m1);
      this.quaternion.premultiply(_q1.invert());
    }
  }
  
  public function add(object: Object3D): Object3D {
    if (arguments.length > 1) {
      for (i in 0...arguments.length) {
        this.add(arguments[i]);
      }
      return this;
    }
    if (object == this) {
      trace('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
      return this;
    }
    if (object != null && object.isObject3D) {
      object.removeFromParent();
      object.parent = this;
      this.children.push(object);
      object.dispatchEvent(_addedEvent);
      _childaddedEvent.child = object;
      this.dispatchEvent(_childaddedEvent);
      _childaddedEvent.child = null;
    } else {
      trace('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
    }
    return this;
  }
  
  public function remove(object: Object3D): Object3D {
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
      object.dispatchEvent(_removedEvent);
      _childremovedEvent.child = object;
      this.dispatchEvent(_childremovedEvent);
      _childremovedEvent.child = null;
    }
    return this;
  }
  
  public function removeFromParent(): Object3D {
    var parent = this.parent;
    if (parent != null) {
      parent.remove(this);
    }
    return this;
  }
  
  public function clear(): Object3D {
    return this.remove(...this.children);
  }
  
  public function attach(object: Object3D): Object3D {
    this.updateWorldMatrix(true, false);
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
  
  public function getObjectById(id: Int): Object3D {
    return this.getObjectByProperty("id", id);
  }
  
  public function getObjectByName(name: String): Object3D {
    return this.getObjectByProperty("name", name);
  }
  
  public function getObjectByProperty(name: String, value: Dynamic): Dynamic {
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
  
  public function getObjectsByProperty(name: String, value: Dynamic, result: Array<Object3D> = []): Array<Object3D> {
    if (this[name] == value) result.push(this);
    for (i in 0...this.children.length) {
      this.children[i].getObjectsByProperty(name, value, result);
    }
    return result;
  }
  
  public function getWorldPosition(target: Vector3): Vector3 {
    this.updateWorldMatrix(true, false);
    return target.setFromMatrixPosition(this.matrixWorld);
  }
  
  public function getWorldQuaternion(target: Quaternion): Quaternion {
    this.updateWorldMatrix(true, false);
    this.matrixWorld.decompose(_position, target, _scale);
    return target;
  }
  
  public function getWorldScale(target: Vector3): Vector3 {
    this.updateWorldMatrix(true, false);
    this.matrixWorld.decompose(_position, _quaternion, target);
    return target;
  }
  
  public function getWorldDirection(target: Vector3): Vector3 {
    this.updateWorldMatrix(true, false);
    var e = this.matrixWorld.elements;
    return target.set(e[8], e[9], e[10]).normalize();
  }
  
  public function raycast(): Void {
    
  }
  
}