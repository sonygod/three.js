package three.js.src.core;

import math.Quaternion;
import math.Vector3;
import math.Matrix4;
import EventDispatcher;
import math.Euler;
import Layers;
import math.Matrix3;
import math.MathUtils;

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

  private static var _object3DId:Int = 0;

  private var _v1:Vector3;
  private var _q1:Quaternion;
  private var _m1:Matrix4;
  private var _target:Vector3;

  private var _xAxis:Vector3;
  private var _yAxis:Vector3;
  private var _zAxis:Vector3;

  private var _addedEvent:{ type:String };
  private var _removedEvent:{ type:String };
  private var _childaddedEvent:{ type:String, child:Object3D };
  private var _childremovedEvent:{ type:String, child:Object3D };

  public function new() {
    super();

    id = _object3DId++;
    uuid = MathUtils.generateUUID();
    name = '';
    type = 'Object3D';

    parent = null;
    children = [];

    up = new Vector3(0, 1, 0);

    position = new Vector3();
    rotation = new Euler();
    quaternion = new Quaternion();
    scale = new Vector3(1, 1, 1);

    rotation.onChange = function() {
      quaternion.setFromEuler(rotation, false);
    }

    quaternion.onChange = function() {
      rotation.setFromQuaternion(quaternion, undefined, false);
    }

    matrix = new Matrix4();
    matrixWorld = new Matrix4();

    matrixAutoUpdate = true;
    matrixWorldAutoUpdate = true;
    matrixWorldNeedsUpdate = false;

    layers = new Layers();
    visible = true;

    castShadow = false;
    receiveShadow = false;

    frustumCulled = true;
    renderOrder = 0;

    animations = [];

    userData = {};

    _v1 = new Vector3();
    _q1 = new Quaternion();
    _m1 = new Matrix4();
    _target = new Vector3();

    _xAxis = new Vector3(1, 0, 0);
    _yAxis = new Vector3(0, 1, 0);
    _zAxis = new Vector3(0, 0, 1);

    _addedEvent = { type: 'added' };
    _removedEvent = { type: 'removed' };
    _childaddedEvent = { type: 'childadded', child: null };
    _childremovedEvent = { type: 'childremoved', child: null };
  }

  // ... rest of the methods ...

  public function onBeforeShadow(/* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
  public function onAfterShadow(/* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
  public function onBeforeRender(/* renderer, scene, camera, geometry, material, group */) {}
  public function onAfterRender(/* renderer, scene, camera, geometry, material, group */) {}

  public function applyMatrix4(matrix:Matrix4) {
    if (matrixAutoUpdate) updateMatrix();
    matrix.premultiply(matrix);
    matrix.decompose(position, quaternion, scale);
  }

  public function applyQuaternion(q:Quaternion) {
    quaternion.premultiply(q);
    return this;
  }

  public function setRotationFromAxisAngle(axis:Vector3, angle:Float) {
    quaternion.setFromAxisAngle(axis, angle);
  }

  public function setRotationFromEuler(euler:Euler) {
    quaternion.setFromEuler(euler, true);
  }

  public function setRotationFromMatrix(m:Matrix4) {
    quaternion.setFromRotationMatrix(m);
  }

  public function setRotationFromQuaternion(q:Quaternion) {
    quaternion.copy(q);
  }

  public function rotateOnAxis(axis:Vector3, angle:Float) {
    _q1.setFromAxisAngle(axis, angle);
    quaternion.multiply(_q1);
    return this;
  }

  public function rotateOnWorldAxis(axis:Vector3, angle:Float) {
    _q1.setFromAxisAngle(axis, angle);
    quaternion.premultiply(_q1);
    return this;
  }

  public function rotateX(angle:Float) {
    return rotateOnAxis(_xAxis, angle);
  }

  public function rotateY(angle:Float) {
    return rotateOnAxis(_yAxis, angle);
  }

  public function rotateZ(angle:Float) {
    return rotateOnAxis(_zAxis, angle);
  }

  public function translateOnAxis(axis:Vector3, distance:Float) {
    _v1.copy(axis).applyQuaternion(quaternion);
    position.add(_v1.multiplyScalar(distance));
    return this;
  }

  public function translateX(distance:Float) {
    return translateOnAxis(_xAxis, distance);
  }

  public function translateY(distance:Float) {
    return translateOnAxis(_yAxis, distance);
  }

  public function translateZ(distance:Float) {
    return translateOnAxis(_zAxis, distance);
  }

  public function localToWorld(vector:Vector3) {
    updateWorldMatrix(true, false);
    return vector.applyMatrix4(matrixWorld);
  }

  public function worldToLocal(vector:Vector3) {
    updateWorldMatrix(true, false);
    return vector.applyMatrix4(_m1.copy(matrixWorld).invert());
  }

  public function lookAt(x:Float, y:Float, z:Float) {
    if (x.isVector3) {
      _target.copy(x);
    } else {
      _target.set(x, y, z);
    }

    const parent:Object3D = this.parent;

    updateWorldMatrix(true, false);

    _position.setFromMatrixPosition(matrixWorld);

    if (isCamera || isLight) {
      _m1.lookAt(_position, _target, up);
    } else {
      _m1.lookAt(_target, _position, up);
    }

    quaternion.setFromRotationMatrix(_m1);

    if (parent) {
      _m1.extractRotation(parent.matrixWorld);
      _q1.setFromRotationMatrix(_m1);
      quaternion.premultiply(_q1.invert());
    }
  }

  public function add(object:Object3D) {
    if (object === this) {
      console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
      return this;
    }

    if (object && object.isObject3D) {
      object.removeFromParent();
      object.parent = this;
      children.push(object);

      object.dispatchEvent(_addedEvent);

      _childaddedEvent.child = object;
      dispatchEvent(_childaddedEvent);
      _childaddedEvent.child = null;

    } else {
      console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
    }

    return this;
  }

  public function remove(object:Object3D) {
    const index:Int = children.indexOf(object);

    if (index !== -1) {
      object.parent = null;
      children.splice(index, 1);

      object.dispatchEvent(_removedEvent);

      _childremovedEvent.child = object;
      dispatchEvent(_childremovedEvent);
      _childremovedEvent.child = null;
    }

    return this;
  }

  public function removeFromParent() {
    const parent:Object3D = this.parent;

    if (parent !== null) {
      parent.remove(this);
    }

    return this;
  }

  public function clear() {
    return remove(...children);
  }

  public function attach(object:Object3D) {
    updateWorldMatrix(true, false);

    _m1.copy(matrixWorld).invert();

    if (object.parent !== null) {
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

  public function getObjectById(id:Int) {
    return getObjectByProperty('id', id);
  }

  public function getObjectByName(name:String) {
    return getObjectByProperty('name', name);
  }

  public function getObjectByProperty(name:String, value:Dynamic) {
    if (Reflect.field(this, name) == value) return this;

    for (child in children) {
      var object:Object3D = child.getObjectByProperty(name, value);
      if (object !== null) return object;
    }

    return null;
  }

  public function getObjectsByProperty(name:String, value:Dynamic, result:Array<Object3D> = []) {
    if (Reflect.field(this, name) == value) result.push(this);

    for (child in children) {
      child.getObjectsByProperty(name, value, result);
    }

    return result;
  }

  public function getWorldPosition(target:Vector3) {
    updateWorldMatrix(true, false);
    return target.setFromMatrixPosition(matrixWorld);
  }

  public function getWorldQuaternion(target:Quaternion) {
    updateWorldMatrix(true, false);
    matrixWorld.decompose(_position, target, _scale);
    return target;
  }

  public function getWorldScale(target:Vector3) {
    updateWorldMatrix(true, false);
    matrixWorld.decompose(_position, _quaternion, target);
    return target;
  }

  public function getWorldDirection(target:Vector3) {
    updateWorldMatrix(true, false);
    const e:Array<Float> = matrixWorld.elements;
    return target.set(e[8], e[9], e[10]).normalize();
  }

  public function raycast(/* raycaster, intersects */) {}
}