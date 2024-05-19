import { Quaternion } from '../math/Quaternion.js';
import { Vector3 } from '../math/Vector3.js';
import { Matrix4 } from '../math/Matrix4.js';
import { EventDispatcher } from './EventDispatcher.js';
import { Euler } from '../math/Euler.js';
import { Layers } from './Layers.js';
import { Matrix3 } from '../math/Matrix3.js';
import * as MathUtils from '../math/MathUtils.js';
let _object3DId = 0;
const _v1 = /*@__PURE__*/new Vector3();
const _q1 = /*@__PURE__*/new Quaternion();
const _m1 = /*@__PURE__*/new Matrix4();
const _target = /*@__PURE__*/new Vector3();
const _position = /*@__PURE__*/new Vector3();
const _scale = /*@__PURE__*/new Vector3();
const _quaternion = /*@__PURE__*/new Quaternion();
const _xAxis = /*@__PURE__*/new Vector3(1, 0, 0);
const _yAxis = /*@__PURE__*/new Vector3(0, 1, 0);
const _zAxis = /*@__PURE__*/new Vector3(0, 0, 1);
const _addedEvent = {
  type: 'added'
};
const _removedEvent = {
  type: 'removed'
};
const _childaddedEvent = {
  type: 'childadded',
  child: null
};
const _childremovedEvent = {
  type: 'childremoved',
  child: null
};
class Object3D extends EventDispatcher {
  constructor() {
    super();
    this.isObject3D = true;
    Object.defineProperty(this, 'id', {
      value: _object3DId++
    });
    this.uuid = MathUtils.generateUUID();
    this.name = '';
    this.type = 'Object3D';
    this.parent = null;
    this.children = [];
    this.up = Object3D.DEFAULT_UP.clone();
    const position = new Vector3();
    const rotation = new Euler();
    const quaternion = new Quaternion();
    const scale = new Vector3(1, 1, 1);
    function onRotationChange() {
      quaternion.setFromEuler(rotation, false);
    }
    function onQuaternionChange() {
      rotation.setFromQuaternion(quaternion, undefined, false);
    }
    rotation._onChange(onRotationChange);
    quaternion._onChange(onQuaternionChange);
    Object.defineProperties(this, {
      position: {
        configurable: true,
        enumerable: true,
        value: position
      },
      rotation: {
        configurable: true,
        enumerable: true,
        value: rotation
      },
      quaternion: {
        configurable: true,
        enumerable: true,
        value: quaternion
      },
      scale: {
        configurable: true,
        enumerable: true,
        value: scale
      },
      modelViewMatrix: {
        value: new Matrix4()
      },
      normalMatrix: {
        value: new Matrix3()
      }
    });
    this.matrix = new Matrix4();
    this.matrixWorld = new Matrix4();
    this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
    this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // checked by the renderer
    this.matrixWorldNeedsUpdate = false;
    this.layers = new Layers();
    this.visible = true;
    this.castShadow = false;
    this.receiveShadow = false;
    this.frustumCulled = true;
    this.renderOrder = 0;
    this.animations = [];
    this.userData = {};
  }
  onBeforeShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
  onAfterShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
  onBeforeRender( /* renderer, scene, camera, geometry, material, group */) {}
  onAfterRender( /* renderer, scene, camera, geometry, material, group */) {}
  applyMatrix4(matrix) {
    if (this.matrixAutoUpdate) this.updateMatrix();
    this.matrix.premultiply(matrix);
    this.matrix.decompose(this.position, this.quaternion, this.scale);
  }
  applyQuaternion(q) {
    this.quaternion.premultiply(q);
    return this;
  }
  setRotationFromAxisAngle(axis, angle) {
    // assumes axis is normalized

    this.quaternion.setFromAxisAngle(axis, angle);
  }
  setRotationFromEuler(euler) {
    this.quaternion.setFromEuler(euler, true);
  }
  setRotationFromMatrix(m) {
    // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

    this.quaternion.setFromRotationMatrix(m);
  }
  setRotationFromQuaternion(q) {
    // assumes q is normalized

    this.quaternion.copy(q);
  }
  rotateOnAxis(axis, angle) {
    // rotate object on axis in object space
    // axis is assumed to be normalized

    _q1.setFromAxisAngle(axis, angle);
    this.quaternion.multiply(_q1);
    return this;
  }
  rotateOnWorldAxis(axis, angle) {
    // rotate object on axis in world space
    // axis is assumed to be normalized
    // method assumes no rotated parent

    _q1.setFromAxisAngle(axis, angle);
    this.quaternion.premultiply(_q1);
    return this;
  }
  rotateX(angle) {
    return this.rotateOnAxis(_xAxis, angle);
  }
  rotateY(angle) {
    return this.rotateOnAxis(_yAxis, angle);
  }
  rotateZ(angle) {
    return this.rotateOnAxis(_zAxis, angle);
  }
  translateOnAxis(axis, distance) {
    // translate object by distance along axis in object space
    // axis is assumed to be normalized

    _v1.copy(axis).applyQuaternion(this.quaternion);
    this.position.add(_v1.multiplyScalar(distance));
    return this;
  }
  translateX(distance) {
    return this.translateOnAxis(_xAxis, distance);
  }
  translateY(distance) {
    return this.translateOnAxis(_yAxis, distance);
  }
  translateZ(distance) {
    return this.translateOnAxis(_zAxis, distance);
  }
  localToWorld(vector) {
    this.updateWorldMatrix(true, false);
    return vector.applyMatrix4(this.matrixWorld);
  }
  worldToLocal(vector) {
    this.updateWorldMatrix(true, false);
    return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
  }
  lookAt(x, y, z) {
    // This method does not support objects having non-uniformly-scaled parent(s)

    if (x.isVector3) {
      _target.copy(x);
    } else {
      _target.set(x, y, z);
    }
    const parent = this.parent;
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
  add(object) {
    if (arguments.length > 1) {
      for (let i = 0; i < arguments.length; i++) {
        this.add(arguments[i]);
      }
      return this;
    }
    if (object === this) {
      console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
      return this;
    }
    if (object && object.isObject3D) {
      object.removeFromParent();
      object.parent = this;
      this.children.push(object);
      object.dispatchEvent(_addedEvent);
      _childaddedEvent.child = object;
      this.dispatchEvent(_childaddedEvent);
      _childaddedEvent.child = null;
    } else {
      console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
    }
    return this;
  }
  remove(object) {
    if (arguments.length > 1) {
      for (let i = 0; i < arguments.length; i++) {
        this.remove(arguments[i]);
      }
      return this;
    }
    const index = this.children.indexOf(object);
    if (index !== -1) {
      object.parent = null;
      this.children.splice(index, 1);
      object.dispatchEvent(_removedEvent);
      _childremovedEvent.child = object;
      this.dispatchEvent(_childremovedEvent);
      _childremovedEvent.child = null;
    }
    return this;
  }
  removeFromParent() {
    const parent = this.parent;
    if (parent !== null) {
      parent.remove(this);
    }
    return this;
  }
  clear() {
    return this.remove(...this.children);
  }
  attach(object) {
    // adds object as a child of this, while maintaining the object's world transform

    // Note: This method does not support scene graphs having non-uniformly-scaled nodes(s)

    this.updateWorldMatrix(true, false);
    _m1.copy(this.matrixWorld).invert();
    if (object.parent !== null) {
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
  getObjectById(id) {
    return this.getObjectByProperty('id', id);
  }
  getObjectByName(name) {
    return this.getObjectByProperty('name', name);
  }
  getObjectByProperty(name, value) {
    if (this[name] === value) return this;
    for (let i = 0, l = this.children.length; i < l; i++) {
      const child = this.children[i];
      const object = child.getObjectByProperty(name, value);
      if (object !== undefined) {
        return object;
      }
    }
    return undefined;
  }
  getObjectsByProperty(name, value, result = []) {
    if (this[name] === value) result.push(this);
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      children[i].getObjectsByProperty(name, value, result);
    }
    return result;
  }
  getWorldPosition(target) {
    this.updateWorldMatrix(true, false);
    return target.setFromMatrixPosition(this.matrixWorld);
  }
  getWorldQuaternion(target) {
    this.updateWorldMatrix(true, false);
    this.matrixWorld.decompose(_position, target, _scale);
    return target;
  }
  getWorldScale(target) {
    this.updateWorldMatrix(true, false);
    this.matrixWorld.decompose(_position, _quaternion, target);
    return target;
  }
  getWorldDirection(target) {
    this.updateWorldMatrix(true, false);
    const e = this.matrixWorld.elements;
    return target.set(e[8], e[9], e[10]).normalize();
  }
  raycast( /* raycaster, intersects */) {}
  traverse(callback) {
    callback(this);
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      children[i].traverse(callback);
    }
  }
  traverseVisible(callback) {
    if (this.visible === false) return;
    callback(this);
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      children[i].traverseVisible(callback);
    }
  }
  traverseAncestors(callback) {
    const parent = this.parent;
    if (parent !== null) {
      callback(parent);
      parent.traverseAncestors(callback);
    }
  }
  updateMatrix() {
    this.matrix.compose(this.position, this.quaternion, this.scale);
    this.matrixWorldNeedsUpdate = true;
  }
  updateMatrixWorld(force) {
    if (this.matrixAutoUpdate) this.updateMatrix();
    if (this.matrixWorldNeedsUpdate || force) {
      if (this.parent === null) {
        this.matrixWorld.copy(this.matrix);
      } else {
        this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
      }
      this.matrixWorldNeedsUpdate = false;
      force = true;
    }

    // update children

    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      const child = children[i];
      if (child.matrixWorldAutoUpdate === true || force === true) {
        child.updateMatrixWorld(force);
      }
    }
  }
  updateWorldMatrix(updateParents, updateChildren) {
    const parent = this.parent;
    if (updateParents === true && parent !== null && parent.matrixWorldAutoUpdate === true) {
      parent.updateWorldMatrix(true, false);
    }
    if (this.matrixAutoUpdate) this.updateMatrix();
    if (this.parent === null) {
      this.matrixWorld.copy(this.matrix);
    } else {
      this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
    }

    // update children

    if (updateChildren === true) {
      const children = this.children;
      for (let i = 0, l = children.length; i < l; i++) {
        const child = children[i];
        if (child.matrixWorldAutoUpdate === true) {
          child.updateWorldMatrix(false, true);
        }
      }
    }
  }
  toJSON(meta) {
    // meta is a string when called from JSON.stringify
    const isRootObject = meta === undefined || typeof meta === 'string';
    const output = {};

    // meta is a hash used to collect geometries, materials.
    // not providing it implies that this is the root object
    // being serialized.
    if (isRootObject) {
      // initialize meta obj
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

    // standard Object3D serialization

    const object = {};
    object.uuid = this.uuid;
    object.type = this.type;
    if (this.name !== '') object.name = this.name;
    if (this.castShadow === true) object.castShadow = true;
    if (this.receiveShadow === true) object.receiveShadow = true;
    if (this.visible === false) object.visible = false;
    if (this.frustumCulled === false) object.frustumCulled = false;
    if (this.renderOrder !== 0) object.renderOrder = this.renderOrder;
    if (Object.keys(this.userData).length > 0) object.userData = this.userData;
    object.layers = this.layers.mask;
    object.matrix = this.matrix.toArray();
    object.up = this.up.toArray();
    if (this.matrixAutoUpdate === false) object.matrixAutoUpdate = false;

    // object specific properties

    if (this.isInstancedMesh) {
      object.type = 'InstancedMesh';
      object.count = this.count;
      object.instanceMatrix = this.instanceMatrix.toJSON();
      if (this.instanceColor !== null) object.instanceColor = this.instanceColor.toJSON();
    }
    if (this.isBatchedMesh) {
      object.type = 'BatchedMesh';
      object.perObjectFrustumCulled = this.perObjectFrustumCulled;
      object.sortObjects = this.sortObjects;
      object.drawRanges = this._drawRanges;
      object.reservedRanges = this._reservedRanges;
      object.visibility = this._visibility;
      object.active = this._active;
      object.bounds = this._bounds.map(bound => ({
        boxInitialized: bound.boxInitialized,
        boxMin: bound.box.min.toArray(),
        boxMax: bound.box.max.toArray(),
        sphereInitialized: bound.sphereInitialized,
        sphereRadius: bound.sphere.radius,
        sphereCenter: bound.sphere.center.toArray()
      }));
      object.maxGeometryCount = this._maxGeometryCount;
      object.maxVertexCount = this._maxVertexCount;
      object.maxIndexCount = this._maxIndexCount;
      object.geometryInitialized = this._geometryInitialized;
      object.geometryCount = this._geometryCount;
      object.matricesTexture = this._matricesTexture.toJSON(meta);
      if (this._colorsTexture !== null) object.colorsTexture = this._colorsTexture.toJSON(meta);
      if (this.boundingSphere !== null) {
        object.boundingSphere = {
          center: object.boundingSphere.center.toArray(),
          radius: object.boundingSphere.radius
        };
      }
      if (this.boundingBox !== null) {
        object.boundingBox = {
          min: object.boundingBox.min.toArray(),
          max: object.boundingBox.max.toArray()
        };
      }
    }

    //

    function serialize(library, element) {
      if (library[element.uuid] === undefined) {
        library[element.uuid] = element.toJSON(meta);
      }
      return element.uuid;
    }
    if (this.isScene) {
      if (this.background) {
        if (this.background.isColor) {
          object.background = this.background.toJSON();
        } else if (this.background.isTexture) {
          object.background = this.background.toJSON(meta).uuid;
        }
      }
      if (this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== true) {
        object.environment = this.environment.toJSON(meta).uuid;
      }
    } else if (this.isMesh || this.isLine || this.isPoints) {
      object.geometry = serialize(meta.geometries, this.geometry);
      const parameters = this.geometry.parameters;
      if (parameters !== undefined && parameters.shapes !== undefined) {
        const shapes = parameters.shapes;
        if (Array.isArray(shapes)) {
          for (let i = 0, l = shapes.length; i < l; i++) {
            const shape = shapes[i];
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
      if (this.skeleton !== undefined) {
        serialize(meta.skeletons, this.skeleton);
        object.skeleton = this.skeleton.uuid;
      }
    }
    if (this.material !== undefined) {
      if (Array.isArray(this.material)) {
        const uuids = [];
        for (let i = 0, l = this.material.length; i < l; i++) {
          uuids.push(serialize(meta.materials, this.material[i]));
        }
        object.material = uuids;
      } else {
        object.material = serialize(meta.materials, this.material);
      }
    }

    //

    if (this.children.length > 0) {
      object.children = [];
      for (let i = 0; i < this.children.length; i++) {
        object.children.push(this.children[i].toJSON(meta).object);
      }
    }

    //

    if (this.animations.length > 0) {
      object.animations = [];
      for (let i = 0; i < this.animations.length; i++) {
        const animation = this.animations[i];
        object.animations.push(serialize(meta.animations, animation));
      }
    }
    if (isRootObject) {
      const geometries = extractFromCache(meta.geometries);
      const materials = extractFromCache(meta.materials);
      const textures = extractFromCache(meta.textures);
      const images = extractFromCache(meta.images);
      const shapes = extractFromCache(meta.shapes);
      const skeletons = extractFromCache(meta.skeletons);
      const animations = extractFromCache(meta.animations);
      const nodes = extractFromCache(meta.nodes);
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

    // extract data from the cache hash
    // remove metadata on each item
    // and return as array
    function extractFromCache(cache) {
      const values = [];
      for (const key in cache) {
        const data = cache[key];
        delete data.metadata;
        values.push(data);
      }
      return values;
    }
  }
  clone(recursive) {
    return new this.constructor().copy(this, recursive);
  }
  copy(source, recursive = true) {
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
    this.animations = source.animations.slice();
    this.userData = JSON.parse(JSON.stringify(source.userData));
    if (recursive === true) {
      for (let i = 0; i < source.children.length; i++) {
        const child = source.children[i];
        this.add(child.clone());
      }
    }
    return this;
  }
}
Object3D.DEFAULT_UP = /*@__PURE__*/new Vector3(0, 1, 0);
Object3D.DEFAULT_MATRIX_AUTO_UPDATE = true;
Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true;
export { Object3D };
import { Quaternion } from '../math/Quaternion.js';
Quaternion
Quaternion
Quaternion
'../math/Quaternion.js'
import { Vector3 } from '../math/Vector3.js';
Vector3
Vector3
Vector3
'../math/Vector3.js'
import { Matrix4 } from '../math/Matrix4.js';
Matrix4
Matrix4
Matrix4
'../math/Matrix4.js'
import { EventDispatcher } from './EventDispatcher.js';
EventDispatcher
EventDispatcher
EventDispatcher
'./EventDispatcher.js'
import { Euler } from '../math/Euler.js';
Euler
Euler
Euler
'../math/Euler.js'
import { Layers } from './Layers.js';
Layers
Layers
Layers
'./Layers.js'
import { Matrix3 } from '../math/Matrix3.js';
Matrix3
Matrix3
Matrix3
'../math/Matrix3.js'
import * as MathUtils from '../math/MathUtils.js';
* as MathUtils
MathUtils
'../math/MathUtils.js'
let _object3DId = 0;
_object3DId = 0
_object3DId
0
const _v1 = /*@__PURE__*/new Vector3();
_v1 = /*@__PURE__*/new Vector3()
_v1
/*@__PURE__*/new Vector3()
Vector3
const _q1 = /*@__PURE__*/new Quaternion();
_q1 = /*@__PURE__*/new Quaternion()
_q1
/*@__PURE__*/new Quaternion()
Quaternion
const _m1 = /*@__PURE__*/new Matrix4();
_m1 = /*@__PURE__*/new Matrix4()
_m1
/*@__PURE__*/new Matrix4()
Matrix4
const _target = /*@__PURE__*/new Vector3();
_target = /*@__PURE__*/new Vector3()
_target
/*@__PURE__*/new Vector3()
Vector3
const _position = /*@__PURE__*/new Vector3();
_position = /*@__PURE__*/new Vector3()
_position
/*@__PURE__*/new Vector3()
Vector3
const _scale = /*@__PURE__*/new Vector3();
_scale = /*@__PURE__*/new Vector3()
_scale
/*@__PURE__*/new Vector3()
Vector3
const _quaternion = /*@__PURE__*/new Quaternion();
_quaternion = /*@__PURE__*/new Quaternion()
_quaternion
/*@__PURE__*/new Quaternion()
Quaternion
const _xAxis = /*@__PURE__*/new Vector3(1, 0, 0);
_xAxis = /*@__PURE__*/new Vector3(1, 0, 0)
_xAxis
/*@__PURE__*/new Vector3(1, 0, 0)
Vector3
1
0
0
const _yAxis = /*@__PURE__*/new Vector3(0, 1, 0);
_yAxis = /*@__PURE__*/new Vector3(0, 1, 0)
_yAxis
/*@__PURE__*/new Vector3(0, 1, 0)
Vector3
0
1
0
const _zAxis = /*@__PURE__*/new Vector3(0, 0, 1);
_zAxis = /*@__PURE__*/new Vector3(0, 0, 1)
_zAxis
/*@__PURE__*/new Vector3(0, 0, 1)
Vector3
0
0
1
const _addedEvent = {
  type: 'added'
};
_addedEvent = {
  type: 'added'
}
_addedEvent
{
  type: 'added'
}
type: 'added'
type
'added'
const _removedEvent = {
  type: 'removed'
};
_removedEvent = {
  type: 'removed'
}
_removedEvent
{
  type: 'removed'
}
type: 'removed'
type
'removed'
const _childaddedEvent = {
  type: 'childadded',
  child: null
};
_childaddedEvent = {
  type: 'childadded',
  child: null
}
_childaddedEvent
{
  type: 'childadded',
  child: null
}
type: 'childadded'
type
'childadded'
child: null
child
null
const _childremovedEvent = {
  type: 'childremoved',
  child: null
};
_childremovedEvent = {
  type: 'childremoved',
  child: null
}
_childremovedEvent
{
  type: 'childremoved',
  child: null
}
type: 'childremoved'
type
'childremoved'
child: null
child
null
class Object3D extends EventDispatcher {
  constructor() {
    super();
    this.isObject3D = true;
    Object.defineProperty(this, 'id', {
      value: _object3DId++
    });
    this.uuid = MathUtils.generateUUID();
    this.name = '';
    this.type = 'Object3D';
    this.parent = null;
    this.children = [];
    this.up = Object3D.DEFAULT_UP.clone();
    const position = new Vector3();
    const rotation = new Euler();
    const quaternion = new Quaternion();
    const scale = new Vector3(1, 1, 1);
    function onRotationChange() {
      quaternion.setFromEuler(rotation, false);
    }
    function onQuaternionChange() {
      rotation.setFromQuaternion(quaternion, undefined, false);
    }
    rotation._onChange(onRotationChange);
    quaternion._onChange(onQuaternionChange);
    Object.defineProperties(this, {
      position: {
        configurable: true,
        enumerable: true,
        value: position
      },
      rotation: {
        configurable: true,
        enumerable: true,
        value: rotation
      },
      quaternion: {
        configurable: true,
        enumerable: true,
        value: quaternion
      },
      scale: {
        configurable: true,
        enumerable: true,
        value: scale
      },
      modelViewMatrix: {
        value: new Matrix4()
      },
      normalMatrix: {
        value: new Matrix3()
      }
    });
    this.matrix = new Matrix4();
    this.matrixWorld = new Matrix4();
    this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
    this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // checked by the renderer
    this.matrixWorldNeedsUpdate = false;
    this.layers = new Layers();
    this.visible = true;
    this.castShadow = false;
    this.receiveShadow = false;
    this.frustumCulled = true;
    this.renderOrder = 0;
    this.animations = [];
    this.userData = {};
  }
  onBeforeShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
  onAfterShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
  onBeforeRender( /* renderer, scene, camera, geometry, material, group */) {}
  onAfterRender( /* renderer, scene, camera, geometry, material, group */) {}
  applyMatrix4(matrix) {
    if (this.matrixAutoUpdate) this.updateMatrix();
    this.matrix.premultiply(matrix);
    this.matrix.decompose(this.position, this.quaternion, this.scale);
  }
  applyQuaternion(q) {
    this.quaternion.premultiply(q);
    return this;
  }
  setRotationFromAxisAngle(axis, angle) {
    // assumes axis is normalized

    this.quaternion.setFromAxisAngle(axis, angle);
  }
  setRotationFromEuler(euler) {
    this.quaternion.setFromEuler(euler, true);
  }
  setRotationFromMatrix(m) {
    // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

    this.quaternion.setFromRotationMatrix(m);
  }
  setRotationFromQuaternion(q) {
    // assumes q is normalized

    this.quaternion.copy(q);
  }
  rotateOnAxis(axis, angle) {
    // rotate object on axis in object space
    // axis is assumed to be normalized

    _q1.setFromAxisAngle(axis, angle);
    this.quaternion.multiply(_q1);
    return this;
  }
  rotateOnWorldAxis(axis, angle) {
    // rotate object on axis in world space
    // axis is assumed to be normalized
    // method assumes no rotated parent

    _q1.setFromAxisAngle(axis, angle);
    this.quaternion.premultiply(_q1);
    return this;
  }
  rotateX(angle) {
    return this.rotateOnAxis(_xAxis, angle);
  }
  rotateY(angle) {
    return this.rotateOnAxis(_yAxis, angle);
  }
  rotateZ(angle) {
    return this.rotateOnAxis(_zAxis, angle);
  }
  translateOnAxis(axis, distance) {
    // translate object by distance along axis in object space
    // axis is assumed to be normalized

    _v1.copy(axis).applyQuaternion(this.quaternion);
    this.position.add(_v1.multiplyScalar(distance));
    return this;
  }
  translateX(distance) {
    return this.translateOnAxis(_xAxis, distance);
  }
  translateY(distance) {
    return this.translateOnAxis(_yAxis, distance);
  }
  translateZ(distance) {
    return this.translateOnAxis(_zAxis, distance);
  }
  localToWorld(vector) {
    this.updateWorldMatrix(true, false);
    return vector.applyMatrix4(this.matrixWorld);
  }
  worldToLocal(vector) {
    this.updateWorldMatrix(true, false);
    return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
  }
  lookAt(x, y, z) {
    // This method does not support objects having non-uniformly-scaled parent(s)

    if (x.isVector3) {
      _target.copy(x);
    } else {
      _target.set(x, y, z);
    }
    const parent = this.parent;
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
  add(object) {
    if (arguments.length > 1) {
      for (let i = 0; i < arguments.length; i++) {
        this.add(arguments[i]);
      }
      return this;
    }
    if (object === this) {
      console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
      return this;
    }
    if (object && object.isObject3D) {
      object.removeFromParent();
      object.parent = this;
      this.children.push(object);
      object.dispatchEvent(_addedEvent);
      _childaddedEvent.child = object;
      this.dispatchEvent(_childaddedEvent);
      _childaddedEvent.child = null;
    } else {
      console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
    }
    return this;
  }
  remove(object) {
    if (arguments.length > 1) {
      for (let i = 0; i < arguments.length; i++) {
        this.remove(arguments[i]);
      }
      return this;
    }
    const index = this.children.indexOf(object);
    if (index !== -1) {
      object.parent = null;
      this.children.splice(index, 1);
      object.dispatchEvent(_removedEvent);
      _childremovedEvent.child = object;
      this.dispatchEvent(_childremovedEvent);
      _childremovedEvent.child = null;
    }
    return this;
  }
  removeFromParent() {
    const parent = this.parent;
    if (parent !== null) {
      parent.remove(this);
    }
    return this;
  }
  clear() {
    return this.remove(...this.children);
  }
  attach(object) {
    // adds object as a child of this, while maintaining the object's world transform

    // Note: This method does not support scene graphs having non-uniformly-scaled nodes(s)

    this.updateWorldMatrix(true, false);
    _m1.copy(this.matrixWorld).invert();
    if (object.parent !== null) {
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
  getObjectById(id) {
    return this.getObjectByProperty('id', id);
  }
  getObjectByName(name) {
    return this.getObjectByProperty('name', name);
  }
  getObjectByProperty(name, value) {
    if (this[name] === value) return this;
    for (let i = 0, l = this.children.length; i < l; i++) {
      const child = this.children[i];
      const object = child.getObjectByProperty(name, value);
      if (object !== undefined) {
        return object;
      }
    }
    return undefined;
  }
  getObjectsByProperty(name, value, result = []) {
    if (this[name] === value) result.push(this);
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      children[i].getObjectsByProperty(name, value, result);
    }
    return result;
  }
  getWorldPosition(target) {
    this.updateWorldMatrix(true, false);
    return target.setFromMatrixPosition(this.matrixWorld);
  }
  getWorldQuaternion(target) {
    this.updateWorldMatrix(true, false);
    this.matrixWorld.decompose(_position, target, _scale);
    return target;
  }
  getWorldScale(target) {
    this.updateWorldMatrix(true, false);
    this.matrixWorld.decompose(_position, _quaternion, target);
    return target;
  }
  getWorldDirection(target) {
    this.updateWorldMatrix(true, false);
    const e = this.matrixWorld.elements;
    return target.set(e[8], e[9], e[10]).normalize();
  }
  raycast( /* raycaster, intersects */) {}
  traverse(callback) {
    callback(this);
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      children[i].traverse(callback);
    }
  }
  traverseVisible(callback) {
    if (this.visible === false) return;
    callback(this);
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      children[i].traverseVisible(callback);
    }
  }
  traverseAncestors(callback) {
    const parent = this.parent;
    if (parent !== null) {
      callback(parent);
      parent.traverseAncestors(callback);
    }
  }
  updateMatrix() {
    this.matrix.compose(this.position, this.quaternion, this.scale);
    this.matrixWorldNeedsUpdate = true;
  }
  updateMatrixWorld(force) {
    if (this.matrixAutoUpdate) this.updateMatrix();
    if (this.matrixWorldNeedsUpdate || force) {
      if (this.parent === null) {
        this.matrixWorld.copy(this.matrix);
      } else {
        this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
      }
      this.matrixWorldNeedsUpdate = false;
      force = true;
    }

    // update children

    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      const child = children[i];
      if (child.matrixWorldAutoUpdate === true || force === true) {
        child.updateMatrixWorld(force);
      }
    }
  }
  updateWorldMatrix(updateParents, updateChildren) {
    const parent = this.parent;
    if (updateParents === true && parent !== null && parent.matrixWorldAutoUpdate === true) {
      parent.updateWorldMatrix(true, false);
    }
    if (this.matrixAutoUpdate) this.updateMatrix();
    if (this.parent === null) {
      this.matrixWorld.copy(this.matrix);
    } else {
      this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
    }

    // update children

    if (updateChildren === true) {
      const children = this.children;
      for (let i = 0, l = children.length; i < l; i++) {
        const child = children[i];
        if (child.matrixWorldAutoUpdate === true) {
          child.updateWorldMatrix(false, true);
        }
      }
    }
  }
  toJSON(meta) {
    // meta is a string when called from JSON.stringify
    const isRootObject = meta === undefined || typeof meta === 'string';
    const output = {};

    // meta is a hash used to collect geometries, materials.
    // not providing it implies that this is the root object
    // being serialized.
    if (isRootObject) {
      // initialize meta obj
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

    // standard Object3D serialization

    const object = {};
    object.uuid = this.uuid;
    object.type = this.type;
    if (this.name !== '') object.name = this.name;
    if (this.castShadow === true) object.castShadow = true;
    if (this.receiveShadow === true) object.receiveShadow = true;
    if (this.visible === false) object.visible = false;
    if (this.frustumCulled === false) object.frustumCulled = false;
    if (this.renderOrder !== 0) object.renderOrder = this.renderOrder;
    if (Object.keys(this.userData).length > 0) object.userData = this.userData;
    object.layers = this.layers.mask;
    object.matrix = this.matrix.toArray();
    object.up = this.up.toArray();
    if (this.matrixAutoUpdate === false) object.matrixAutoUpdate = false;

    // object specific properties

    if (this.isInstancedMesh) {
      object.type = 'InstancedMesh';
      object.count = this.count;
      object.instanceMatrix = this.instanceMatrix.toJSON();
      if (this.instanceColor !== null) object.instanceColor = this.instanceColor.toJSON();
    }
    if (this.isBatchedMesh) {
      object.type = 'BatchedMesh';
      object.perObjectFrustumCulled = this.perObjectFrustumCulled;
      object.sortObjects = this.sortObjects;
      object.drawRanges = this._drawRanges;
      object.reservedRanges = this._reservedRanges;
      object.visibility = this._visibility;
      object.active = this._active;
      object.bounds = this._bounds.map(bound => ({
        boxInitialized: bound.boxInitialized,
        boxMin: bound.box.min.toArray(),
        boxMax: bound.box.max.toArray(),
        sphereInitialized: bound.sphereInitialized,
        sphereRadius: bound.sphere.radius,
        sphereCenter: bound.sphere.center.toArray()
      }));
      object.maxGeometryCount = this._maxGeometryCount;
      object.maxVertexCount = this._maxVertexCount;
      object.maxIndexCount = this._maxIndexCount;
      object.geometryInitialized = this._geometryInitialized;
      object.geometryCount = this._geometryCount;
      object.matricesTexture = this._matricesTexture.toJSON(meta);
      if (this._colorsTexture !== null) object.colorsTexture = this._colorsTexture.toJSON(meta);
      if (this.boundingSphere !== null) {
        object.boundingSphere = {
          center: object.boundingSphere.center.toArray(),
          radius: object.boundingSphere.radius
        };
      }
      if (this.boundingBox !== null) {
        object.boundingBox = {
          min: object.boundingBox.min.toArray(),
          max: object.boundingBox.max.toArray()
        };
      }
    }

    //

    function serialize(library, element) {
      if (library[element.uuid] === undefined) {
        library[element.uuid] = element.toJSON(meta);
      }
      return element.uuid;
    }
    if (this.isScene) {
      if (this.background) {
        if (this.background.isColor) {
          object.background = this.background.toJSON();
        } else if (this.background.isTexture) {
          object.background = this.background.toJSON(meta).uuid;
        }
      }
      if (this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== true) {
        object.environment = this.environment.toJSON(meta).uuid;
      }
    } else if (this.isMesh || this.isLine || this.isPoints) {
      object.geometry = serialize(meta.geometries, this.geometry);
      const parameters = this.geometry.parameters;
      if (parameters !== undefined && parameters.shapes !== undefined) {
        const shapes = parameters.shapes;
        if (Array.isArray(shapes)) {
          for (let i = 0, l = shapes.length; i < l; i++) {
            const shape = shapes[i];
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
      if (this.skeleton !== undefined) {
        serialize(meta.skeletons, this.skeleton);
        object.skeleton = this.skeleton.uuid;
      }
    }
    if (this.material !== undefined) {
      if (Array.isArray(this.material)) {
        const uuids = [];
        for (let i = 0, l = this.material.length; i < l; i++) {
          uuids.push(serialize(meta.materials, this.material[i]));
        }
        object.material = uuids;
      } else {
        object.material = serialize(meta.materials, this.material);
      }
    }

    //

    if (this.children.length > 0) {
      object.children = [];
      for (let i = 0; i < this.children.length; i++) {
        object.children.push(this.children[i].toJSON(meta).object);
      }
    }

    //

    if (this.animations.length > 0) {
      object.animations = [];
      for (let i = 0; i < this.animations.length; i++) {
        const animation = this.animations[i];
        object.animations.push(serialize(meta.animations, animation));
      }
    }
    if (isRootObject) {
      const geometries = extractFromCache(meta.geometries);
      const materials = extractFromCache(meta.materials);
      const textures = extractFromCache(meta.textures);
      const images = extractFromCache(meta.images);
      const shapes = extractFromCache(meta.shapes);
      const skeletons = extractFromCache(meta.skeletons);
      const animations = extractFromCache(meta.animations);
      const nodes = extractFromCache(meta.nodes);
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

    // extract data from the cache hash
    // remove metadata on each item
    // and return as array
    function extractFromCache(cache) {
      const values = [];
      for (const key in cache) {
        const data = cache[key];
        delete data.metadata;
        values.push(data);
      }
      return values;
    }
  }
  clone(recursive) {
    return new this.constructor().copy(this, recursive);
  }
  copy(source, recursive = true) {
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
    this.animations = source.animations.slice();
    this.userData = JSON.parse(JSON.stringify(source.userData));
    if (recursive === true) {
      for (let i = 0; i < source.children.length; i++) {
        const child = source.children[i];
        this.add(child.clone());
      }
    }
    return this;
  }
}
Object3D
{
  constructor() {
    super();
    this.isObject3D = true;
    Object.defineProperty(this, 'id', {
      value: _object3DId++
    });
    this.uuid = MathUtils.generateUUID();
    this.name = '';
    this.type = 'Object3D';
    this.parent = null;
    this.children = [];
    this.up = Object3D.DEFAULT_UP.clone();
    const position = new Vector3();
    const rotation = new Euler();
    const quaternion = new Quaternion();
    const scale = new Vector3(1, 1, 1);
    function onRotationChange() {
      quaternion.setFromEuler(rotation, false);
    }
    function onQuaternionChange() {
      rotation.setFromQuaternion(quaternion, undefined, false);
    }
    rotation._onChange(onRotationChange);
    quaternion._onChange(onQuaternionChange);
    Object.defineProperties(this, {
      position: {
        configurable: true,
        enumerable: true,
        value: position
      },
      rotation: {
        configurable: true,
        enumerable: true,
        value: rotation
      },
      quaternion: {
        configurable: true,
        enumerable: true,
        value: quaternion
      },
      scale: {
        configurable: true,
        enumerable: true,
        value: scale
      },
      modelViewMatrix: {
        value: new Matrix4()
      },
      normalMatrix: {
        value: new Matrix3()
      }
    });
    this.matrix = new Matrix4();
    this.matrixWorld = new Matrix4();
    this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
    this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // checked by the renderer
    this.matrixWorldNeedsUpdate = false;
    this.layers = new Layers();
    this.visible = true;
    this.castShadow = false;
    this.receiveShadow = false;
    this.frustumCulled = true;
    this.renderOrder = 0;
    this.animations = [];
    this.userData = {};
  }
  onBeforeShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
  onAfterShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
  onBeforeRender( /* renderer, scene, camera, geometry, material, group */) {}
  onAfterRender( /* renderer, scene, camera, geometry, material, group */) {}
  applyMatrix4(matrix) {
    if (this.matrixAutoUpdate) this.updateMatrix();
    this.matrix.premultiply(matrix);
    this.matrix.decompose(this.position, this.quaternion, this.scale);
  }
  applyQuaternion(q) {
    this.quaternion.premultiply(q);
    return this;
  }
  setRotationFromAxisAngle(axis, angle) {
    // assumes axis is normalized

    this.quaternion.setFromAxisAngle(axis, angle);
  }
  setRotationFromEuler(euler) {
    this.quaternion.setFromEuler(euler, true);
  }
  setRotationFromMatrix(m) {
    // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

    this.quaternion.setFromRotationMatrix(m);
  }
  setRotationFromQuaternion(q) {
    // assumes q is normalized

    this.quaternion.copy(q);
  }
  rotateOnAxis(axis, angle) {
    // rotate object on axis in object space
    // axis is assumed to be normalized

    _q1.setFromAxisAngle(axis, angle);
    this.quaternion.multiply(_q1);
    return this;
  }
  rotateOnWorldAxis(axis, angle) {
    // rotate object on axis in world space
    // axis is assumed to be normalized
    // method assumes no rotated parent

    _q1.setFromAxisAngle(axis, angle);
    this.quaternion.premultiply(_q1);
    return this;
  }
  rotateX(angle) {
    return this.rotateOnAxis(_xAxis, angle);
  }
  rotateY(angle) {
    return this.rotateOnAxis(_yAxis, angle);
  }
  rotateZ(angle) {
    return this.rotateOnAxis(_zAxis, angle);
  }
  translateOnAxis(axis, distance) {
    // translate object by distance along axis in object space
    // axis is assumed to be normalized

    _v1.copy(axis).applyQuaternion(this.quaternion);
    this.position.add(_v1.multiplyScalar(distance));
    return this;
  }
  translateX(distance) {
    return this.translateOnAxis(_xAxis, distance);
  }
  translateY(distance) {
    return this.translateOnAxis(_yAxis, distance);
  }
  translateZ(distance) {
    return this.translateOnAxis(_zAxis, distance);
  }
  localToWorld(vector) {
    this.updateWorldMatrix(true, false);
    return vector.applyMatrix4(this.matrixWorld);
  }
  worldToLocal(vector) {
    this.updateWorldMatrix(true, false);
    return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
  }
  lookAt(x, y, z) {
    // This method does not support objects having non-uniformly-scaled parent(s)

    if (x.isVector3) {
      _target.copy(x);
    } else {
      _target.set(x, y, z);
    }
    const parent = this.parent;
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
  add(object) {
    if (arguments.length > 1) {
      for (let i = 0; i < arguments.length; i++) {
        this.add(arguments[i]);
      }
      return this;
    }
    if (object === this) {
      console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
      return this;
    }
    if (object && object.isObject3D) {
      object.removeFromParent();
      object.parent = this;
      this.children.push(object);
      object.dispatchEvent(_addedEvent);
      _childaddedEvent.child = object;
      this.dispatchEvent(_childaddedEvent);
      _childaddedEvent.child = null;
    } else {
      console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
    }
    return this;
  }
  remove(object) {
    if (arguments.length > 1) {
      for (let i = 0; i < arguments.length; i++) {
        this.remove(arguments[i]);
      }
      return this;
    }
    const index = this.children.indexOf(object);
    if (index !== -1) {
      object.parent = null;
      this.children.splice(index, 1);
      object.dispatchEvent(_removedEvent);
      _childremovedEvent.child = object;
      this.dispatchEvent(_childremovedEvent);
      _childremovedEvent.child = null;
    }
    return this;
  }
  removeFromParent() {
    const parent = this.parent;
    if (parent !== null) {
      parent.remove(this);
    }
    return this;
  }
  clear() {
    return this.remove(...this.children);
  }
  attach(object) {
    // adds object as a child of this, while maintaining the object's world transform

    // Note: This method does not support scene graphs having non-uniformly-scaled nodes(s)

    this.updateWorldMatrix(true, false);
    _m1.copy(this.matrixWorld).invert();
    if (object.parent !== null) {
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
  getObjectById(id) {
    return this.getObjectByProperty('id', id);
  }
  getObjectByName(name) {
    return this.getObjectByProperty('name', name);
  }
  getObjectByProperty(name, value) {
    if (this[name] === value) return this;
    for (let i = 0, l = this.children.length; i < l; i++) {
      const child = this.children[i];
      const object = child.getObjectByProperty(name, value);
      if (object !== undefined) {
        return object;
      }
    }
    return undefined;
  }
  getObjectsByProperty(name, value, result = []) {
    if (this[name] === value) result.push(this);
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      children[i].getObjectsByProperty(name, value, result);
    }
    return result;
  }
  getWorldPosition(target) {
    this.updateWorldMatrix(true, false);
    return target.setFromMatrixPosition(this.matrixWorld);
  }
  getWorldQuaternion(target) {
    this.updateWorldMatrix(true, false);
    this.matrixWorld.decompose(_position, target, _scale);
    return target;
  }
  getWorldScale(target) {
    this.updateWorldMatrix(true, false);
    this.matrixWorld.decompose(_position, _quaternion, target);
    return target;
  }
  getWorldDirection(target) {
    this.updateWorldMatrix(true, false);
    const e = this.matrixWorld.elements;
    return target.set(e[8], e[9], e[10]).normalize();
  }
  raycast( /* raycaster, intersects */) {}
  traverse(callback) {
    callback(this);
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      children[i].traverse(callback);
    }
  }
  traverseVisible(callback) {
    if (this.visible === false) return;
    callback(this);
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      children[i].traverseVisible(callback);
    }
  }
  traverseAncestors(callback) {
    const parent = this.parent;
    if (parent !== null) {
      callback(parent);
      parent.traverseAncestors(callback);
    }
  }
  updateMatrix() {
    this.matrix.compose(this.position, this.quaternion, this.scale);
    this.matrixWorldNeedsUpdate = true;
  }
  updateMatrixWorld(force) {
    if (this.matrixAutoUpdate) this.updateMatrix();
    if (this.matrixWorldNeedsUpdate || force) {
      if (this.parent === null) {
        this.matrixWorld.copy(this.matrix);
      } else {
        this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
      }
      this.matrixWorldNeedsUpdate = false;
      force = true;
    }

    // update children

    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      const child = children[i];
      if (child.matrixWorldAutoUpdate === true || force === true) {
        child.updateMatrixWorld(force);
      }
    }
  }
  updateWorldMatrix(updateParents, updateChildren) {
    const parent = this.parent;
    if (updateParents === true && parent !== null && parent.matrixWorldAutoUpdate === true) {
      parent.updateWorldMatrix(true, false);
    }
    if (this.matrixAutoUpdate) this.updateMatrix();
    if (this.parent === null) {
      this.matrixWorld.copy(this.matrix);
    } else {
      this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
    }

    // update children

    if (updateChildren === true) {
      const children = this.children;
      for (let i = 0, l = children.length; i < l; i++) {
        const child = children[i];
        if (child.matrixWorldAutoUpdate === true) {
          child.updateWorldMatrix(false, true);
        }
      }
    }
  }
  toJSON(meta) {
    // meta is a string when called from JSON.stringify
    const isRootObject = meta === undefined || typeof meta === 'string';
    const output = {};

    // meta is a hash used to collect geometries, materials.
    // not providing it implies that this is the root object
    // being serialized.
    if (isRootObject) {
      // initialize meta obj
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

    // standard Object3D serialization

    const object = {};
    object.uuid = this.uuid;
    object.type = this.type;
    if (this.name !== '') object.name = this.name;
    if (this.castShadow === true) object.castShadow = true;
    if (this.receiveShadow === true) object.receiveShadow = true;
    if (this.visible === false) object.visible = false;
    if (this.frustumCulled === false) object.frustumCulled = false;
    if (this.renderOrder !== 0) object.renderOrder = this.renderOrder;
    if (Object.keys(this.userData).length > 0) object.userData = this.userData;
    object.layers = this.layers.mask;
    object.matrix = this.matrix.toArray();
    object.up = this.up.toArray();
    if (this.matrixAutoUpdate === false) object.matrixAutoUpdate = false;

    // object specific properties

    if (this.isInstancedMesh) {
      object.type = 'InstancedMesh';
      object.count = this.count;
      object.instanceMatrix = this.instanceMatrix.toJSON();
      if (this.instanceColor !== null) object.instanceColor = this.instanceColor.toJSON();
    }
    if (this.isBatchedMesh) {
      object.type = 'BatchedMesh';
      object.perObjectFrustumCulled = this.perObjectFrustumCulled;
      object.sortObjects = this.sortObjects;
      object.drawRanges = this._drawRanges;
      object.reservedRanges = this._reservedRanges;
      object.visibility = this._visibility;
      object.active = this._active;
      object.bounds = this._bounds.map(bound => ({
        boxInitialized: bound.boxInitialized,
        boxMin: bound.box.min.toArray(),
        boxMax: bound.box.max.toArray(),
        sphereInitialized: bound.sphereInitialized,
        sphereRadius: bound.sphere.radius,
        sphereCenter: bound.sphere.center.toArray()
      }));
      object.maxGeometryCount = this._maxGeometryCount;
      object.maxVertexCount = this._maxVertexCount;
      object.maxIndexCount = this._maxIndexCount;
      object.geometryInitialized = this._geometryInitialized;
      object.geometryCount = this._geometryCount;
      object.matricesTexture = this._matricesTexture.toJSON(meta);
      if (this._colorsTexture !== null) object.colorsTexture = this._colorsTexture.toJSON(meta);
      if (this.boundingSphere !== null) {
        object.boundingSphere = {
          center: object.boundingSphere.center.toArray(),
          radius: object.boundingSphere.radius
        };
      }
      if (this.boundingBox !== null) {
        object.boundingBox = {
          min: object.boundingBox.min.toArray(),
          max: object.boundingBox.max.toArray()
        };
      }
    }

    //

    function serialize(library, element) {
      if (library[element.uuid] === undefined) {
        library[element.uuid] = element.toJSON(meta);
      }
      return element.uuid;
    }
    if (this.isScene) {
      if (this.background) {
        if (this.background.isColor) {
          object.background = this.background.toJSON();
        } else if (this.background.isTexture) {
          object.background = this.background.toJSON(meta).uuid;
        }
      }
      if (this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== true) {
        object.environment = this.environment.toJSON(meta).uuid;
      }
    } else if (this.isMesh || this.isLine || this.isPoints) {
      object.geometry = serialize(meta.geometries, this.geometry);
      const parameters = this.geometry.parameters;
      if (parameters !== undefined && parameters.shapes !== undefined) {
        const shapes = parameters.shapes;
        if (Array.isArray(shapes)) {
          for (let i = 0, l = shapes.length; i < l; i++) {
            const shape = shapes[i];
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
      if (this.skeleton !== undefined) {
        serialize(meta.skeletons, this.skeleton);
        object.skeleton = this.skeleton.uuid;
      }
    }
    if (this.material !== undefined) {
      if (Array.isArray(this.material)) {
        const uuids = [];
        for (let i = 0, l = this.material.length; i < l; i++) {
          uuids.push(serialize(meta.materials, this.material[i]));
        }
        object.material = uuids;
      } else {
        object.material = serialize(meta.materials, this.material);
      }
    }

    //

    if (this.children.length > 0) {
      object.children = [];
      for (let i = 0; i < this.children.length; i++) {
        object.children.push(this.children[i].toJSON(meta).object);
      }
    }

    //

    if (this.animations.length > 0) {
      object.animations = [];
      for (let i = 0; i < this.animations.length; i++) {
        const animation = this.animations[i];
        object.animations.push(serialize(meta.animations, animation));
      }
    }
    if (isRootObject) {
      const geometries = extractFromCache(meta.geometries);
      const materials = extractFromCache(meta.materials);
      const textures = extractFromCache(meta.textures);
      const images = extractFromCache(meta.images);
      const shapes = extractFromCache(meta.shapes);
      const skeletons = extractFromCache(meta.skeletons);
      const animations = extractFromCache(meta.animations);
      const nodes = extractFromCache(meta.nodes);
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

    // extract data from the cache hash
    // remove metadata on each item
    // and return as array
    function extractFromCache(cache) {
      const values = [];
      for (const key in cache) {
        const data = cache[key];
        delete data.metadata;
        values.push(data);
      }
      return values;
    }
  }
  clone(recursive) {
    return new this.constructor().copy(this, recursive);
  }
  copy(source, recursive = true) {
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
    this.animations = source.animations.slice();
    this.userData = JSON.parse(JSON.stringify(source.userData));
    if (recursive === true) {
      for (let i = 0; i < source.children.length; i++) {
        const child = source.children[i];
        this.add(child.clone());
      }
    }
    return this;
  }
}
constructor() {
  super();
  this.isObject3D = true;
  Object.defineProperty(this, 'id', {
    value: _object3DId++
  });
  this.uuid = MathUtils.generateUUID();
  this.name = '';
  this.type = 'Object3D';
  this.parent = null;
  this.children = [];
  this.up = Object3D.DEFAULT_UP.clone();
  const position = new Vector3();
  const rotation = new Euler();
  const quaternion = new Quaternion();
  const scale = new Vector3(1, 1, 1);
  function onRotationChange() {
    quaternion.setFromEuler(rotation, false);
  }
  function onQuaternionChange() {
    rotation.setFromQuaternion(quaternion, undefined, false);
  }
  rotation._onChange(onRotationChange);
  quaternion._onChange(onQuaternionChange);
  Object.defineProperties(this, {
    position: {
      configurable: true,
      enumerable: true,
      value: position
    },
    rotation: {
      configurable: true,
      enumerable: true,
      value: rotation
    },
    quaternion: {
      configurable: true,
      enumerable: true,
      value: quaternion
    },
    scale: {
      configurable: true,
      enumerable: true,
      value: scale
    },
    modelViewMatrix: {
      value: new Matrix4()
    },
    normalMatrix: {
      value: new Matrix3()
    }
  });
  this.matrix = new Matrix4();
  this.matrixWorld = new Matrix4();
  this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
  this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // checked by the renderer
  this.matrixWorldNeedsUpdate = false;
  this.layers = new Layers();
  this.visible = true;
  this.castShadow = false;
  this.receiveShadow = false;
  this.frustumCulled = true;
  this.renderOrder = 0;
  this.animations = [];
  this.userData = {};
}
constructor() {
  super();
  this.isObject3D = true;
  Object.defineProperty(this, 'id', {
    value: _object3DId++
  });
  this.uuid = MathUtils.generateUUID();
  this.name = '';
  this.type = 'Object3D';
  this.parent = null;
  this.children = [];
  this.up = Object3D.DEFAULT_UP.clone();
  const position = new Vector3();
  const rotation = new Euler();
  const quaternion = new Quaternion();
  const scale = new Vector3(1, 1, 1);
  function onRotationChange() {
    quaternion.setFromEuler(rotation, false);
  }
  function onQuaternionChange() {
    rotation.setFromQuaternion(quaternion, undefined, false);
  }
  rotation._onChange(onRotationChange);
  quaternion._onChange(onQuaternionChange);
  Object.defineProperties(this, {
    position: {
      configurable: true,
      enumerable: true,
      value: position
    },
    rotation: {
      configurable: true,
      enumerable: true,
      value: rotation
    },
    quaternion: {
      configurable: true,
      enumerable: true,
      value: quaternion
    },
    scale: {
      configurable: true,
      enumerable: true,
      value: scale
    },
    modelViewMatrix: {
      value: new Matrix4()
    },
    normalMatrix: {
      value: new Matrix3()
    }
  });
  this.matrix = new Matrix4();
  this.matrixWorld = new Matrix4();
  this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
  this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // checked by the renderer
  this.matrixWorldNeedsUpdate = false;
  this.layers = new Layers();
  this.visible = true;
  this.castShadow = false;
  this.receiveShadow = false;
  this.frustumCulled = true;
  this.renderOrder = 0;
  this.animations = [];
  this.userData = {};
}
function onRotationChange() {
  quaternion.setFromEuler(rotation, false);
}
onRotationChange
{
  quaternion.setFromEuler(rotation, false);
}
quaternion.setFromEuler(rotation, false);
quaternion.setFromEuler(rotation, false)
quaternion.setFromEuler
quaternion
setFromEuler
rotation
false
function onQuaternionChange() {
  rotation.setFromQuaternion(quaternion, undefined, false);
}
function onQuaternionChange() {
  rotation.setFromQuaternion(quaternion, undefined, false);
}
onQuaternionChange
{
  rotation.setFromQuaternion(quaternion, undefined, false);
}
rotation.setFromQuaternion(quaternion, undefined, false);
rotation.setFromQuaternion(quaternion, undefined, false)
rotation.setFromQuaternion
rotation
setFromQuaternion
quaternion
undefined
false
rotation._onChange(onRotationChange);
rotation._onChange(onRotationChange)
rotation._onChange
rotation
_onChange
onRotationChange
quaternion._onChange(onQuaternionChange);
quaternion._onChange(onQuaternionChange)
quaternion._onChange
quaternion
_onChange
onQuaternionChange
Object.defineProperties(this, {
  position: {
    configurable: true,
    enumerable: true,
    value: position
  },
  rotation: {
    configurable: true,
    enumerable: true,
    value: rotation
  },
  quaternion: {
    configurable: true,
    enumerable: true,
    value: quaternion
  },
  scale: {
    configurable: true,
    enumerable: true,
    value: scale
  },
  modelViewMatrix: {
    value: new Matrix4()
  },
  normalMatrix: {
    value: new Matrix3()
  }
});
Object.defineProperties(this, {
  position: {
    configurable: true,
    enumerable: true,
    value: position
  },
  rotation: {
    configurable: true,
    enumerable: true,
    value: rotation
  },
  quaternion: {
    configurable: true,
    enumerable: true,
    value: quaternion
  },
  scale: {
    configurable: true,
    enumerable: true,
    value: scale
  },
  modelViewMatrix: {
    value: new Matrix4()
  },
  normalMatrix: {
    value: new Matrix3()
  }
})
Object.defineProperties
Object
defineProperties
this
{
  position: {
    configurable: true,
    enumerable: true,
    value: position
  },
  rotation: {
    configurable: true,
    enumerable: true,
    value: rotation
  },
  quaternion: {
    configurable: true,
    enumerable: true,
    value: quaternion
  },
  scale: {
    configurable: true,
    enumerable: true,
    value: scale
  },
  modelViewMatrix: {
    value: new Matrix4()
  },
  normalMatrix: {
    value: new Matrix3()
  }
}
position: {
  configurable: true,
  enumerable: true,
  value: position
}
position
{
  configurable: true,
  enumerable: true,
  value: position
}
configurable: true
configurable
true
enumerable: true
enumerable
true
value: position
value
position
rotation: {
  configurable: true,
  enumerable: true,
  value: rotation
}
rotation
{
  configurable: true,
  enumerable: true,
  value: rotation
}
configurable: true
configurable
true
enumerable: true
enumerable
true
value: rotation
value
rotation
quaternion: {
  configurable: true,
  enumerable: true,
  value: quaternion
}
quaternion
{
  configurable: true,
  enumerable: true,
  value: quaternion
}
configurable: true
configurable
true
enumerable: true
enumerable
true
value: quaternion
value
quaternion
scale: {
  configurable: true,
  enumerable: true,
  value: scale
}
scale
{
  configurable: true,
  enumerable: true,
  value: scale
}
configurable: true
configurable
true
enumerable: true
enumerable
true
value: scale
value
scale
modelViewMatrix: {
  value: new Matrix4()
}
modelViewMatrix
{
  value: new Matrix4()
}
value: new Matrix4()
value
new Matrix4()
Matrix4
normalMatrix: {
  value: new Matrix3()
}
normalMatrix
{
  value: new Matrix3()
}
value: new Matrix3()
value
new Matrix3()
Matrix3
this.matrix = new Matrix4();
this.matrix = new Matrix4()
this.matrix
this
matrix
new Matrix4()
Matrix4
this.matrixWorld = new Matrix4();
this.matrixWorld = new Matrix4()
this.matrixWorld
this
matrixWorld
new Matrix4()
Matrix4
this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE
this.matrixAutoUpdate
this
matrixAutoUpdate
Object3D.DEFAULT_MATRIX_AUTO_UPDATE
Object3D
DEFAULT_MATRIX_AUTO_UPDATE
this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // checked by the renderer
this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE
this.matrixWorldAutoUpdate
this
matrixWorldAutoUpdate
Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE
Object3D
DEFAULT_MATRIX_WORLD_AUTO_UPDATE
// checked by the renderer
this.matrixWorldNeedsUpdate = false;
this.matrixWorldNeedsUpdate = false
this.matrixWorldNeedsUpdate
this
matrixWorldNeedsUpdate
false
this.layers = new Layers();
this.layers = new Layers()
this.layers
this
layers
new Layers()
Layers
this.visible = true;
this.visible = true
this.visible
this
visible
true
this.castShadow = false;
this.castShadow = false
this.castShadow
this
castShadow
false
this.receiveShadow = false;
this.receiveShadow = false
this.receiveShadow
this
receiveShadow
false
this.frustumCulled = true;
this.frustumCulled = true
this.frustumCulled
this
frustumCulled
true
this.renderOrder = 0;
this.renderOrder = 0
this.renderOrder
this
renderOrder
0
this.animations = [];
this.animations = []
this.animations
this
animations
[]
this.userData = {};
this.userData = {}
this.userData
this
userData
{}
onBeforeShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
constructor
{
  super();
  this.isObject3D = true;
  Object.defineProperty(this, 'id', {
    value: _object3DId++
  });
  this.uuid = MathUtils.generateUUID();
  this.name = '';
  this.type = 'Object3D';
  this.parent = null;
  this.children = [];
  this.up = Object3D.DEFAULT_UP.clone();
  const position = new Vector3();
  const rotation = new Euler();
  const quaternion = new Quaternion();
  const scale = new Vector3(1, 1, 1);
  function onRotationChange() {
    quaternion.setFromEuler(rotation, false);
  }
  function onQuaternionChange() {
    rotation.setFromQuaternion(quaternion, undefined, false);
  }
  rotation._onChange(onRotationChange);
  quaternion._onChange(onQuaternionChange);
  Object.defineProperties(this, {
    position: {
      configurable: true,
      enumerable: true,
      value: position
    },
    rotation: {
      configurable: true,
      enumerable: true,
      value: rotation
    },
    quaternion: {
      configurable: true,
      enumerable: true,
      value: quaternion
    },
    scale: {
      configurable: true,
      enumerable: true,
      value: scale
    },
    modelViewMatrix: {
      value: new Matrix4()
    },
    normalMatrix: {
      value: new Matrix3()
    }
  });
  this.matrix = new Matrix4();
  this.matrixWorld = new Matrix4();
  this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
  this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // checked by the renderer
  this.matrixWorldNeedsUpdate = false;
  this.layers = new Layers();
  this.visible = true;
  this.castShadow = false;
  this.receiveShadow = false;
  this.frustumCulled = true;
  this.renderOrder = 0;
  this.animations = [];
  this.userData = {};
}
super();
super()
super
this.isObject3D = true;
this.isObject3D = true
this.isObject3D
this
isObject3D
true
Object.defineProperty(this, 'id', {
  value: _object3DId++
});
Object.defineProperty(this, 'id', {
  value: _object3DId++
})
Object.defineProperty
Object
defineProperty
this
'id'
{
  value: _object3DId++
}
value: _object3DId++
value
_object3DId++
_object3DId
this.uuid = MathUtils.generateUUID();
this.uuid = MathUtils.generateUUID()
this.uuid
this
uuid
MathUtils.generateUUID()
MathUtils.generateUUID
MathUtils
generateUUID
this.name = '';
this.name = ''
this.name
this
name
''
this.type = 'Object3D';
this.type = 'Object3D'
this.type
this
type
'Object3D'
this.parent = null;
this.parent = null
this.parent
this
parent
null
this.children = [];
this.children = []
this.children
this
children
[]
this.up = Object3D.DEFAULT_UP.clone();
this.up = Object3D.DEFAULT_UP.clone()
this.up
this
up
Object3D.DEFAULT_UP.clone()
Object3D.DEFAULT_UP.clone
Object3D.DEFAULT_UP
Object3D
DEFAULT_UP
clone
const position = new Vector3();
position = new Vector3()
position
new Vector3()
Vector3
const rotation = new Euler();
rotation = new Euler()
rotation
new Euler()
Euler
const quaternion = new Quaternion();
quaternion = new Quaternion()
quaternion
new Quaternion()
Quaternion
const scale = new Vector3(1, 1, 1);
scale = new Vector3(1, 1, 1)
scale
new Vector3(1, 1, 1)
Vector3
1
1
1
function onRotationChange() {
  quaternion.setFromEuler(rotation, false);
}
onBeforeShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
onBeforeShadow
{}
onAfterShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
onAfterShadow( /* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}
onAfterShadow
{}
onBeforeRender( /* renderer, scene, camera, geometry, material, group */) {}
onBeforeRender( /* renderer, scene, camera, geometry, material, group */) {}
onBeforeRender
{}
onAfterRender( /* renderer, scene, camera, geometry, material, group */) {}
onAfterRender( /* renderer, scene, camera, geometry, material, group */) {}
onAfterRender
{}
applyMatrix4(matrix) {
  if (this.matrixAutoUpdate) this.updateMatrix();
  this.matrix.premultiply(matrix);
  this.matrix.decompose(this.position, this.quaternion, this.scale);
}
applyMatrix4(matrix) {
  if (this.matrixAutoUpdate) this.updateMatrix();
  this.matrix.premultiply(matrix);
  this.matrix.decompose(this.position, this.quaternion, this.scale);
}
applyMatrix4
matrix
{
  if (this.matrixAutoUpdate) this.updateMatrix();
  this.matrix.premultiply(matrix);
  this.matrix.decompose(this.position, this.quaternion, this.scale);
}
if (this.matrixAutoUpdate) this.updateMatrix();
this.matrixAutoUpdate
this
matrixAutoUpdate
this.updateMatrix();
this.updateMatrix()
this.updateMatrix
this
updateMatrix
this.matrix.premultiply(matrix);
this.matrix.premultiply(matrix)
this.matrix.premultiply
this.matrix
this
matrix
premultiply
matrix
this.matrix.decompose(this.position, this.quaternion, this.scale);
this.matrix.decompose(this.position, this.quaternion, this.scale)
this.matrix.decompose
this.matrix
this
matrix
decompose
this.position
this
position
this.quaternion
this
quaternion
this.scale
this
scale
applyQuaternion(q) {
  this.quaternion.premultiply(q);
  return this;
}
applyQuaternion(q) {
  this.quaternion.premultiply(q);
  return this;
}
applyQuaternion
q
{
  this.quaternion.premultiply(q);
  return this;
}
this.quaternion.premultiply(q);
this.quaternion.premultiply(q)
this.quaternion.premultiply
this.quaternion
this
quaternion
premultiply
q
return this;
this
setRotationFromAxisAngle(axis, angle) {
  // assumes axis is normalized

  this.quaternion.setFromAxisAngle(axis, angle);
}
setRotationFromAxisAngle(axis, angle) {
  // assumes axis is normalized

  this.quaternion.setFromAxisAngle(axis, angle);
}
setRotationFromAxisAngle
axis
angle
{
  // assumes axis is normalized

  this.quaternion.setFromAxisAngle(axis, angle);
}
// assumes axis is normalized

this.quaternion.setFromAxisAngle(axis, angle);
this.quaternion.setFromAxisAngle(axis, angle)
this.quaternion.setFromAxisAngle
this.quaternion
this
quaternion
setFromAxisAngle
axis
angle
setRotationFromEuler(euler) {
  this.quaternion.setFromEuler(euler, true);
}
setRotationFromEuler(euler) {
  this.quaternion.setFromEuler(euler, true);
}
setRotationFromEuler
euler
{
  this.quaternion.setFromEuler(euler, true);
}
this.quaternion.setFromEuler(euler, true);
this.quaternion.setFromEuler(euler, true)
this.quaternion.setFromEuler
this.quaternion
this
quaternion
setFromEuler
euler
true
setRotationFromMatrix(m) {
  // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

  this.quaternion.setFromRotationMatrix(m);
}
setRotationFromMatrix(m) {
  // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

  this.quaternion.setFromRotationMatrix(m);
}
setRotationFromMatrix
m
{
  // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

  this.quaternion.setFromRotationMatrix(m);
}
// assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

this.quaternion.setFromRotationMatrix(m);
this.quaternion.setFromRotationMatrix(m)
this.quaternion.setFromRotationMatrix
this.quaternion
this
quaternion
setFromRotationMatrix
m
setRotationFromQuaternion(q) {
  // assumes q is normalized

  this.quaternion.copy(q);
}
setRotationFromQuaternion(q) {
  // assumes q is normalized

  this.quaternion.copy(q);
}
setRotationFromQuaternion
q
{
  // assumes q is normalized

  this.quaternion.copy(q);
}
// assumes q is normalized

this.quaternion.copy(q);
this.quaternion.copy(q)
this.quaternion.copy
this.quaternion
this
quaternion
copy
q
rotateOnAxis(axis, angle) {
  // rotate object on axis in object space
  // axis is assumed to be normalized

  _q1.setFromAxisAngle(axis, angle);
  this.quaternion.multiply(_q1);
  return this;
}
rotateOnAxis(axis, angle) {
  // rotate object on axis in object space
  // axis is assumed to be normalized

  _q1.setFromAxisAngle(axis, angle);
  this.quaternion.multiply(_q1);
  return this;
}
rotateOnAxis
axis
angle
{
  // rotate object on axis in object space
  // axis is assumed to be normalized

  _q1.setFromAxisAngle(axis, angle);
  this.quaternion.multiply(_q1);
  return this;
}
// rotate object on axis in object space
// axis is assumed to be normalized

_q1.setFromAxisAngle(axis, angle);
_q1.setFromAxisAngle(axis, angle)
_q1.setFromAxisAngle
_q1
setFromAxisAngle
axis
angle
this.quaternion.multiply(_q1);
this.quaternion.multiply(_q1)
this.quaternion.multiply
this.quaternion
this
quaternion
multiply
_q1
return this;
this
rotateOnWorldAxis(axis, angle) {
  // rotate object on axis in world space
  // axis is assumed to be normalized
  // method assumes no rotated parent

  _q1.setFromAxisAngle(axis, angle);
  this.quaternion.premultiply(_q1);
  return this;
}
rotateOnWorldAxis(axis, angle) {
  // rotate object on axis in world space
  // axis is assumed to be normalized
  // method assumes no rotated parent

  _q1.setFromAxisAngle(axis, angle);
  this.quaternion.premultiply(_q1);
  return this;
}
rotateOnWorldAxis
axis
angle
{
  // rotate object on axis in world space
  // axis is assumed to be normalized
  // method assumes no rotated parent

  _q1.setFromAxisAngle(axis, angle);
  this.quaternion.premultiply(_q1);
  return this;
}
// rotate object on axis in world space
// axis is assumed to be normalized
// method assumes no rotated parent

_q1.setFromAxisAngle(axis, angle);
_q1.setFromAxisAngle(axis, angle)
_q1.setFromAxisAngle
_q1
setFromAxisAngle
axis
angle
this.quaternion.premultiply(_q1);
this.quaternion.premultiply(_q1)
this.quaternion.premultiply
this.quaternion
this
quaternion
premultiply
_q1
return this;
this
rotateX(angle) {
  return this.rotateOnAxis(_xAxis, angle);
}
rotateX(angle) {
  return this.rotateOnAxis(_xAxis, angle);
}
rotateX
angle
{
  return this.rotateOnAxis(_xAxis, angle);
}
return this.rotateOnAxis(_xAxis, angle);
this.rotateOnAxis(_xAxis, angle)
this.rotateOnAxis
this
rotateOnAxis
_xAxis
angle
rotateY(angle) {
  return this.rotateOnAxis(_yAxis, angle);
}
rotateY(angle) {
  return this.rotateOnAxis(_yAxis, angle);
}
rotateY
angle
{
  return this.rotateOnAxis(_yAxis, angle);
}
return this.rotateOnAxis(_yAxis, angle);
this.rotateOnAxis(_yAxis, angle)
this.rotateOnAxis
this
rotateOnAxis
_yAxis
angle
rotateZ(angle) {
  return this.rotateOnAxis(_zAxis, angle);
}
rotateZ(angle) {
  return this.rotateOnAxis(_zAxis, angle);
}
rotateZ
angle
{
  return this.rotateOnAxis(_zAxis, angle);
}
return this.rotateOnAxis(_zAxis, angle);
this.rotateOnAxis(_zAxis, angle)
this.rotateOnAxis
this
rotateOnAxis
_zAxis
angle
translateOnAxis(axis, distance) {
  // translate object by distance along axis in object space
  // axis is assumed to be normalized

  _v1.copy(axis).applyQuaternion(this.quaternion);
  this.position.add(_v1.multiplyScalar(distance));
  return this;
}
translateOnAxis(axis, distance) {
  // translate object by distance along axis in object space
  // axis is assumed to be normalized

  _v1.copy(axis).applyQuaternion(this.quaternion);
  this.position.add(_v1.multiplyScalar(distance));
  return this;
}
translateOnAxis
axis
distance
{
  // translate object by distance along axis in object space
  // axis is assumed to be normalized

  _v1.copy(axis).applyQuaternion(this.quaternion);
  this.position.add(_v1.multiplyScalar(distance));
  return this;
}
// translate object by distance along axis in object space
// axis is assumed to be normalized

_v1.copy(axis).applyQuaternion(this.quaternion);
_v1.copy(axis).applyQuaternion(this.quaternion)
_v1.copy(axis).applyQuaternion
_v1.copy(axis)
_v1.copy
_v1
copy
axis
applyQuaternion
this.quaternion
this
quaternion
this.position.add(_v1.multiplyScalar(distance));
this.position.add(_v1.multiplyScalar(distance))
this.position.add
this.position
this
position
add
_v1.multiplyScalar(distance)
_v1.multiplyScalar
_v1
multiplyScalar
distance
return this;
this
translateX(distance) {
  return this.translateOnAxis(_xAxis, distance);
}
translateX(distance) {
  return this.translateOnAxis(_xAxis, distance);
}
translateX
distance
{
  return this.translateOnAxis(_xAxis, distance);
}
return this.translateOnAxis(_xAxis, distance);
this.translateOnAxis(_xAxis, distance)
this.translateOnAxis
this
translateOnAxis
_xAxis
distance
translateY(distance) {
  return this.translateOnAxis(_yAxis, distance);
}
translateY(distance) {
  return this.translateOnAxis(_yAxis, distance);
}
translateY
distance
{
  return this.translateOnAxis(_yAxis, distance);
}
return this.translateOnAxis(_yAxis, distance);
this.translateOnAxis(_yAxis, distance)
this.translateOnAxis
this
translateOnAxis
_yAxis
distance
translateZ(distance) {
  return this.translateOnAxis(_zAxis, distance);
}
translateZ(distance) {
  return this.translateOnAxis(_zAxis, distance);
}
translateZ
distance
{
  return this.translateOnAxis(_zAxis, distance);
}
return this.translateOnAxis(_zAxis, distance);
this.translateOnAxis(_zAxis, distance)
this.translateOnAxis
this
translateOnAxis
_zAxis
distance
localToWorld(vector) {
  this.updateWorldMatrix(true, false);
  return vector.applyMatrix4(this.matrixWorld);
}
localToWorld(vector) {
  this.updateWorldMatrix(true, false);
  return vector.applyMatrix4(this.matrixWorld);
}
localToWorld
vector
{
  this.updateWorldMatrix(true, false);
  return vector.applyMatrix4(this.matrixWorld);
}
this.updateWorldMatrix(true, false);
this.updateWorldMatrix(true, false)
this.updateWorldMatrix
this
updateWorldMatrix
true
false
return vector.applyMatrix4(this.matrixWorld);
vector.applyMatrix4(this.matrixWorld)
vector.applyMatrix4
vector
applyMatrix4
this.matrixWorld
this
matrixWorld
worldToLocal(vector) {
  this.updateWorldMatrix(true, false);
  return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
}
worldToLocal(vector) {
  this.updateWorldMatrix(true, false);
  return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
}
worldToLocal
vector
{
  this.updateWorldMatrix(true, false);
  return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
}
this.updateWorldMatrix(true, false);
this.updateWorldMatrix(true, false)
this.updateWorldMatrix
this
updateWorldMatrix
true
false
return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
vector.applyMatrix4(_m1.copy(this.matrixWorld).invert())
vector.applyMatrix4
vector
applyMatrix4
_m1.copy(this.matrixWorld).invert()
_m1.copy(this.matrixWorld).invert
_m1.copy(this.matrixWorld)
_m1.copy
_m1
copy
this.matrixWorld
this
matrixWorld
invert
lookAt(x, y, z) {
  // This method does not support objects having non-uniformly-scaled parent(s)

  if (x.isVector3) {
    _target.copy(x);
  } else {
    _target.set(x, y, z);
  }
  const parent = this.parent;
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
lookAt(x, y, z) {
  // This method does not support objects having non-uniformly-scaled parent(s)

  if (x.isVector3) {
    _target.copy(x);
  } else {
    _target.set(x, y, z);
  }
  const parent = this.parent;
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
lookAt
x
y
z
{
  // This method does not support objects having non-uniformly-scaled parent(s)

  if (x.isVector3) {
    _target.copy(x);
  } else {
    _target.set(x, y, z);
  }
  const parent = this.parent;
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
// This method does not support objects having non-uniformly-scaled parent(s)

if (x.isVector3) {
  _target.copy(x);
} else {
  _target.set(x, y, z);
}
x.isVector3
x
isVector3
{
  _target.copy(x);
}
_target.copy(x);
_target.copy(x)
_target.copy
_target
copy
x
{
  _target.set(x, y, z);
}
_target.set(x, y, z);
_target.set(x, y, z)
_target.set
_target
set
x
y
z
const parent = this.parent;
parent = this.parent
parent
this.parent
this
parent
this.updateWorldMatrix(true, false);
this.updateWorldMatrix(true, false)
this.updateWorldMatrix
this
updateWorldMatrix
true
false
_position.setFromMatrixPosition(this.matrixWorld);
_position.setFromMatrixPosition(this.matrixWorld)
_position.setFromMatrixPosition
_position
setFromMatrixPosition
this.matrixWorld
this
matrixWorld
if (this.isCamera || this.isLight) {
  _m1.lookAt(_position, _target, this.up);
} else {
  _m1.lookAt(_target, _position, this.up);
}
this.isCamera || this.isLight
this.isCamera
this
isCamera
this.isLight
this
isLight
{
  _m1.lookAt(_position, _target, this.up);
}
_m1.lookAt(_position, _target, this.up);
_m1.lookAt(_position, _target, this.up)
_m1.lookAt
_m1
lookAt
_position
_target
this.up
this
up
{
  _m1.lookAt(_target, _position, this.up);
}
_m1.lookAt(_target, _position, this.up);
_m1.lookAt(_target, _position, this.up)
_m1.lookAt
_m1
lookAt
_target
_position
this.up
this
up
this.quaternion.setFromRotationMatrix(_m1);
this.quaternion.setFromRotationMatrix(_m1)
this.quaternion.setFromRotationMatrix
this.quaternion
this
quaternion
setFromRotationMatrix
_m1
if (parent) {
  _m1.extractRotation(parent.matrixWorld);
  _q1.setFromRotationMatrix(_m1);
  this.quaternion.premultiply(_q1.invert());
}
parent
{
  _m1.extractRotation(parent.matrixWorld);
  _q1.setFromRotationMatrix(_m1);
  this.quaternion.premultiply(_q1.invert());
}
_m1.extractRotation(parent.matrixWorld);
_m1.extractRotation(parent.matrixWorld)
_m1.extractRotation
_m1
extractRotation
parent.matrixWorld
parent
matrixWorld
_q1.setFromRotationMatrix(_m1);
_q1.setFromRotationMatrix(_m1)
_q1.setFromRotationMatrix
_q1
setFromRotationMatrix
_m1
this.quaternion.premultiply(_q1.invert());
this.quaternion.premultiply(_q1.invert())
this.quaternion.premultiply
this.quaternion
this
quaternion
premultiply
_q1.invert()
_q1.invert
_q1
invert
add(object) {
  if (arguments.length > 1) {
    for (let i = 0; i < arguments.length; i++) {
      this.add(arguments[i]);
    }
    return this;
  }
  if (object === this) {
    console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
    return this;
  }
  if (object && object.isObject3D) {
    object.removeFromParent();
    object.parent = this;
    this.children.push(object);
    object.dispatchEvent(_addedEvent);
    _childaddedEvent.child = object;
    this.dispatchEvent(_childaddedEvent);
    _childaddedEvent.child = null;
  } else {
    console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
  }
  return this;
}
add(object) {
  if (arguments.length > 1) {
    for (let i = 0; i < arguments.length; i++) {
      this.add(arguments[i]);
    }
    return this;
  }
  if (object === this) {
    console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
    return this;
  }
  if (object && object.isObject3D) {
    object.removeFromParent();
    object.parent = this;
    this.children.push(object);
    object.dispatchEvent(_addedEvent);
    _childaddedEvent.child = object;
    this.dispatchEvent(_childaddedEvent);
    _childaddedEvent.child = null;
  } else {
    console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
  }
  return this;
}
add
object
{
  if (arguments.length > 1) {
    for (let i = 0; i < arguments.length; i++) {
      this.add(arguments[i]);
    }
    return this;
  }
  if (object === this) {
    console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
    return this;
  }
  if (object && object.isObject3D) {
    object.removeFromParent();
    object.parent = this;
    this.children.push(object);
    object.dispatchEvent(_addedEvent);
    _childaddedEvent.child = object;
    this.dispatchEvent(_childaddedEvent);
    _childaddedEvent.child = null;
  } else {
    console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
  }
  return this;
}
if (arguments.length > 1) {
  for (let i = 0; i < arguments.length; i++) {
    this.add(arguments[i]);
  }
  return this;
}
arguments.length > 1
arguments.length
arguments
length
1
{
  for (let i = 0; i < arguments.length; i++) {
    this.add(arguments[i]);
  }
  return this;
}
for (let i = 0; i < arguments.length; i++) {
  this.add(arguments[i]);
}
let i = 0;
i = 0
i
0
i < arguments.length
i
arguments.length
arguments
length
i++
i
{
  this.add(arguments[i]);
}
this.add(arguments[i]);
this.add(arguments[i])
this.add
this
add
arguments[i]
arguments
i
return this;
this
if (object === this) {
  console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
  return this;
}
object === this
object
this
{
  console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
  return this;
}
console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object)
console.error
console
error
'THREE.Object3D.add: object can\'t be added as a child of itself.'
object
return this;
this
if (object && object.isObject3D) {
  object.removeFromParent();
  object.parent = this;
  this.children.push(object);
  object.dispatchEvent(_addedEvent);
  _childaddedEvent.child = object;
  this.dispatchEvent(_childaddedEvent);
  _childaddedEvent.child = null;
} else {
  console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
}
object && object.isObject3D
object
object.isObject3D
object
isObject3D
{
  object.removeFromParent();
  object.parent = this;
  this.children.push(object);
  object.dispatchEvent(_addedEvent);
  _childaddedEvent.child = object;
  this.dispatchEvent(_childaddedEvent);
  _childaddedEvent.child = null;
}
object.removeFromParent();
object.removeFromParent()
object.removeFromParent
object
removeFromParent
object.parent = this;
object.parent = this
object.parent
object
parent
this
this.children.push(object);
this.children.push(object)
this.children.push
this.children
this
children
push
object
object.dispatchEvent(_addedEvent);
object.dispatchEvent(_addedEvent)
object.dispatchEvent
object
dispatchEvent
_addedEvent
_childaddedEvent.child = object;
_childaddedEvent.child = object
_childaddedEvent.child
_childaddedEvent
child
object
this.dispatchEvent(_childaddedEvent);
this.dispatchEvent(_childaddedEvent)
this.dispatchEvent
this
dispatchEvent
_childaddedEvent
_childaddedEvent.child = null;
_childaddedEvent.child = null
_childaddedEvent.child
_childaddedEvent
child
null
{
  console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
}
console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object)
console.error
console
error
'THREE.Object3D.add: object not an instance of THREE.Object3D.'
object
return this;
this
remove(object) {
  if (arguments.length > 1) {
    for (let i = 0; i < arguments.length; i++) {
      this.remove(arguments[i]);
    }
    return this;
  }
  const index = this.children.indexOf(object);
  if (index !== -1) {
    object.parent = null;
    this.children.splice(index, 1);
    object.dispatchEvent(_removedEvent);
    _childremovedEvent.child = object;
    this.dispatchEvent(_childremovedEvent);
    _childremovedEvent.child = null;
  }
  return this;
}
remove(object) {
  if (arguments.length > 1) {
    for (let i = 0; i < arguments.length; i++) {
      this.remove(arguments[i]);
    }
    return this;
  }
  const index = this.children.indexOf(object);
  if (index !== -1) {
    object.parent = null;
    this.children.splice(index, 1);
    object.dispatchEvent(_removedEvent);
    _childremovedEvent.child = object;
    this.dispatchEvent(_childremovedEvent);
    _childremovedEvent.child = null;
  }
  return this;
}
remove
object
{
  if (arguments.length > 1) {
    for (let i = 0; i < arguments.length; i++) {
      this.remove(arguments[i]);
    }
    return this;
  }
  const index = this.children.indexOf(object);
  if (index !== -1) {
    object.parent = null;
    this.children.splice(index, 1);
    object.dispatchEvent(_removedEvent);
    _childremovedEvent.child = object;
    this.dispatchEvent(_childremovedEvent);
    _childremovedEvent.child = null;
  }
  return this;
}
if (arguments.length > 1) {
  for (let i = 0; i < arguments.length; i++) {
    this.remove(arguments[i]);
  }
  return this;
}
arguments.length > 1
arguments.length
arguments
length
1
{
  for (let i = 0; i < arguments.length; i++) {
    this.remove(arguments[i]);
  }
  return this;
}
for (let i = 0; i < arguments.length; i++) {
  this.remove(arguments[i]);
}
let i = 0;
i = 0
i
0
i < arguments.length
i
arguments.length
arguments
length
i++
i
{
  this.remove(arguments[i]);
}
this.remove(arguments[i]);
this.remove(arguments[i])
this.remove
this
remove
arguments[i]
arguments
i
return this;
this
const index = this.children.indexOf(object);
index = this.children.indexOf(object)
index
this.children.indexOf(object)
this.children.indexOf
this.children
this
children
indexOf
object
if (index !== -1) {
  object.parent = null;
  this.children.splice(index, 1);
  object.dispatchEvent(_removedEvent);
  _childremovedEvent.child = object;
  this.dispatchEvent(_childremovedEvent);
  _childremovedEvent.child = null;
}
index !== -1
index
-1
1
{
  object.parent = null;
  this.children.splice(index, 1);
  object.dispatchEvent(_removedEvent);
  _childremovedEvent.child = object;
  this.dispatchEvent(_childremovedEvent);
  _childremovedEvent.child = null;
}
object.parent = null;
object.parent = null
object.parent
object
parent
null
this.children.splice(index, 1);
this.children.splice(index, 1)
this.children.splice
this.children
this
children
splice
index
1
object.dispatchEvent(_removedEvent);
object.dispatchEvent(_removedEvent)
object.dispatchEvent
object
dispatchEvent
_removedEvent
_childremovedEvent.child = object;
_childremovedEvent.child = object
_childremovedEvent.child
_childremovedEvent
child
object
this.dispatchEvent(_childremovedEvent);
this.dispatchEvent(_childremovedEvent)
this.dispatchEvent
this
dispatchEvent
_childremovedEvent
_childremovedEvent.child = null;
_childremovedEvent.child = null
_childremovedEvent.child
_childremovedEvent
child
null
return this;
this
removeFromParent() {
  const parent = this.parent;
  if (parent !== null) {
    parent.remove(this);
  }
  return this;
}
removeFromParent() {
  const parent = this.parent;
  if (parent !== null) {
    parent.remove(this);
  }
  return this;
}
removeFromParent
{
  const parent = this.parent;
  if (parent !== null) {
    parent.remove(this);
  }
  return this;
}
const parent = this.parent;
parent = this.parent
parent
this.parent
this
parent
if (parent !== null) {
  parent.remove(this);
}
parent !== null
parent
null
{
  parent.remove(this);
}
parent.remove(this);
parent.remove(this)
parent.remove
parent
remove
this
return this;
this
clear() {
  return this.remove(...this.children);
}
clear() {
  return this.remove(...this.children);
}
clear
{
  return this.remove(...this.children);
}
return this.remove(...this.children);
this.remove(...this.children)
this.remove
this
remove
...this.children
this.children
this
children
attach(object) {
  // adds object as a child of this, while maintaining the object's world transform

  // Note: This method does not support scene graphs having non-uniformly-scaled nodes(s)

  this.updateWorldMatrix(true, false);
  _m1.copy(this.matrixWorld).invert();
  if (object.parent !== null) {
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
attach(object) {
  // adds object as a child of this, while maintaining the object's world transform

  // Note: This method does not support scene graphs having non-uniformly-scaled nodes(s)

  this.updateWorldMatrix(true, false);
  _m1.copy(this.matrixWorld).invert();
  if (object.parent !== null) {
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
attach
object
{
  // adds object as a child of this, while maintaining the object's world transform

  // Note: This method does not support scene graphs having non-uniformly-scaled nodes(s)

  this.updateWorldMatrix(true, false);
  _m1.copy(this.matrixWorld).invert();
  if (object.parent !== null) {
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
// adds object as a child of this, while maintaining the object's world transform

// Note: This method does not support scene graphs having non-uniformly-scaled nodes(s)

this.updateWorldMatrix(true, false);
this.updateWorldMatrix(true, false)
this.updateWorldMatrix
this
updateWorldMatrix
true
false
_m1.copy(this.matrixWorld).invert();
_m1.copy(this.matrixWorld).invert()
_m1.copy(this.matrixWorld).invert
_m1.copy(this.matrixWorld)
_m1.copy
_m1
copy
this.matrixWorld
this
matrixWorld
invert
if (object.parent !== null) {
  object.parent.updateWorldMatrix(true, false);
  _m1.multiply(object.parent.matrixWorld);
}
object.parent !== null
object.parent
object
parent
null
{
  object.parent.updateWorldMatrix(true, false);
  _m1.multiply(object.parent.matrixWorld);
}
object.parent.updateWorldMatrix(true, false);
object.parent.updateWorldMatrix(true, false)
object.parent.updateWorldMatrix
object.parent
object
parent
updateWorldMatrix
true
false
_m1.multiply(object.parent.matrixWorld);
_m1.multiply(object.parent.matrixWorld)
_m1.multiply
_m1
multiply
object.parent.matrixWorld
object.parent
object
parent
matrixWorld
object.applyMatrix4(_m1);
object.applyMatrix4(_m1)
object.applyMatrix4
object
applyMatrix4
_m1
object.removeFromParent();
object.removeFromParent()
object.removeFromParent
object
removeFromParent
object.parent = this;
object.parent = this
object.parent
object
parent
this
this.children.push(object);
this.children.push(object)
this.children.push
this.children
this
children
push
object
object.updateWorldMatrix(false, true);
object.updateWorldMatrix(false, true)
object.updateWorldMatrix
object
updateWorldMatrix
false
true
object.dispatchEvent(_addedEvent);
object.dispatchEvent(_addedEvent)
object.dispatchEvent
object
dispatchEvent
_addedEvent
_childaddedEvent.child = object;
_childaddedEvent.child = object
_childaddedEvent.child
_childaddedEvent
child
object
this.dispatchEvent(_childaddedEvent);
this.dispatchEvent(_childaddedEvent)
this.dispatchEvent
this
dispatchEvent
_childaddedEvent
_childaddedEvent.child = null;
_childaddedEvent.child = null
_childaddedEvent.child
_childaddedEvent
child
null
return this;
this
getObjectById(id) {
  return this.getObjectByProperty('id', id);
}
getObjectById(id) {
  return this.getObjectByProperty('id', id);
}
getObjectById
id
{
  return this.getObjectByProperty('id', id);
}
return this.getObjectByProperty('id', id);
this.getObjectByProperty('id', id)
this.getObjectByProperty
this
getObjectByProperty
'id'
id
getObjectByName(name) {
  return this.getObjectByProperty('name', name);
}
getObjectByName(name) {
  return this.getObjectByProperty('name', name);
}
getObjectByName
name
{
  return this.getObjectByProperty('name', name);
}
return this.getObjectByProperty('name', name);
this.getObjectByProperty('name', name)
this.getObjectByProperty
this
getObjectByProperty
'name'
name
getObjectByProperty(name, value) {
  if (this[name] === value) return this;
  for (let i = 0, l = this.children.length; i < l; i++) {
    const child = this.children[i];
    const object = child.getObjectByProperty(name, value);
    if (object !== undefined) {
      return object;
    }
  }
  return undefined;
}
getObjectByProperty(name, value) {
  if (this[name] === value) return this;
  for (let i = 0, l = this.children.length; i < l; i++) {
    const child = this.children[i];
    const object = child.getObjectByProperty(name, value);
    if (object !== undefined) {
      return object;
    }
  }
  return undefined;
}
getObjectByProperty
name
value
{
  if (this[name] === value) return this;
  for (let i = 0, l = this.children.length; i < l; i++) {
    const child = this.children[i];
    const object = child.getObjectByProperty(name, value);
    if (object !== undefined) {
      return object;
    }
  }
  return undefined;
}
if (this[name] === value) return this;
this[name] === value
this[name]
this
name
value
return this;
this
for (let i = 0, l = this.children.length; i < l; i++) {
  const child = this.children[i];
  const object = child.getObjectByProperty(name, value);
  if (object !== undefined) {
    return object;
  }
}
let i = 0,
  l = this.children.length;
i = 0
i
0
l = this.children.length
l
this.children.length
this.children
this
children
length
i < l
i
l
i++
i
{
  const child = this.children[i];
  const object = child.getObjectByProperty(name, value);
  if (object !== undefined) {
    return object;
  }
}
const child = this.children[i];
child = this.children[i]
child
this.children[i]
this.children
this
children
i
const object = child.getObjectByProperty(name, value);
object = child.getObjectByProperty(name, value)
object
child.getObjectByProperty(name, value)
child.getObjectByProperty
child
getObjectByProperty
name
value
if (object !== undefined) {
  return object;
}
object !== undefined
object
undefined
{
  return object;
}
return object;
object
return undefined;
undefined
getObjectsByProperty(name, value, result = []) {
  if (this[name] === value) result.push(this);
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    children[i].getObjectsByProperty(name, value, result);
  }
  return result;
}
getObjectsByProperty(name, value, result = []) {
  if (this[name] === value) result.push(this);
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    children[i].getObjectsByProperty(name, value, result);
  }
  return result;
}
getObjectsByProperty
name
value
result = []
result
[]
{
  if (this[name] === value) result.push(this);
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    children[i].getObjectsByProperty(name, value, result);
  }
  return result;
}
if (this[name] === value) result.push(this);
this[name] === value
this[name]
this
name
value
result.push(this);
result.push(this)
result.push
result
push
this
const children = this.children;
children = this.children
children
this.children
this
children
for (let i = 0, l = children.length; i < l; i++) {
  children[i].getObjectsByProperty(name, value, result);
}
let i = 0,
  l = children.length;
i = 0
i
0
l = children.length
l
children.length
children
length
i < l
i
l
i++
i
{
  children[i].getObjectsByProperty(name, value, result);
}
children[i].getObjectsByProperty(name, value, result);
children[i].getObjectsByProperty(name, value, result)
children[i].getObjectsByProperty
children[i]
children
i
getObjectsByProperty
name
value
result
return result;
result
getWorldPosition(target) {
  this.updateWorldMatrix(true, false);
  return target.setFromMatrixPosition(this.matrixWorld);
}
getWorldPosition(target) {
  this.updateWorldMatrix(true, false);
  return target.setFromMatrixPosition(this.matrixWorld);
}
getWorldPosition
target
{
  this.updateWorldMatrix(true, false);
  return target.setFromMatrixPosition(this.matrixWorld);
}
this.updateWorldMatrix(true, false);
this.updateWorldMatrix(true, false)
this.updateWorldMatrix
this
updateWorldMatrix
true
false
return target.setFromMatrixPosition(this.matrixWorld);
target.setFromMatrixPosition(this.matrixWorld)
target.setFromMatrixPosition
target
setFromMatrixPosition
this.matrixWorld
this
matrixWorld
getWorldQuaternion(target) {
  this.updateWorldMatrix(true, false);
  this.matrixWorld.decompose(_position, target, _scale);
  return target;
}
getWorldQuaternion(target) {
  this.updateWorldMatrix(true, false);
  this.matrixWorld.decompose(_position, target, _scale);
  return target;
}
getWorldQuaternion
target
{
  this.updateWorldMatrix(true, false);
  this.matrixWorld.decompose(_position, target, _scale);
  return target;
}
this.updateWorldMatrix(true, false);
this.updateWorldMatrix(true, false)
this.updateWorldMatrix
this
updateWorldMatrix
true
false
this.matrixWorld.decompose(_position, target, _scale);
this.matrixWorld.decompose(_position, target, _scale)
this.matrixWorld.decompose
this.matrixWorld
this
matrixWorld
decompose
_position
target
_scale
return target;
target
getWorldScale(target) {
  this.updateWorldMatrix(true, false);
  this.matrixWorld.decompose(_position, _quaternion, target);
  return target;
}
getWorldScale(target) {
  this.updateWorldMatrix(true, false);
  this.matrixWorld.decompose(_position, _quaternion, target);
  return target;
}
getWorldScale
target
{
  this.updateWorldMatrix(true, false);
  this.matrixWorld.decompose(_position, _quaternion, target);
  return target;
}
this.updateWorldMatrix(true, false);
this.updateWorldMatrix(true, false)
this.updateWorldMatrix
this
updateWorldMatrix
true
false
this.matrixWorld.decompose(_position, _quaternion, target);
this.matrixWorld.decompose(_position, _quaternion, target)
this.matrixWorld.decompose
this.matrixWorld
this
matrixWorld
decompose
_position
_quaternion
target
return target;
target
getWorldDirection(target) {
  this.updateWorldMatrix(true, false);
  const e = this.matrixWorld.elements;
  return target.set(e[8], e[9], e[10]).normalize();
}
getWorldDirection(target) {
  this.updateWorldMatrix(true, false);
  const e = this.matrixWorld.elements;
  return target.set(e[8], e[9], e[10]).normalize();
}
getWorldDirection
target
{
  this.updateWorldMatrix(true, false);
  const e = this.matrixWorld.elements;
  return target.set(e[8], e[9], e[10]).normalize();
}
this.updateWorldMatrix(true, false);
this.updateWorldMatrix(true, false)
this.updateWorldMatrix
this
updateWorldMatrix
true
false
const e = this.matrixWorld.elements;
e = this.matrixWorld.elements
e
this.matrixWorld.elements
this.matrixWorld
this
matrixWorld
elements
return target.set(e[8], e[9], e[10]).normalize();
target.set(e[8], e[9], e[10]).normalize()
target.set(e[8], e[9], e[10]).normalize
target.set(e[8], e[9], e[10])
target.set
target
set
e[8]
e
8
e[9]
e
9
e[10]
e
10
normalize
raycast( /* raycaster, intersects */) {}
raycast( /* raycaster, intersects */) {}
raycast
{}
traverse(callback) {
  callback(this);
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    children[i].traverse(callback);
  }
}
traverse(callback) {
  callback(this);
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    children[i].traverse(callback);
  }
}
traverse
callback
{
  callback(this);
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    children[i].traverse(callback);
  }
}
callback(this);
callback(this)
callback
this
const children = this.children;
children = this.children
children
this.children
this
children
for (let i = 0, l = children.length; i < l; i++) {
  children[i].traverse(callback);
}
let i = 0,
  l = children.length;
i = 0
i
0
l = children.length
l
children.length
children
length
i < l
i
l
i++
i
{
  children[i].traverse(callback);
}
children[i].traverse(callback);
children[i].traverse(callback)
children[i].traverse
children[i]
children
i
traverse
callback
traverseVisible(callback) {
  if (this.visible === false) return;
  callback(this);
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    children[i].traverseVisible(callback);
  }
}
traverseVisible(callback) {
  if (this.visible === false) return;
  callback(this);
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    children[i].traverseVisible(callback);
  }
}
traverseVisible
callback
{
  if (this.visible === false) return;
  callback(this);
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    children[i].traverseVisible(callback);
  }
}
if (this.visible === false) return;
this.visible === false
this.visible
this
visible
false
return;
callback(this);
callback(this)
callback
this
const children = this.children;
children = this.children
children
this.children
this
children
for (let i = 0, l = children.length; i < l; i++) {
  children[i].traverseVisible(callback);
}
let i = 0,
  l = children.length;
i = 0
i
0
l = children.length
l
children.length
children
length
i < l
i
l
i++
i
{
  children[i].traverseVisible(callback);
}
children[i].traverseVisible(callback);
children[i].traverseVisible(callback)
children[i].traverseVisible
children[i]
children
i
traverseVisible
callback
traverseAncestors(callback) {
  const parent = this.parent;
  if (parent !== null) {
    callback(parent);
    parent.traverseAncestors(callback);
  }
}
traverseAncestors(callback) {
  const parent = this.parent;
  if (parent !== null) {
    callback(parent);
    parent.traverseAncestors(callback);
  }
}
traverseAncestors
callback
{
  const parent = this.parent;
  if (parent !== null) {
    callback(parent);
    parent.traverseAncestors(callback);
  }
}
const parent = this.parent;
parent = this.parent
parent
this.parent
this
parent
if (parent !== null) {
  callback(parent);
  parent.traverseAncestors(callback);
}
parent !== null
parent
null
{
  callback(parent);
  parent.traverseAncestors(callback);
}
callback(parent);
callback(parent)
callback
parent
parent.traverseAncestors(callback);
parent.traverseAncestors(callback)
parent.traverseAncestors
parent
traverseAncestors
callback
updateMatrix() {
  this.matrix.compose(this.position, this.quaternion, this.scale);
  this.matrixWorldNeedsUpdate = true;
}
updateMatrix() {
  this.matrix.compose(this.position, this.quaternion, this.scale);
  this.matrixWorldNeedsUpdate = true;
}
updateMatrix
{
  this.matrix.compose(this.position, this.quaternion, this.scale);
  this.matrixWorldNeedsUpdate = true;
}
this.matrix.compose(this.position, this.quaternion, this.scale);
this.matrix.compose(this.position, this.quaternion, this.scale)
this.matrix.compose
this.matrix
this
matrix
compose
this.position
this
position
this.quaternion
this
quaternion
this.scale
this
scale
this.matrixWorldNeedsUpdate = true;
this.matrixWorldNeedsUpdate = true
this.matrixWorldNeedsUpdate
this
matrixWorldNeedsUpdate
true
updateMatrixWorld(force) {
  if (this.matrixAutoUpdate) this.updateMatrix();
  if (this.matrixWorldNeedsUpdate || force) {
    if (this.parent === null) {
      this.matrixWorld.copy(this.matrix);
    } else {
      this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
    }
    this.matrixWorldNeedsUpdate = false;
    force = true;
  }

  // update children

  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    const child = children[i];
    if (child.matrixWorldAutoUpdate === true || force === true) {
      child.updateMatrixWorld(force);
    }
  }
}
updateMatrixWorld(force) {
  if (this.matrixAutoUpdate) this.updateMatrix();
  if (this.matrixWorldNeedsUpdate || force) {
    if (this.parent === null) {
      this.matrixWorld.copy(this.matrix);
    } else {
      this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
    }
    this.matrixWorldNeedsUpdate = false;
    force = true;
  }

  // update children

  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    const child = children[i];
    if (child.matrixWorldAutoUpdate === true || force === true) {
      child.updateMatrixWorld(force);
    }
  }
}
updateMatrixWorld
force
{
  if (this.matrixAutoUpdate) this.updateMatrix();
  if (this.matrixWorldNeedsUpdate || force) {
    if (this.parent === null) {
      this.matrixWorld.copy(this.matrix);
    } else {
      this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
    }
    this.matrixWorldNeedsUpdate = false;
    force = true;
  }

  // update children

  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    const child = children[i];
    if (child.matrixWorldAutoUpdate === true || force === true) {
      child.updateMatrixWorld(force);
    }
  }
}
if (this.matrixAutoUpdate) this.updateMatrix();
this.matrixAutoUpdate
this
matrixAutoUpdate
this.updateMatrix();
this.updateMatrix()
this.updateMatrix
this
updateMatrix
if (this.matrixWorldNeedsUpdate || force) {
  if (this.parent === null) {
    this.matrixWorld.copy(this.matrix);
  } else {
    this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
  }
  this.matrixWorldNeedsUpdate = false;
  force = true;
}

// update children
this.matrixWorldNeedsUpdate || force
this.matrixWorldNeedsUpdate
this
matrixWorldNeedsUpdate
force
{
  if (this.parent === null) {
    this.matrixWorld.copy(this.matrix);
  } else {
    this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
  }
  this.matrixWorldNeedsUpdate = false;
  force = true;
}
if (this.parent === null) {
  this.matrixWorld.copy(this.matrix);
} else {
  this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
}
this.parent === null
this.parent
this
parent
null
{
  this.matrixWorld.copy(this.matrix);
}
this.matrixWorld.copy(this.matrix);
this.matrixWorld.copy(this.matrix)
this.matrixWorld.copy
this.matrixWorld
this
matrixWorld
copy
this.matrix
this
matrix
{
  this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
}
this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix)
this.matrixWorld.multiplyMatrices
this.matrixWorld
this
matrixWorld
multiplyMatrices
this.parent.matrixWorld
this.parent
this
parent
matrixWorld
this.matrix
this
matrix
this.matrixWorldNeedsUpdate = false;
this.matrixWorldNeedsUpdate = false
this.matrixWorldNeedsUpdate
this
matrixWorldNeedsUpdate
false
force = true;
force = true
force
true
// update children

const children = this.children;
children = this.children
children
this.children
this
children
for (let i = 0, l = children.length; i < l; i++) {
  const child = children[i];
  if (child.matrixWorldAutoUpdate === true || force === true) {
    child.updateMatrixWorld(force);
  }
}
let i = 0,
  l = children.length;
i = 0
i
0
l = children.length
l
children.length
children
length
i < l
i
l
i++
i
{
  const child = children[i];
  if (child.matrixWorldAutoUpdate === true || force === true) {
    child.updateMatrixWorld(force);
  }
}
const child = children[i];
child = children[i]
child
children[i]
children
i
if (child.matrixWorldAutoUpdate === true || force === true) {
  child.updateMatrixWorld(force);
}
child.matrixWorldAutoUpdate === true || force === true
child.matrixWorldAutoUpdate === true
child.matrixWorldAutoUpdate
child
matrixWorldAutoUpdate
true
force === true
force
true
{
  child.updateMatrixWorld(force);
}
child.updateMatrixWorld(force);
child.updateMatrixWorld(force)
child.updateMatrixWorld
child
updateMatrixWorld
force
updateWorldMatrix(updateParents, updateChildren) {
  const parent = this.parent;
  if (updateParents === true && parent !== null && parent.matrixWorldAutoUpdate === true) {
    parent.updateWorldMatrix(true, false);
  }
  if (this.matrixAutoUpdate) this.updateMatrix();
  if (this.parent === null) {
    this.matrixWorld.copy(this.matrix);
  } else {
    this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
  }

  // update children

  if (updateChildren === true) {
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      const child = children[i];
      if (child.matrixWorldAutoUpdate === true) {
        child.updateWorldMatrix(false, true);
      }
    }
  }
}
updateWorldMatrix(updateParents, updateChildren) {
  const parent = this.parent;
  if (updateParents === true && parent !== null && parent.matrixWorldAutoUpdate === true) {
    parent.updateWorldMatrix(true, false);
  }
  if (this.matrixAutoUpdate) this.updateMatrix();
  if (this.parent === null) {
    this.matrixWorld.copy(this.matrix);
  } else {
    this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
  }

  // update children

  if (updateChildren === true) {
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      const child = children[i];
      if (child.matrixWorldAutoUpdate === true) {
        child.updateWorldMatrix(false, true);
      }
    }
  }
}
updateWorldMatrix
updateParents
updateChildren
{
  const parent = this.parent;
  if (updateParents === true && parent !== null && parent.matrixWorldAutoUpdate === true) {
    parent.updateWorldMatrix(true, false);
  }
  if (this.matrixAutoUpdate) this.updateMatrix();
  if (this.parent === null) {
    this.matrixWorld.copy(this.matrix);
  } else {
    this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
  }

  // update children

  if (updateChildren === true) {
    const children = this.children;
    for (let i = 0, l = children.length; i < l; i++) {
      const child = children[i];
      if (child.matrixWorldAutoUpdate === true) {
        child.updateWorldMatrix(false, true);
      }
    }
  }
}
const parent = this.parent;
parent = this.parent
parent
this.parent
this
parent
if (updateParents === true && parent !== null && parent.matrixWorldAutoUpdate === true) {
  parent.updateWorldMatrix(true, false);
}
updateParents === true && parent !== null && parent.matrixWorldAutoUpdate === true
updateParents === true && parent !== null
updateParents === true
updateParents
true
parent !== null
parent
null
parent.matrixWorldAutoUpdate === true
parent.matrixWorldAutoUpdate
parent
matrixWorldAutoUpdate
true
{
  parent.updateWorldMatrix(true, false);
}
parent.updateWorldMatrix(true, false);
parent.updateWorldMatrix(true, false)
parent.updateWorldMatrix
parent
updateWorldMatrix
true
false
if (this.matrixAutoUpdate) this.updateMatrix();
this.matrixAutoUpdate
this
matrixAutoUpdate
this.updateMatrix();
this.updateMatrix()
this.updateMatrix
this
updateMatrix
if (this.parent === null) {
  this.matrixWorld.copy(this.matrix);
} else {
  this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
}

// update children
this.parent === null
this.parent
this
parent
null
{
  this.matrixWorld.copy(this.matrix);
}
this.matrixWorld.copy(this.matrix);
this.matrixWorld.copy(this.matrix)
this.matrixWorld.copy
this.matrixWorld
this
matrixWorld
copy
this.matrix
this
matrix
{
  this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
}
this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix)
this.matrixWorld.multiplyMatrices
this.matrixWorld
this
matrixWorld
multiplyMatrices
this.parent.matrixWorld
this.parent
this
parent
matrixWorld
this.matrix
this
matrix
// update children

if (updateChildren === true) {
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    const child = children[i];
    if (child.matrixWorldAutoUpdate === true) {
      child.updateWorldMatrix(false, true);
    }
  }
}
updateChildren === true
updateChildren
true
{
  const children = this.children;
  for (let i = 0, l = children.length; i < l; i++) {
    const child = children[i];
    if (child.matrixWorldAutoUpdate === true) {
      child.updateWorldMatrix(false, true);
    }
  }
}
const children = this.children;
children = this.children
children
this.children
this
children
for (let i = 0, l = children.length; i < l; i++) {
  const child = children[i];
  if (child.matrixWorldAutoUpdate === true) {
    child.updateWorldMatrix(false, true);
  }
}
let i = 0,
  l = children.length;
i = 0
i
0
l = children.length
l
children.length
children
length
i < l
i
l
i++
i
{
  const child = children[i];
  if (child.matrixWorldAutoUpdate === true) {
    child.updateWorldMatrix(false, true);
  }
}
const child = children[i];
child = children[i]
child
children[i]
children
i
if (child.matrixWorldAutoUpdate === true) {
  child.updateWorldMatrix(false, true);
}
child.matrixWorldAutoUpdate === true
child.matrixWorldAutoUpdate
child
matrixWorldAutoUpdate
true
{
  child.updateWorldMatrix(false, true);
}
child.updateWorldMatrix(false, true);
child.updateWorldMatrix(false, true)
child.updateWorldMatrix
child
updateWorldMatrix
false
true
toJSON(meta) {
  // meta is a string when called from JSON.stringify
  const isRootObject = meta === undefined || typeof meta === 'string';
  const output = {};

  // meta is a hash used to collect geometries, materials.
  // not providing it implies that this is the root object
  // being serialized.
  if (isRootObject) {
    // initialize meta obj
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

  // standard Object3D serialization

  const object = {};
  object.uuid = this.uuid;
  object.type = this.type;
  if (this.name !== '') object.name = this.name;
  if (this.castShadow === true) object.castShadow = true;
  if (this.receiveShadow === true) object.receiveShadow = true;
  if (this.visible === false) object.visible = false;
  if (this.frustumCulled === false) object.frustumCulled = false;
  if (this.renderOrder !== 0) object.renderOrder = this.renderOrder;
  if (Object.keys(this.userData).length > 0) object.userData = this.userData;
  object.layers = this.layers.mask;
  object.matrix = this.matrix.toArray();
  object.up = this.up.toArray();
  if (this.matrixAutoUpdate === false) object.matrixAutoUpdate = false;

  // object specific properties

  if (this.isInstancedMesh) {
    object.type = 'InstancedMesh';
    object.count = this.count;
    object.instanceMatrix = this.instanceMatrix.toJSON();
    if (this.instanceColor !== null) object.instanceColor = this.instanceColor.toJSON();
  }
  if (this.isBatchedMesh) {
    object.type = 'BatchedMesh';
    object.perObjectFrustumCulled = this.perObjectFrustumCulled;
    object.sortObjects = this.sortObjects;
    object.drawRanges = this._drawRanges;
    object.reservedRanges = this._reservedRanges;
    object.visibility = this._visibility;
    object.active = this._active;
    object.bounds = this._bounds.map(bound => ({
      boxInitialized: bound.boxInitialized,
      boxMin: bound.box.min.toArray(),
      boxMax: bound.box.max.toArray(),
      sphereInitialized: bound.sphereInitialized,
      sphereRadius: bound.sphere.radius,
      sphereCenter: bound.sphere.center.toArray()
    }));
    object.maxGeometryCount = this._maxGeometryCount;
    object.maxVertexCount = this._maxVertexCount;
    object.maxIndexCount = this._maxIndexCount;
    object.geometryInitialized = this._geometryInitialized;
    object.geometryCount = this._geometryCount;
    object.matricesTexture = this._matricesTexture.toJSON(meta);
    if (this._colorsTexture !== null) object.colorsTexture = this._colorsTexture.toJSON(meta);
    if (this.boundingSphere !== null) {
      object.boundingSphere = {
        center: object.boundingSphere.center.toArray(),
        radius: object.boundingSphere.radius
      };
    }
    if (this.boundingBox !== null) {
      object.boundingBox = {
        min: object.boundingBox.min.toArray(),
        max: object.boundingBox.max.toArray()
      };
    }
  }

  //

  function serialize(library, element) {
    if (library[element.uuid] === undefined) {
      library[element.uuid] = element.toJSON(meta);
    }
    return element.uuid;
  }
  if (this.isScene) {
    if (this.background) {
      if (this.background.isColor) {
        object.background = this.background.toJSON();
      } else if (this.background.isTexture) {
        object.background = this.background.toJSON(meta).uuid;
      }
    }
    if (this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== true) {
      object.environment = this.environment.toJSON(meta).uuid;
    }
  } else if (this.isMesh || this.isLine || this.isPoints) {
    object.geometry = serialize(meta.geometries, this.geometry);
    const parameters = this.geometry.parameters;
    if (parameters !== undefined && parameters.shapes !== undefined) {
      const shapes = parameters.shapes;
      if (Array.isArray(shapes)) {
        for (let i = 0, l = shapes.length; i < l; i++) {
          const shape = shapes[i];
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
    if (this.skeleton !== undefined) {
      serialize(meta.skeletons, this.skeleton);
      object.skeleton = this.skeleton.uuid;
    }
  }
  if (this.material !== undefined) {
    if (Array.isArray(this.material)) {
      const uuids = [];
      for (let i = 0, l = this.material.length; i < l; i++) {
        uuids.push(serialize(meta.materials, this.material[i]));
      }
      object.material = uuids;
    } else {
      object.material = serialize(meta.materials, this.material);
    }
  }

  //

  if (this.children.length > 0) {
    object.children = [];
    for (let i = 0; i < this.children.length; i++) {
      object.children.push(this.children[i].toJSON(meta).object);
    }
  }

  //

  if (this.animations.length > 0) {
    object.animations = [];
    for (let i = 0; i < this.animations.length; i++) {
      const animation = this.animations[i];
      object.animations.push(serialize(meta.animations, animation));
    }
  }
  if (isRootObject) {
    const geometries = extractFromCache(meta.geometries);
    const materials = extractFromCache(meta.materials);
    const textures = extractFromCache(meta.textures);
    const images = extractFromCache(meta.images);
    const shapes = extractFromCache(meta.shapes);
    const skeletons = extractFromCache(meta.skeletons);
    const animations = extractFromCache(meta.animations);
    const nodes = extractFromCache(meta.nodes);
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

  // extract data from the cache hash
  // remove metadata on each item
  // and return as array
  function extractFromCache(cache) {
    const values = [];
    for (const key in cache) {
      const data = cache[key];
      delete data.metadata;
      values.push(data);
    }
    return values;
  }
}
toJSON(meta) {
  // meta is a string when called from JSON.stringify
  const isRootObject = meta === undefined || typeof meta === 'string';
  const output = {};

  // meta is a hash used to collect geometries, materials.
  // not providing it implies that this is the root object
  // being serialized.
  if (isRootObject) {
    // initialize meta obj
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

  // standard Object3D serialization

  const object = {};
  object.uuid = this.uuid;
  object.type = this.type;
  if (this.name !== '') object.name = this.name;
  if (this.castShadow === true) object.castShadow = true;
  if (this.receiveShadow === true) object.receiveShadow = true;
  if (this.visible === false) object.visible = false;
  if (this.frustumCulled === false) object.frustumCulled = false;
  if (this.renderOrder !== 0) object.renderOrder = this.renderOrder;
  if (Object.keys(this.userData).length > 0) object.userData = this.userData;
  object.layers = this.layers.mask;
  object.matrix = this.matrix.toArray();
  object.up = this.up.toArray();
  if (this.matrixAutoUpdate === false) object.matrixAutoUpdate = false;

  // object specific properties

  if (this.isInstancedMesh) {
    object.type = 'InstancedMesh';
    object.count = this.count;
    object.instanceMatrix = this.instanceMatrix.toJSON();
    if (this.instanceColor !== null) object.instanceColor = this.instanceColor.toJSON();
  }
  if (this.isBatchedMesh) {
    object.type = 'BatchedMesh';
    object.perObjectFrustumCulled = this.perObjectFrustumCulled;
    object.sortObjects = this.sortObjects;
    object.drawRanges = this._drawRanges;
    object.reservedRanges = this._reservedRanges;
    object.visibility = this._visibility;
    object.active = this._active;
    object.bounds = this._bounds.map(bound => ({
      boxInitialized: bound.boxInitialized,
      boxMin: bound.box.min.toArray(),
      boxMax: bound.box.max.toArray(),
      sphereInitialized: bound.sphereInitialized,
      sphereRadius: bound.sphere.radius,
      sphereCenter: bound.sphere.center.toArray()
    }));
    object.maxGeometryCount = this._maxGeometryCount;
    object.maxVertexCount = this._maxVertexCount;
    object.maxIndexCount = this._maxIndexCount;
    object.geometryInitialized = this._geometryInitialized;
    object.geometryCount = this._geometryCount;
    object.matricesTexture = this._matricesTexture.toJSON(meta);
    if (this._colorsTexture !== null) object.colorsTexture = this._colorsTexture.toJSON(meta);
    if (this.boundingSphere !== null) {
      object.boundingSphere = {
        center: object.boundingSphere.center.toArray(),
        radius: object.boundingSphere.radius
      };
    }
    if (this.boundingBox !== null) {
      object.boundingBox = {
        min: object.boundingBox.min.toArray(),
        max: object.boundingBox.max.toArray()
      };
    }
  }

  //

  function serialize(library, element) {
    if (library[element.uuid] === undefined) {
      library[element.uuid] = element.toJSON(meta);
    }
    return element.uuid;
  }
  if (this.isScene) {
    if (this.background) {
      if (this.background.isColor) {
        object.background = this.background.toJSON();
      } else if (this.background.isTexture) {
        object.background = this.background.toJSON(meta).uuid;
      }
    }
    if (this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== true) {
      object.environment = this.environment.toJSON(meta).uuid;
    }
  } else if (this.isMesh || this.isLine || this.isPoints) {
    object.geometry = serialize(meta.geometries, this.geometry);
    const parameters = this.geometry.parameters;
    if (parameters !== undefined && parameters.shapes !== undefined) {
      const shapes = parameters.shapes;
      if (Array.isArray(shapes)) {
        for (let i = 0, l = shapes.length; i < l; i++) {
          const shape = shapes[i];
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
    if (this.skeleton !== undefined) {
      serialize(meta.skeletons, this.skeleton);
      object.skeleton = this.skeleton.uuid;
    }
  }
  if (this.material !== undefined) {
    if (Array.isArray(this.material)) {
      const uuids = [];
      for (let i = 0, l = this.material.length; i < l; i++) {
        uuids.push(serialize(meta.materials, this.material[i]));
      }
      object.material = uuids;
    } else {
      object.material = serialize(meta.materials, this.material);
    }
  }

  //

  if (this.children.length > 0) {
    object.children = [];
    for (let i = 0; i < this.children.length; i++) {
      object.children.push(this.children[i].toJSON(meta).object);
    }
  }

  //

  if (this.animations.length > 0) {
    object.animations = [];
    for (let i = 0; i < this.animations.length; i++) {
      const animation = this.animations[i];
      object.animations.push(serialize(meta.animations, animation));
    }
  }
  if (isRootObject) {
    const geometries = extractFromCache(meta.geometries);
    const materials = extractFromCache(meta.materials);
    const textures = extractFromCache(meta.textures);
    const images = extractFromCache(meta.images);
    const shapes = extractFromCache(meta.shapes);
    const skeletons = extractFromCache(meta.skeletons);
    const animations = extractFromCache(meta.animations);
    const nodes = extractFromCache(meta.nodes);
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

  // extract data from the cache hash
  // remove metadata on each item
  // and return as array
  function extractFromCache(cache) {
    const values = [];
    for (const key in cache) {
      const data = cache[key];
      delete data.metadata;
      values.push(data);
    }
    return values;
  }
}
bound => ({
  boxInitialized: bound.boxInitialized,
  boxMin: bound.box.min.toArray(),
  boxMax: bound.box.max.toArray(),
  sphereInitialized: bound.sphereInitialized,
  sphereRadius: bound.sphere.radius,
  sphereCenter: bound.sphere.center.toArray()
})
bound
{
  boxInitialized: bound.boxInitialized,
  boxMin: bound.box.min.toArray(),
  boxMax: bound.box.max.toArray(),
  sphereInitialized: bound.sphereInitialized,
  sphereRadius: bound.sphere.radius,
  sphereCenter: bound.sphere.center.toArray()
}
boxInitialized: bound.boxInitialized
boxInitialized
bound.boxInitialized
bound
boxInitialized
boxMin: bound.box.min.toArray()
boxMin
bound.box.min.toArray()
bound.box.min.toArray
bound.box.min
bound.box
bound
box
min
toArray
boxMax: bound.box.max.toArray()
boxMax
bound.box.max.toArray()
bound.box.max.toArray
bound.box.max
bound.box
bound
box
max
toArray
sphereInitialized: bound.sphereInitialized
sphereInitialized
bound.sphereInitialized
bound
sphereInitialized
sphereRadius: bound.sphere.radius
sphereRadius
bound.sphere.radius
bound.sphere
bound
sphere
radius
sphereCenter: bound.sphere.center.toArray()
sphereCenter
bound.sphere.center.toArray()
bound.sphere.center.toArray
bound.sphere.center
bound.sphere
bound
sphere
center
toArray
object.maxGeometryCount = this._maxGeometryCount;
object.maxGeometryCount = this._maxGeometryCount
object.maxGeometryCount
object
maxGeometryCount
this._maxGeometryCount
this
_maxGeometryCount
object.maxVertexCount = this._maxVertexCount;
object.maxVertexCount = this._maxVertexCount
object.maxVertexCount
object
maxVertexCount
this._maxVertexCount
this
_maxVertexCount
object.maxIndexCount = this._maxIndexCount;
object.maxIndexCount = this._maxIndexCount
object.maxIndexCount
object
maxIndexCount
this._maxIndexCount
this
_maxIndexCount
object.geometryInitialized = this._geometryInitialized;
object.geometryInitialized = this._geometryInitialized
object.geometryInitialized
object
geometryInitialized
this._geometryInitialized
this
_geometryInitialized
object.geometryCount = this._geometryCount;
object.geometryCount = this._geometryCount
object.geometryCount
object
geometryCount
this._geometryCount
this
_geometryCount
object.matricesTexture = this._matricesTexture.toJSON(meta);
object.matricesTexture = this._matricesTexture.toJSON(meta)
object.matricesTexture
object
matricesTexture
this._matricesTexture.toJSON(meta)
this._matricesTexture.toJSON
this._matricesTexture
this
_matricesTexture
toJSON
meta
if (this._colorsTexture !== null) object.colorsTexture = this._colorsTexture.toJSON(meta);
this._colorsTexture !== null
this._colorsTexture
this
_colorsTexture
null
object.colorsTexture = this._colorsTexture.toJSON(meta);
object.colorsTexture = this._colorsTexture.toJSON(meta)
object.colorsTexture
object
colorsTexture
this._colorsTexture.toJSON(meta)
this._colorsTexture.toJSON
this._colorsTexture
this
_colorsTexture
toJSON
meta
if (this.boundingSphere !== null) {
  object.boundingSphere = {
    center: object.boundingSphere.center.toArray(),
    radius: object.boundingSphere.radius
  };
}
this.boundingSphere !== null
this.boundingSphere
this
boundingSphere
null
{
  object.boundingSphere = {
    center: object.boundingSphere.center.toArray(),
    radius: object.boundingSphere.radius
  };
}
object.boundingSphere = {
  center: object.boundingSphere.center.toArray(),
  radius: object.boundingSphere.radius
};
object.boundingSphere = {
  center: object.boundingSphere.center.toArray(),
  radius: object.boundingSphere.radius
}
object.boundingSphere
object
boundingSphere
{
  center: object.boundingSphere.center.toArray(),
  radius: object.boundingSphere.radius
}
center: object.boundingSphere.center.toArray()
center
object.boundingSphere.center.toArray()
object.boundingSphere.center.toArray
object.boundingSphere.center
object.boundingSphere
object
boundingSphere
center
toArray
radius: object.boundingSphere.radius
radius
object.boundingSphere.radius
object.boundingSphere
object
boundingSphere
radius
if (this.boundingBox !== null) {
  object.boundingBox = {
    min: object.boundingBox.min.toArray(),
    max: object.boundingBox.max.toArray()
  };
}
this.boundingBox !== null
this.boundingBox
this
boundingBox
null
{
  object.boundingBox = {
    min: object.boundingBox.min.toArray(),
    max: object.boundingBox.max.toArray()
  };
}
object.boundingBox = {
  min: object.boundingBox.min.toArray(),
  max: object.boundingBox.max.toArray()
};
object.boundingBox = {
  min: object.boundingBox.min.toArray(),
  max: object.boundingBox.max.toArray()
}
object.boundingBox
object
boundingBox
{
  min: object.boundingBox.min.toArray(),
  max: object.boundingBox.max.toArray()
}
min: object.boundingBox.min.toArray()
min
object.boundingBox.min.toArray()
object.boundingBox.min.toArray
object.boundingBox.min
object.boundingBox
object
boundingBox
min
toArray
max: object.boundingBox.max.toArray()
max
object.boundingBox.max.toArray()
object.boundingBox.max.toArray
object.boundingBox.max
object.boundingBox
object
boundingBox
max
toArray
//

function serialize(library, element) {
  if (library[element.uuid] === undefined) {
    library[element.uuid] = element.toJSON(meta);
  }
  return element.uuid;
}
//

function serialize(library, element) {
  if (library[element.uuid] === undefined) {
    library[element.uuid] = element.toJSON(meta);
  }
  return element.uuid;
}
serialize
library
element
{
  if (library[element.uuid] === undefined) {
    library[element.uuid] = element.toJSON(meta);
  }
  return element.uuid;
}
if (library[element.uuid] === undefined) {
  library[element.uuid] = element.toJSON(meta);
}
library[element.uuid] === undefined
library[element.uuid]
library
element.uuid
element
uuid
undefined
{
  library[element.uuid] = element.toJSON(meta);
}
library[element.uuid] = element.toJSON(meta);
library[element.uuid] = element.toJSON(meta)
library[element.uuid]
library
element.uuid
element
uuid
element.toJSON(meta)
element.toJSON
element
toJSON
meta
return element.uuid;
element.uuid
element
uuid
if (this.isScene) {
  if (this.background) {
    if (this.background.isColor) {
      object.background = this.background.toJSON();
    } else if (this.background.isTexture) {
      object.background = this.background.toJSON(meta).uuid;
    }
  }
  if (this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== true) {
    object.environment = this.environment.toJSON(meta).uuid;
  }
} else if (this.isMesh || this.isLine || this.isPoints) {
  object.geometry = serialize(meta.geometries, this.geometry);
  const parameters = this.geometry.parameters;
  if (parameters !== undefined && parameters.shapes !== undefined) {
    const shapes = parameters.shapes;
    if (Array.isArray(shapes)) {
      for (let i = 0, l = shapes.length; i < l; i++) {
        const shape = shapes[i];
        serialize(meta.shapes, shape);
      }
    } else {
      serialize(meta.shapes, shapes);
    }
  }
}
this.isScene
this
isScene
{
  if (this.background) {
    if (this.background.isColor) {
      object.background = this.background.toJSON();
    } else if (this.background.isTexture) {
      object.background = this.background.toJSON(meta).uuid;
    }
  }
  if (this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== true) {
    object.environment = this.environment.toJSON(meta).uuid;
  }
}
if (this.background) {
  if (this.background.isColor) {
    object.background = this.background.toJSON();
  } else if (this.background.isTexture) {
    object.background = this.background.toJSON(meta).uuid;
  }
}
this.background
this
background
{
  if (this.background.isColor) {
    object.background = this.background.toJSON();
  } else if (this.background.isTexture) {
    object.background = this.background.toJSON(meta).uuid;
  }
}
if (this.background.isColor) {
  object.background = this.background.toJSON();
} else if (this.background.isTexture) {
  object.background = this.background.toJSON(meta).uuid;
}
this.background.isColor
this.background
this
background
isColor
{
  object.background = this.background.toJSON();
}
object.background = this.background.toJSON();
object.background = this.background.toJSON()
object.background
object
background
this.background.toJSON()
this.background.toJSON
this.background
this
background
toJSON
if (this.background.isTexture) {
  object.background = this.background.toJSON(meta).uuid;
}
this.background.isTexture
this.background
this
background
isTexture
{
  object.background = this.background.toJSON(meta).uuid;
}
object.background = this.background.toJSON(meta).uuid;
object.background = this.background.toJSON(meta).uuid
object.background
object
background
this.background.toJSON(meta).uuid
this.background.toJSON(meta)
this.background.toJSON
this.background
this
background
toJSON
meta
uuid
if (this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== true) {
  object.environment = this.environment.toJSON(meta).uuid;
}
this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== true
this.environment && this.environment.isTexture
this.environment
this
environment
this.environment.isTexture
this.environment
this
environment
isTexture
this.environment.isRenderTargetTexture !== true
this.environment.isRenderTargetTexture
this.environment
this
environment
isRenderTargetTexture
true
{
  object.environment = this.environment.toJSON(meta).uuid;
}
object.environment = this.environment.toJSON(meta).uuid;
object.environment = this.environment.toJSON(meta).uuid
object.environment
object
environment
this.environment.toJSON(meta).uuid
this.environment.toJSON(meta)
this.environment.toJSON
this.environment
this
environment
toJSON
meta
uuid
if (this.isMesh || this.isLine || this.isPoints) {
  object.geometry = serialize(meta.geometries, this.geometry);
  const parameters = this.geometry.parameters;
  if (parameters !== undefined && parameters.shapes !== undefined) {
    const shapes = parameters.shapes;
    if (Array.isArray(shapes)) {
      for (let i = 0, l = shapes.length; i < l; i++) {
        const shape = shapes[i];
        serialize(meta.shapes, shape);
      }
    } else {
      serialize(meta.shapes, shapes);
    }
  }
}
this.isMesh || this.isLine || this.isPoints
this.isMesh || this.isLine
this.isMesh
this
isMesh
this.isLine
this
isLine
this.isPoints
this
isPoints
{
  object.geometry = serialize(meta.geometries, this.geometry);
  const parameters = this.geometry.parameters;
  if (parameters !== undefined && parameters.shapes !== undefined) {
    const shapes = parameters.shapes;
    if (Array.isArray(shapes)) {
      for (let i = 0, l = shapes.length; i < l; i++) {
        const shape = shapes[i];
        serialize(meta.shapes, shape);
      }
    } else {
      serialize(meta.shapes, shapes);
    }
  }
}
object.geometry = serialize(meta.geometries, this.geometry);
object.geometry = serialize(meta.geometries, this.geometry)
object.geometry
object
geometry
serialize(meta.geometries, this.geometry)
serialize
meta.geometries
meta
geometries
this.geometry
this
geometry
const parameters = this.geometry.parameters;
parameters = this.geometry.parameters
parameters
this.geometry.parameters
this.geometry
this
geometry
parameters
if (parameters !== undefined && parameters.shapes !== undefined) {
  const shapes = parameters.shapes;
  if (Array.isArray(shapes)) {
    for (let i = 0, l = shapes.length; i < l; i++) {
      const shape = shapes[i];
      serialize(meta.shapes, shape);
    }
  } else {
    serialize(meta.shapes, shapes);
  }
}
parameters !== undefined && parameters.shapes !== undefined
parameters !== undefined
parameters
undefined
parameters.shapes !== undefined
parameters.shapes
parameters
shapes
undefined
{
  const shapes = parameters.shapes;
  if (Array.isArray(shapes)) {
    for (let i = 0, l = shapes.length; i < l; i++) {
      const shape = shapes[i];
      serialize(meta.shapes, shape);
    }
  } else {
    serialize(meta.shapes, shapes);
  }
}
const shapes = parameters.shapes;
shapes = parameters.shapes
shapes
parameters.shapes
parameters
shapes
if (Array.isArray(shapes)) {
  for (let i = 0, l = shapes.length; i < l; i++) {
    const shape = shapes[i];
    serialize(meta.shapes, shape);
  }
} else {
  serialize(meta.shapes, shapes);
}
Array.isArray(shapes)
Array.isArray
Array
isArray
shapes
{
  for (let i = 0, l = shapes.length; i < l; i++) {
    const shape = shapes[i];
    serialize(meta.shapes, shape);
  }
}
for (let i = 0, l = shapes.length; i < l; i++) {
  const shape = shapes[i];
  serialize(meta.shapes, shape);
}
let i = 0,
  l = shapes.length;
i = 0
i
0
l = shapes.length
l
shapes.length
shapes
length
i < l
i
l
i++
i
{
  const shape = shapes[i];
  serialize(meta.shapes, shape);
}
const shape = shapes[i];
shape = shapes[i]
shape
shapes[i]
shapes
i
serialize(meta.shapes, shape);
serialize(meta.shapes, shape)
serialize
meta.shapes
meta
shapes
shape
{
  serialize(meta.shapes, shapes);
}
serialize(meta.shapes, shapes);
serialize(meta.shapes, shapes)
serialize
meta.shapes
meta
shapes
shapes
if (this.isSkinnedMesh) {
  object.bindMode = this.bindMode;
  object.bindMatrix = this.bindMatrix.toArray();
  if (this.skeleton !== undefined) {
    serialize(meta.skeletons, this.skeleton);
    object.skeleton = this.skeleton.uuid;
  }
}
this.isSkinnedMesh
this
isSkinnedMesh
{
  object.bindMode = this.bindMode;
  object.bindMatrix = this.bindMatrix.toArray();
  if (this.skeleton !== undefined) {
    serialize(meta.skeletons, this.skeleton);
    object.skeleton = this.skeleton.uuid;
  }
}
object.bindMode = this.bindMode;
object.bindMode = this.bindMode
object.bindMode
object
bindMode
this.bindMode
this
bindMode
object.bindMatrix = this.bindMatrix.toArray();
object.bindMatrix = this.bindMatrix.toArray()
object.bindMatrix
object
bindMatrix
this.bindMatrix.toArray()
this.bindMatrix.toArray
this.bindMatrix
this
bindMatrix
toArray
if (this.skeleton !== undefined) {
  serialize(meta.skeletons, this.skeleton);
  object.skeleton = this.skeleton.uuid;
}
this.skeleton !== undefined
this.skeleton
this
skeleton
undefined
{
  serialize(meta.skeletons, this.skeleton);
  object.skeleton = this.skeleton.uuid;
}
serialize(meta.skeletons, this.skeleton);
serialize(meta.skeletons, this.skeleton)
serialize
meta.skeletons
meta
skeletons
this.skeleton
this
skeleton
object.skeleton = this.skeleton.uuid;
object.skeleton = this.skeleton.uuid
object.skeleton
object
skeleton
this.skeleton.uuid
this.skeleton
this
skeleton
uuid
if (this.material !== undefined) {
  if (Array.isArray(this.material)) {
    const uuids = [];
    for (let i = 0, l = this.material.length; i < l; i++) {
      uuids.push(serialize(meta.materials, this.material[i]));
    }
    object.material = uuids;
  } else {
    object.material = serialize(meta.materials, this.material);
  }
}

//
this.material !== undefined
this.material
this
material
undefined
{
  if (Array.isArray(this.material)) {
    const uuids = [];
    for (let i = 0, l = this.material.length; i < l; i++) {
      uuids.push(serialize(meta.materials, this.material[i]));
    }
    object.material = uuids;
  } else {
    object.material = serialize(meta.materials, this.material);
  }
}
if (Array.isArray(this.material)) {
  const uuids = [];
  for (let i = 0, l = this.material.length; i < l; i++) {
    uuids.push(serialize(meta.materials, this.material[i]));
  }
  object.material = uuids;
} else {
  object.material = serialize(meta.materials, this.material);
}
Array.isArray(this.material)
Array.isArray
Array
isArray
this.material
this
material
{
  const uuids = [];
  for (let i = 0, l = this.material.length; i < l; i++) {
    uuids.push(serialize(meta.materials, this.material[i]));
  }
  object.material = uuids;
}
const uuids = [];
uuids = []
uuids
[]
for (let i = 0, l = this.material.length; i < l; i++) {
  uuids.push(serialize(meta.materials, this.material[i]));
}
let i = 0,
  l = this.material.length;
i = 0
i
0
l = this.material.length
l
this.material.length
this.material
this
material
length
i < l
i
l
i++
i
{
  uuids.push(serialize(meta.materials, this.material[i]));
}
uuids.push(serialize(meta.materials, this.material[i]));
uuids.push(serialize(meta.materials, this.material[i]))
uuids.push
uuids
push
serialize(meta.materials, this.material[i])
serialize
meta.materials
meta
materials
this.material[i]
this.material
this
material
i
object.material = uuids;
object.material = uuids
object.material
object
material
uuids
{
  object.material = serialize(meta.materials, this.material);
}
object.material = serialize(meta.materials, this.material);
object.material = serialize(meta.materials, this.material)
object.material
object
material
serialize(meta.materials, this.material)
serialize
meta.materials
meta
materials
this.material
this
material
//

if (this.children.length > 0) {
  object.children = [];
  for (let i = 0; i < this.children.length; i++) {
    object.children.push(this.children[i].toJSON(meta).object);
  }
}

//
this.children.length > 0
this.children.length
this.children
this
children
length
0
{
  object.children = [];
  for (let i = 0; i < this.children.length; i++) {
    object.children.push(this.children[i].toJSON(meta).object);
  }
}
object.children = [];
object.children = []
object.children
object
children
[]
for (let i = 0; i < this.children.length; i++) {
  object.children.push(this.children[i].toJSON(meta).object);
}
let i = 0;
i = 0
i
0
i < this.children.length
i
this.children.length
this.children
this
children
length
i++
i
{
  object.children.push(this.children[i].toJSON(meta).object);
}
object.children.push(this.children[i].toJSON(meta).object);
object.children.push(this.children[i].toJSON(meta).object)
object.children.push
object.children
object
children
push
this.children[i].toJSON(meta).object
this.children[i].toJSON(meta)
this.children[i].toJSON
this.children[i]
this.children
this
children
i
toJSON
meta
object
//

if (this.animations.length > 0) {
  object.animations = [];
  for (let i = 0; i < this.animations.length; i++) {
    const animation = this.animations[i];
    object.animations.push(serialize(meta.animations, animation));
  }
}
this.animations.length > 0
this.animations.length
this.animations
this
animations
length
0
{
  object.animations = [];
  for (let i = 0; i < this.animations.length; i++) {
    const animation = this.animations[i];
    object.animations.push(serialize(meta.animations, animation));
  }
}
object.animations = [];
object.animations = []
object.animations
object
animations
[]
for (let i = 0; i < this.animations.length; i++) {
  const animation = this.animations[i];
  object.animations.push(serialize(meta.animations, animation));
}
let i = 0;
i = 0
i
0
i < this.animations.length
i
this.animations.length
this.animations
this
animations
length
i++
i
{
  const animation = this.animations[i];
  object.animations.push(serialize(meta.animations, animation));
}
const animation = this.animations[i];
animation = this.animations[i]
animation
this.animations[i]
this.animations
this
animations
i
object.animations.push(serialize(meta.animations, animation));
object.animations.push(serialize(meta.animations, animation))
object.animations.push
object.animations
object
animations
push
serialize(meta.animations, animation)
serialize
meta.animations
meta
animations
animation
if (isRootObject) {
  const geometries = extractFromCache(meta.geometries);
  const materials = extractFromCache(meta.materials);
  const textures = extractFromCache(meta.textures);
  const images = extractFromCache(meta.images);
  const shapes = extractFromCache(meta.shapes);
  const skeletons = extractFromCache(meta.skeletons);
  const animations = extractFromCache(meta.animations);
  const nodes = extractFromCache(meta.nodes);
  if (geometries.length > 0) output.geometries = geometries;
  if (materials.length > 0) output.materials = materials;
  if (textures.length > 0) output.textures = textures;
  if (images.length > 0) output.images = images;
  if (shapes.length > 0) output.shapes = shapes;
  if (skeletons.length > 0) output.skeletons = skeletons;
  if (animations.length > 0) output.animations = animations;
  if (nodes.length > 0) output.nodes = nodes;
}
isRootObject
{
  const geometries = extractFromCache(meta.geometries);
  const materials = extractFromCache(meta.materials);
  const textures = extractFromCache(meta.textures);
  const images = extractFromCache(meta.images);
  const shapes = extractFromCache(meta.shapes);
  const skeletons = extractFromCache(meta.skeletons);
  const animations = extractFromCache(meta.animations);
  const nodes = extractFromCache(meta.nodes);
  if (geometries.length > 0) output.geometries = geometries;
  if (materials.length > 0) output.materials = materials;
  if (textures.length > 0) output.textures = textures;
  if (images.length > 0) output.images = images;
  if (shapes.length > 0) output.shapes = shapes;
  if (skeletons.length > 0) output.skeletons = skeletons;
  if (animations.length > 0) output.animations = animations;
  if (nodes.length > 0) output.nodes = nodes;
}
const geometries = extractFromCache(meta.geometries);
geometries = extractFromCache(meta.geometries)
geometries
extractFromCache(meta.geometries)
extractFromCache
meta.geometries
meta
geometries
const materials = extractFromCache(meta.materials);
materials = extractFromCache(meta.materials)
materials
extractFromCache(meta.materials)
extractFromCache
meta.materials
meta
materials
const textures = extractFromCache(meta.textures);
textures = extractFromCache(meta.textures)
textures
extractFromCache(meta.textures)
extractFromCache
meta.textures
meta
textures
const images = extractFromCache(meta.images);
images = extractFromCache(meta.images)
images
extractFromCache(meta.images)
extractFromCache
meta.images
meta
images
const shapes = extractFromCache(meta.shapes);
shapes = extractFromCache(meta.shapes)
shapes
extractFromCache(meta.shapes)
extractFromCache
meta.shapes
meta
shapes
const skeletons = extractFromCache(meta.skeletons);
skeletons = extractFromCache(meta.skeletons)
skeletons
extractFromCache(meta.skeletons)
extractFromCache
meta.skeletons
meta
skeletons
const animations = extractFromCache(meta.animations);
animations = extractFromCache(meta.animations)
animations
extractFromCache(meta.animations)
extractFromCache
meta.animations
meta
animations
const nodes = extractFromCache(meta.nodes);
nodes = extractFromCache(meta.nodes)
nodes
extractFromCache(meta.nodes)
extractFromCache
meta.nodes
meta
nodes
if (geometries.length > 0) output.geometries = geometries;
geometries.length > 0
geometries.length
geometries
length
0
output.geometries = geometries;
output.geometries = geometries
output.geometries
output
geometries
geometries
if (materials.length > 0) output.materials = materials;
materials.length > 0
materials.length
materials
length
0
output.materials = materials;
output.materials = materials
output.materials
output
materials
materials
if (textures.length > 0) output.textures = textures;
textures.length > 0
textures.length
textures
length
0
output.textures = textures;
output.textures = textures
output.textures
output
textures
textures
if (images.length > 0) output.images = images;
images.length > 0
images.length
images
length
0
output.images = images;
output.images = images
output.images
output
images
images
if (shapes.length > 0) output.shapes = shapes;
shapes.length > 0
shapes.length
shapes
length
0
output.shapes = shapes;
output.shapes = shapes
output.shapes
output
shapes
shapes
if (skeletons.length > 0) output.skeletons = skeletons;
skeletons.length > 0
skeletons.length
skeletons
length
0
output.skeletons = skeletons;
output.skeletons = skeletons
output.skeletons
output
skeletons
skeletons
if (animations.length > 0) output.animations = animations;
animations.length > 0
animations.length
animations
length
0
output.animations = animations;
output.animations = animations
output.animations
output
animations
animations
if (nodes.length > 0) output.nodes = nodes;
nodes.length > 0
nodes.length
nodes
length
0
output.nodes = nodes;
output.nodes = nodes
output.nodes
output
nodes
nodes
output.object = object;
output.object = object
output.object
output
object
object
return output;

// extract data from the cache hash
// remove metadata on each item
// and return as array
output
// extract data from the cache hash
// remove metadata on each item
// and return as array
function extractFromCache(cache) {
  const values = [];
  for (const key in cache) {
    const data = cache[key];
    delete data.metadata;
    values.push(data);
  }
  return values;
}
// extract data from the cache hash
// remove metadata on each item
// and return as array
function extractFromCache(cache) {
  const values = [];
  for (const key in cache) {
    const data = cache[key];
    delete data.metadata;
    values.push(data);
  }
  return values;
}
extractFromCache
cache
{
  const values = [];
  for (const key in cache) {
    const data = cache[key];
    delete data.metadata;
    values.push(data);
  }
  return values;
}
const values = [];
values = []
values
[]
for (const key in cache) {
  const data = cache[key];
  delete data.metadata;
  values.push(data);
}
const key;
key
key
cache
{
  const data = cache[key];
  delete data.metadata;
  values.push(data);
}
const data = cache[key];
data = cache[key]
data
cache[key]
cache
key
delete data.metadata;
delete data.metadata
data.metadata
data
metadata
values.push(data);
values.push(data)
values.push
values
push
data
return values;
values
clone(recursive) {
  return new this.constructor().copy(this, recursive);
}
toJSON
meta
{
  // meta is a string when called from JSON.stringify
  const isRootObject = meta === undefined || typeof meta === 'string';
  const output = {};

  // meta is a hash used to collect geometries, materials.
  // not providing it implies that this is the root object
  // being serialized.
  if (isRootObject) {
    // initialize meta obj
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

  // standard Object3D serialization

  const object = {};
  object.uuid = this.uuid;
  object.type = this.type;
  if (this.name !== '') object.name = this.name;
  if (this.castShadow === true) object.castShadow = true;
  if (this.receiveShadow === true) object.receiveShadow = true;
  if (this.visible === false) object.visible = false;
  if (this.frustumCulled === false) object.frustumCulled = false;
  if (this.renderOrder !== 0) object.renderOrder = this.renderOrder;
  if (Object.keys(this.userData).length > 0) object.userData = this.userData;
  object.layers = this.layers.mask;
  object.matrix = this.matrix.toArray();
  object.up = this.up.toArray();
  if (this.matrixAutoUpdate === false) object.matrixAutoUpdate = false;

  // object specific properties

  if (this.isInstancedMesh) {
    object.type = 'InstancedMesh';
    object.count = this.count;
    object.instanceMatrix = this.instanceMatrix.toJSON();
    if (this.instanceColor !== null) object.instanceColor = this.instanceColor.toJSON();
  }
  if (this.isBatchedMesh) {
    object.type = 'BatchedMesh';
    object.perObjectFrustumCulled = this.perObjectFrustumCulled;
    object.sortObjects = this.sortObjects;
    object.drawRanges = this._drawRanges;
    object.reservedRanges = this._reservedRanges;
    object.visibility = this._visibility;
    object.active = this._active;
    object.bounds = this._bounds.map(bound => ({
      boxInitialized: bound.boxInitialized,
      boxMin: bound.box.min.toArray(),
      boxMax: bound.box.max.toArray(),
      sphereInitialized: bound.sphereInitialized,
      sphereRadius: bound.sphere.radius,
      sphereCenter: bound.sphere.center.toArray()
    }));
    object.maxGeometryCount = this._maxGeometryCount;
    object.maxVertexCount = this._maxVertexCount;
    object.maxIndexCount = this._maxIndexCount;
    object.geometryInitialized = this._geometryInitialized;
    object.geometryCount = this._geometryCount;
    object.matricesTexture = this._matricesTexture.toJSON(meta);
    if (this._colorsTexture !== null) object.colorsTexture = this._colorsTexture.toJSON(meta);
    if (this.boundingSphere !== null) {
      object.boundingSphere = {
        center: object.boundingSphere.center.toArray(),
        radius: object.boundingSphere.radius
      };
    }
    if (this.boundingBox !== null) {
      object.boundingBox = {
        min: object.boundingBox.min.toArray(),
        max: object.boundingBox.max.toArray()
      };
    }
  }

  //

  function serialize(library, element) {
    if (library[element.uuid] === undefined) {
      library[element.uuid] = element.toJSON(meta);
    }
    return element.uuid;
  }
  if (this.isScene) {
    if (this.background) {
      if (this.background.isColor) {
        object.background = this.background.toJSON();
      } else if (this.background.isTexture) {
        object.background = this.background.toJSON(meta).uuid;
      }
    }
    if (this.environment && this.environment.isTexture && this.environment.isRenderTargetTexture !== true) {
      object.environment = this.environment.toJSON(meta).uuid;
    }
  } else if (this.isMesh || this.isLine || this.isPoints) {
    object.geometry = serialize(meta.geometries, this.geometry);
    const parameters = this.geometry.parameters;
    if (parameters !== undefined && parameters.shapes !== undefined) {
      const shapes = parameters.shapes;
      if (Array.isArray(shapes)) {
        for (let i = 0, l = shapes.length; i < l; i++) {
          const shape = shapes[i];
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
    if (this.skeleton !== undefined) {
      serialize(meta.skeletons, this.skeleton);
      object.skeleton = this.skeleton.uuid;
    }
  }
  if (this.material !== undefined) {
    if (Array.isArray(this.material)) {
      const uuids = [];
      for (let i = 0, l = this.material.length; i < l; i++) {
        uuids.push(serialize(meta.materials, this.material[i]));
      }
      object.material = uuids;
    } else {
      object.material = serialize(meta.materials, this.material);
    }
  }

  //

  if (this.children.length > 0) {
    object.children = [];
    for (let i = 0; i < this.children.length; i++) {
      object.children.push(this.children[i].toJSON(meta).object);
    }
  }

  //

  if (this.animations.length > 0) {
    object.animations = [];
    for (let i = 0; i < this.animations.length; i++) {
      const animation = this.animations[i];
      object.animations.push(serialize(meta.animations, animation));
    }
  }
  if (isRootObject) {
    const geometries = extractFromCache(meta.geometries);
    const materials = extractFromCache(meta.materials);
    const textures = extractFromCache(meta.textures);
    const images = extractFromCache(meta.images);
    const shapes = extractFromCache(meta.shapes);
    const skeletons = extractFromCache(meta.skeletons);
    const animations = extractFromCache(meta.animations);
    const nodes = extractFromCache(meta.nodes);
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

  // extract data from the cache hash
  // remove metadata on each item
  // and return as array
  function extractFromCache(cache) {
    const values = [];
    for (const key in cache) {
      const data = cache[key];
      delete data.metadata;
      values.push(data);
    }
    return values;
  }
}
// meta is a string when called from JSON.stringify
const isRootObject = meta === undefined || typeof meta === 'string';
isRootObject = meta === undefined || typeof meta === 'string'
isRootObject
meta === undefined || typeof meta === 'string'
meta === undefined
meta
undefined
typeof meta === 'string'
typeof meta
meta
'string'
const output = {};

// meta is a hash used to collect geometries, materials.
// not providing it implies that this is the root object
// being serialized.
output = {}
output
{}
// meta is a hash used to collect geometries, materials.
// not providing it implies that this is the root object
// being serialized.
if (isRootObject) {
  // initialize meta obj
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

// standard Object3D serialization
isRootObject
{
  // initialize meta obj
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
// initialize meta obj
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
meta = {
  geometries: {},
  materials: {},
  textures: {},
  images: {},
  shapes: {},
  skeletons: {},
  animations: {},
  nodes: {}
}
meta
{
  geometries: {},
  materials: {},
  textures: {},
  images: {},
  shapes: {},
  skeletons: {},
  animations: {},
  nodes: {}
}
geometries: {}
geometries
{}
materials: {}
materials
{}
textures: {}
textures
{}
images: {}
images
{}
shapes: {}
shapes
{}
skeletons: {}
skeletons
{}
animations: {}
animations
{}
nodes: {}
nodes
{}
output.metadata = {
  version: 4.6,
  type: 'Object',
  generator: 'Object3D.toJSON'
};
output.metadata = {
  version: 4.6,
  type: 'Object',
  generator: 'Object3D.toJSON'
}
output.metadata
output
metadata
{
  version: 4.6,
  type: 'Object',
  generator: 'Object3D.toJSON'
}
version: 4.6
version
4.6
type: 'Object'
type
'Object'
generator: 'Object3D.toJSON'
generator
'Object3D.toJSON'
// standard Object3D serialization

const object = {};
object = {}
object
{}
object.uuid = this.uuid;
object.uuid = this.uuid
object.uuid
object
uuid
this.uuid
this
uuid
object.type = this.type;
object.type = this.type
object.type
object
type
this.type
this
type
if (this.name !== '') object.name = this.name;
this.name !== ''
this.name
this
name
''
object.name = this.name;
object.name = this.name
object.name
object
name
this.name
this
name
if (this.castShadow === true) object.castShadow = true;
this.castShadow === true
this.castShadow
this
castShadow
true
object.castShadow = true;
object.castShadow = true
object.castShadow
object
castShadow
true
if (this.receiveShadow === true) object.receiveShadow = true;
this.receiveShadow === true
this.receiveShadow
this
receiveShadow
true
object.receiveShadow = true;
object.receiveShadow = true
object.receiveShadow
object
receiveShadow
true
if (this.visible === false) object.visible = false;
this.visible === false
this.visible
this
visible
false
object.visible = false;
object.visible = false
object.visible
object
visible
false
if (this.frustumCulled === false) object.frustumCulled = false;
this.frustumCulled === false
this.frustumCulled
this
frustumCulled
false
object.frustumCulled = false;
object.frustumCulled = false
object.frustumCulled
object
frustumCulled
false
if (this.renderOrder !== 0) object.renderOrder = this.renderOrder;
this.renderOrder !== 0
this.renderOrder
this
renderOrder
0
object.renderOrder = this.renderOrder;
object.renderOrder = this.renderOrder
object.renderOrder
object
renderOrder
this.renderOrder
this
renderOrder
if (Object.keys(this.userData).length > 0) object.userData = this.userData;
Object.keys(this.userData).length > 0
Object.keys(this.userData).length
Object.keys(this.userData)
Object.keys
Object
keys
this.userData
this
userData
length
0
object.userData = this.userData;
object.userData = this.userData
object.userData
object
userData
this.userData
this
userData
object.layers = this.layers.mask;
object.layers = this.layers.mask
object.layers
object
layers
this.layers.mask
this.layers
this
layers
mask
object.matrix = this.matrix.toArray();
object.matrix = this.matrix.toArray()
object.matrix
object
matrix
this.matrix.toArray()
this.matrix.toArray
this.matrix
this
matrix
toArray
object.up = this.up.toArray();
object.up = this.up.toArray()
object.up
object
up
this.up.toArray()
this.up.toArray
this.up
this
up
toArray
if (this.matrixAutoUpdate === false) object.matrixAutoUpdate = false;

// object specific properties
this.matrixAutoUpdate === false
this.matrixAutoUpdate
this
matrixAutoUpdate
false
object.matrixAutoUpdate = false;
object.matrixAutoUpdate = false
object.matrixAutoUpdate
object
matrixAutoUpdate
false
// object specific properties

if (this.isInstancedMesh) {
  object.type = 'InstancedMesh';
  object.count = this.count;
  object.instanceMatrix = this.instanceMatrix.toJSON();
  if (this.instanceColor !== null) object.instanceColor = this.instanceColor.toJSON();
}
this.isInstancedMesh
this
isInstancedMesh
{
  object.type = 'InstancedMesh';
  object.count = this.count;
  object.instanceMatrix = this.instanceMatrix.toJSON();
  if (this.instanceColor !== null) object.instanceColor = this.instanceColor.toJSON();
}
object.type = 'InstancedMesh';
object.type = 'InstancedMesh'
object.type
object
type
'InstancedMesh'
object.count = this.count;
object.count = this.count
object.count
object
count
this.count
this
count
object.instanceMatrix = this.instanceMatrix.toJSON();
object.instanceMatrix = this.instanceMatrix.toJSON()
object.instanceMatrix
object
instanceMatrix
this.instanceMatrix.toJSON()
this.instanceMatrix.toJSON
this.instanceMatrix
this
instanceMatrix
toJSON
if (this.instanceColor !== null) object.instanceColor = this.instanceColor.toJSON();
this.instanceColor !== null
this.instanceColor
this
instanceColor
null
object.instanceColor = this.instanceColor.toJSON();
object.instanceColor = this.instanceColor.toJSON()
object.instanceColor
object
instanceColor
this.instanceColor.toJSON()
this.instanceColor.toJSON
this.instanceColor
this
instanceColor
toJSON
if (this.isBatchedMesh) {
  object.type = 'BatchedMesh';
  object.perObjectFrustumCulled = this.perObjectFrustumCulled;
  object.sortObjects = this.sortObjects;
  object.drawRanges = this._drawRanges;
  object.reservedRanges = this._reservedRanges;
  object.visibility = this._visibility;
  object.active = this._active;
  object.bounds = this._bounds.map(bound => ({
    boxInitialized: bound.boxInitialized,
    boxMin: bound.box.min.toArray(),
    boxMax: bound.box.max.toArray(),
    sphereInitialized: bound.sphereInitialized,
    sphereRadius: bound.sphere.radius,
    sphereCenter: bound.sphere.center.toArray()
  }));
  object.maxGeometryCount = this._maxGeometryCount;
  object.maxVertexCount = this._maxVertexCount;
  object.maxIndexCount = this._maxIndexCount;
  object.geometryInitialized = this._geometryInitialized;
  object.geometryCount = this._geometryCount;
  object.matricesTexture = this._matricesTexture.toJSON(meta);
  if (this._colorsTexture !== null) object.colorsTexture = this._colorsTexture.toJSON(meta);
  if (this.boundingSphere !== null) {
    object.boundingSphere = {
      center: object.boundingSphere.center.toArray(),
      radius: object.boundingSphere.radius
    };
  }
  if (this.boundingBox !== null) {
    object.boundingBox = {
      min: object.boundingBox.min.toArray(),
      max: object.boundingBox.max.toArray()
    };
  }
}

//
this.isBatchedMesh
this
isBatchedMesh
{
  object.type = 'BatchedMesh';
  object.perObjectFrustumCulled = this.perObjectFrustumCulled;
  object.sortObjects = this.sortObjects;
  object.drawRanges = this._drawRanges;
  object.reservedRanges = this._reservedRanges;
  object.visibility = this._visibility;
  object.active = this._active;
  object.bounds = this._bounds.map(bound => ({
    boxInitialized: bound.boxInitialized,
    boxMin: bound.box.min.toArray(),
    boxMax: bound.box.max.toArray(),
    sphereInitialized: bound.sphereInitialized,
    sphereRadius: bound.sphere.radius,
    sphereCenter: bound.sphere.center.toArray()
  }));
  object.maxGeometryCount = this._maxGeometryCount;
  object.maxVertexCount = this._maxVertexCount;
  object.maxIndexCount = this._maxIndexCount;
  object.geometryInitialized = this._geometryInitialized;
  object.geometryCount = this._geometryCount;
  object.matricesTexture = this._matricesTexture.toJSON(meta);
  if (this._colorsTexture !== null) object.colorsTexture = this._colorsTexture.toJSON(meta);
  if (this.boundingSphere !== null) {
    object.boundingSphere = {
      center: object.boundingSphere.center.toArray(),
      radius: object.boundingSphere.radius
    };
  }
  if (this.boundingBox !== null) {
    object.boundingBox = {
      min: object.boundingBox.min.toArray(),
      max: object.boundingBox.max.toArray()
    };
  }
}
object.type = 'BatchedMesh';
object.type = 'BatchedMesh'
object.type
object
type
'BatchedMesh'
object.perObjectFrustumCulled = this.perObjectFrustumCulled;
object.perObjectFrustumCulled = this.perObjectFrustumCulled
object.perObjectFrustumCulled
object
perObjectFrustumCulled
this.perObjectFrustumCulled
this
perObjectFrustumCulled
object.sortObjects = this.sortObjects;
object.sortObjects = this.sortObjects
object.sortObjects
object
sortObjects
this.sortObjects
this
sortObjects
object.drawRanges = this._drawRanges;
object.drawRanges = this._drawRanges
object.drawRanges
object
drawRanges
this._drawRanges
this
_drawRanges
object.reservedRanges = this._reservedRanges;
object.reservedRanges = this._reservedRanges
object.reservedRanges
object
reservedRanges
this._reservedRanges
this
_reservedRanges
object.visibility = this._visibility;
object.visibility = this._visibility
object.visibility
object
visibility
this._visibility
this
_visibility
object.active = this._active;
object.active = this._active
object.active
object
active
this._active
this
_active
object.bounds = this._bounds.map(bound => ({
  boxInitialized: bound.boxInitialized,
  boxMin: bound.box.min.toArray(),
  boxMax: bound.box.max.toArray(),
  sphereInitialized: bound.sphereInitialized,
  sphereRadius: bound.sphere.radius,
  sphereCenter: bound.sphere.center.toArray()
}));
object.bounds = this._bounds.map(bound => ({
  boxInitialized: bound.boxInitialized,
  boxMin: bound.box.min.toArray(),
  boxMax: bound.box.max.toArray(),
  sphereInitialized: bound.sphereInitialized,
  sphereRadius: bound.sphere.radius,
  sphereCenter: bound.sphere.center.toArray()
}))
object.bounds
object
bounds
this._bounds.map(bound => ({
  boxInitialized: bound.boxInitialized,
  boxMin: bound.box.min.toArray(),
  boxMax: bound.box.max.toArray(),
  sphereInitialized: bound.sphereInitialized,
  sphereRadius: bound.sphere.radius,
  sphereCenter: bound.sphere.center.toArray()
}))
this._bounds.map
this._bounds
this
_bounds
map
bound => ({
  boxInitialized: bound.boxInitialized,
  boxMin: bound.box.min.toArray(),
  boxMax: bound.box.max.toArray(),
  sphereInitialized: bound.sphereInitialized,
  sphereRadius: bound.sphere.radius,
  sphereCenter: bound.sphere.center.toArray()
})
clone(recursive) {
  return new this.constructor().copy(this, recursive);
}
clone
recursive
{
  return new this.constructor().copy(this, recursive);
}
return new this.constructor().copy(this, recursive);
new this.constructor().copy(this, recursive)
new this.constructor().copy
new this.constructor()
this.constructor
this
constructor
copy
this
recursive
copy(source, recursive = true) {
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
  this.animations = source.animations.slice();
  this.userData = JSON.parse(JSON.stringify(source.userData));
  if (recursive === true) {
    for (let i = 0; i < source.children.length; i++) {
      const child = source.children[i];
      this.add(child.clone());
    }
  }
  return this;
}
copy(source, recursive = true) {
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
  this.animations = source.animations.slice();
  this.userData = JSON.parse(JSON.stringify(source.userData));
  if (recursive === true) {
    for (let i = 0; i < source.children.length; i++) {
      const child = source.children[i];
      this.add(child.clone());
    }
  }
  return this;
}
copy
source
recursive = true
recursive
true
{
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
  this.animations = source.animations.slice();
  this.userData = JSON.parse(JSON.stringify(source.userData));
  if (recursive === true) {
    for (let i = 0; i < source.children.length; i++) {
      const child = source.children[i];
      this.add(child.clone());
    }
  }
  return this;
}
this.name = source.name;
this.name = source.name
this.name
this
name
source.name
source
name
this.up.copy(source.up);
this.up.copy(source.up)
this.up.copy
this.up
this
up
copy
source.up
source
up
this.position.copy(source.position);
this.position.copy(source.position)
this.position.copy
this.position
this
position
copy
source.position
source
position
this.rotation.order = source.rotation.order;
this.rotation.order = source.rotation.order
this.rotation.order
this.rotation
this
rotation
order
source.rotation.order
source.rotation
source
rotation
order
this.quaternion.copy(source.quaternion);
this.quaternion.copy(source.quaternion)
this.quaternion.copy
this.quaternion
this
quaternion
copy
source.quaternion
source
quaternion
this.scale.copy(source.scale);
this.scale.copy(source.scale)
this.scale.copy
this.scale
this
scale
copy
source.scale
source
scale
this.matrix.copy(source.matrix);
this.matrix.copy(source.matrix)
this.matrix.copy
this.matrix
this
matrix
copy
source.matrix
source
matrix
this.matrixWorld.copy(source.matrixWorld);
this.matrixWorld.copy(source.matrixWorld)
this.matrixWorld.copy
this.matrixWorld
this
matrixWorld
copy
source.matrixWorld
source
matrixWorld
this.matrixAutoUpdate = source.matrixAutoUpdate;
this.matrixAutoUpdate = source.matrixAutoUpdate
this.matrixAutoUpdate
this
matrixAutoUpdate
source.matrixAutoUpdate
source
matrixAutoUpdate
this.matrixWorldAutoUpdate = source.matrixWorldAutoUpdate;
this.matrixWorldAutoUpdate = source.matrixWorldAutoUpdate
this.matrixWorldAutoUpdate
this
matrixWorldAutoUpdate
source.matrixWorldAutoUpdate
source
matrixWorldAutoUpdate
this.matrixWorldNeedsUpdate = source.matrixWorldNeedsUpdate;
this.matrixWorldNeedsUpdate = source.matrixWorldNeedsUpdate
this.matrixWorldNeedsUpdate
this
matrixWorldNeedsUpdate
source.matrixWorldNeedsUpdate
source
matrixWorldNeedsUpdate
this.layers.mask = source.layers.mask;
this.layers.mask = source.layers.mask
this.layers.mask
this.layers
this
layers
mask
source.layers.mask
source.layers
source
layers
mask
this.visible = source.visible;
this.visible = source.visible
this.visible
this
visible
source.visible
source
visible
this.castShadow = source.castShadow;
this.castShadow = source.castShadow
this.castShadow
this
castShadow
source.castShadow
source
castShadow
this.receiveShadow = source.receiveShadow;
this.receiveShadow = source.receiveShadow
this.receiveShadow
this
receiveShadow
source.receiveShadow
source
receiveShadow
this.frustumCulled = source.frustumCulled;
this.frustumCulled = source.frustumCulled
this.frustumCulled
this
frustumCulled
source.frustumCulled
source
frustumCulled
this.renderOrder = source.renderOrder;
this.renderOrder = source.renderOrder
this.renderOrder
this
renderOrder
source.renderOrder
source
renderOrder
this.animations = source.animations.slice();
this.animations = source.animations.slice()
this.animations
this
animations
source.animations.slice()
source.animations.slice
source.animations
source
animations
slice
this.userData = JSON.parse(JSON.stringify(source.userData));
this.userData = JSON.parse(JSON.stringify(source.userData))
this.userData
this
userData
JSON.parse(JSON.stringify(source.userData))
JSON.parse
JSON
parse
JSON.stringify(source.userData)
JSON.stringify
JSON
stringify
source.userData
source
userData
if (recursive === true) {
  for (let i = 0; i < source.children.length; i++) {
    const child = source.children[i];
    this.add(child.clone());
  }
}
recursive === true
recursive
true
{
  for (let i = 0; i < source.children.length; i++) {
    const child = source.children[i];
    this.add(child.clone());
  }
}
for (let i = 0; i < source.children.length; i++) {
  const child = source.children[i];
  this.add(child.clone());
}
let i = 0;
i = 0
i
0
i < source.children.length
i
source.children.length
source.children
source
children
length
i++
i
{
  const child = source.children[i];
  this.add(child.clone());
}
const child = source.children[i];
child = source.children[i]
child
source.children[i]
source.children
source
children
i
this.add(child.clone());
this.add(child.clone())
this.add
this
add
child.clone()
child.clone
child
clone
return this;
this
EventDispatcher
Object3D.DEFAULT_UP = /*@__PURE__*/new Vector3(0, 1, 0);
Object3D.DEFAULT_UP = /*@__PURE__*/new Vector3(0, 1, 0)
Object3D.DEFAULT_UP
Object3D
DEFAULT_UP
/*@__PURE__*/new Vector3(0, 1, 0)
Vector3
0
1
0
Object3D.DEFAULT_MATRIX_AUTO_UPDATE = true;
Object3D.DEFAULT_MATRIX_AUTO_UPDATE = true
Object3D.DEFAULT_MATRIX_AUTO_UPDATE
Object3D
DEFAULT_MATRIX_AUTO_UPDATE
true
Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true;
Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true
Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE
Object3D
DEFAULT_MATRIX_WORLD_AUTO_UPDATE
true
export { Object3D };
Object3D
Object3D
Object3D