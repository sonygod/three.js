import { Vector3 } from '../math/Vector3.js';
import { Vector2 } from '../math/Vector2.js';
import { Box3 } from '../math/Box3.js';
import { EventDispatcher } from './EventDispatcher.js';
import { BufferAttribute, Float32BufferAttribute, Uint16BufferAttribute, Uint32BufferAttribute } from './BufferAttribute.js';
import { Sphere } from '../math/Sphere.js';
import { Object3D } from './Object3D.js';
import { Matrix4 } from '../math/Matrix4.js';
import { Matrix3 } from '../math/Matrix3.js';
import * as MathUtils from '../math/MathUtils.js';
import { arrayNeedsUint32 } from '../utils.js';
let _id = 0;
const _m1 = /*@__PURE__*/new Matrix4();
const _obj = /*@__PURE__*/new Object3D();
const _offset = /*@__PURE__*/new Vector3();
const _box = /*@__PURE__*/new Box3();
const _boxMorphTargets = /*@__PURE__*/new Box3();
const _vector = /*@__PURE__*/new Vector3();
class BufferGeometry extends EventDispatcher {
  constructor() {
    super();
    this.isBufferGeometry = true;
    Object.defineProperty(this, 'id', {
      value: _id++
    });
    this.uuid = MathUtils.generateUUID();
    this.name = '';
    this.type = 'BufferGeometry';
    this.index = null;
    this.attributes = {};
    this.morphAttributes = {};
    this.morphTargetsRelative = false;
    this.groups = [];
    this.boundingBox = null;
    this.boundingSphere = null;
    this.drawRange = {
      start: 0,
      count: Infinity
    };
    this.userData = {};
  }
  getIndex() {
    return this.index;
  }
  setIndex(index) {
    if (Array.isArray(index)) {
      this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
    } else {
      this.index = index;
    }
    return this;
  }
  getAttribute(name) {
    return this.attributes[name];
  }
  setAttribute(name, attribute) {
    this.attributes[name] = attribute;
    return this;
  }
  deleteAttribute(name) {
    delete this.attributes[name];
    return this;
  }
  hasAttribute(name) {
    return this.attributes[name] !== undefined;
  }
  addGroup(start, count, materialIndex = 0) {
    this.groups.push({
      start: start,
      count: count,
      materialIndex: materialIndex
    });
  }
  clearGroups() {
    this.groups = [];
  }
  setDrawRange(start, count) {
    this.drawRange.start = start;
    this.drawRange.count = count;
  }
  applyMatrix4(matrix) {
    const position = this.attributes.position;
    if (position !== undefined) {
      position.applyMatrix4(matrix);
      position.needsUpdate = true;
    }
    const normal = this.attributes.normal;
    if (normal !== undefined) {
      const normalMatrix = new Matrix3().getNormalMatrix(matrix);
      normal.applyNormalMatrix(normalMatrix);
      normal.needsUpdate = true;
    }
    const tangent = this.attributes.tangent;
    if (tangent !== undefined) {
      tangent.transformDirection(matrix);
      tangent.needsUpdate = true;
    }
    if (this.boundingBox !== null) {
      this.computeBoundingBox();
    }
    if (this.boundingSphere !== null) {
      this.computeBoundingSphere();
    }
    return this;
  }
  applyQuaternion(q) {
    _m1.makeRotationFromQuaternion(q);
    this.applyMatrix4(_m1);
    return this;
  }
  rotateX(angle) {
    // rotate geometry around world x-axis

    _m1.makeRotationX(angle);
    this.applyMatrix4(_m1);
    return this;
  }
  rotateY(angle) {
    // rotate geometry around world y-axis

    _m1.makeRotationY(angle);
    this.applyMatrix4(_m1);
    return this;
  }
  rotateZ(angle) {
    // rotate geometry around world z-axis

    _m1.makeRotationZ(angle);
    this.applyMatrix4(_m1);
    return this;
  }
  translate(x, y, z) {
    // translate geometry

    _m1.makeTranslation(x, y, z);
    this.applyMatrix4(_m1);
    return this;
  }
  scale(x, y, z) {
    // scale geometry

    _m1.makeScale(x, y, z);
    this.applyMatrix4(_m1);
    return this;
  }
  lookAt(vector) {
    _obj.lookAt(vector);
    _obj.updateMatrix();
    this.applyMatrix4(_obj.matrix);
    return this;
  }
  center() {
    this.computeBoundingBox();
    this.boundingBox.getCenter(_offset).negate();
    this.translate(_offset.x, _offset.y, _offset.z);
    return this;
  }
  setFromPoints(points) {
    const position = [];
    for (let i = 0, l = points.length; i < l; i++) {
      const point = points[i];
      position.push(point.x, point.y, point.z || 0);
    }
    this.setAttribute('position', new Float32BufferAttribute(position, 3));
    return this;
  }
  computeBoundingBox() {
    if (this.boundingBox === null) {
      this.boundingBox = new Box3();
    }
    const position = this.attributes.position;
    const morphAttributesPosition = this.morphAttributes.position;
    if (position && position.isGLBufferAttribute) {
      console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
      this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity));
      return;
    }
    if (position !== undefined) {
      this.boundingBox.setFromBufferAttribute(position);

      // process morph attributes if present

      if (morphAttributesPosition) {
        for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
          const morphAttribute = morphAttributesPosition[i];
          _box.setFromBufferAttribute(morphAttribute);
          if (this.morphTargetsRelative) {
            _vector.addVectors(this.boundingBox.min, _box.min);
            this.boundingBox.expandByPoint(_vector);
            _vector.addVectors(this.boundingBox.max, _box.max);
            this.boundingBox.expandByPoint(_vector);
          } else {
            this.boundingBox.expandByPoint(_box.min);
            this.boundingBox.expandByPoint(_box.max);
          }
        }
      }
    } else {
      this.boundingBox.makeEmpty();
    }
    if (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) {
      console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
    }
  }
  computeBoundingSphere() {
    if (this.boundingSphere === null) {
      this.boundingSphere = new Sphere();
    }
    const position = this.attributes.position;
    const morphAttributesPosition = this.morphAttributes.position;
    if (position && position.isGLBufferAttribute) {
      console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
      this.boundingSphere.set(new Vector3(), Infinity);
      return;
    }
    if (position) {
      // first, find the center of the bounding sphere

      const center = this.boundingSphere.center;
      _box.setFromBufferAttribute(position);

      // process morph attributes if present

      if (morphAttributesPosition) {
        for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
          const morphAttribute = morphAttributesPosition[i];
          _boxMorphTargets.setFromBufferAttribute(morphAttribute);
          if (this.morphTargetsRelative) {
            _vector.addVectors(_box.min, _boxMorphTargets.min);
            _box.expandByPoint(_vector);
            _vector.addVectors(_box.max, _boxMorphTargets.max);
            _box.expandByPoint(_vector);
          } else {
            _box.expandByPoint(_boxMorphTargets.min);
            _box.expandByPoint(_boxMorphTargets.max);
          }
        }
      }
      _box.getCenter(center);

      // second, try to find a boundingSphere with a radius smaller than the
      // boundingSphere of the boundingBox: sqrt(3) smaller in the best case

      let maxRadiusSq = 0;
      for (let i = 0, il = position.count; i < il; i++) {
        _vector.fromBufferAttribute(position, i);
        maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
      }

      // process morph attributes if present

      if (morphAttributesPosition) {
        for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
          const morphAttribute = morphAttributesPosition[i];
          const morphTargetsRelative = this.morphTargetsRelative;
          for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
            _vector.fromBufferAttribute(morphAttribute, j);
            if (morphTargetsRelative) {
              _offset.fromBufferAttribute(position, j);
              _vector.add(_offset);
            }
            maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
          }
        }
      }
      this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
      if (isNaN(this.boundingSphere.radius)) {
        console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
      }
    }
  }
  computeTangents() {
    const index = this.index;
    const attributes = this.attributes;

    // based on http://www.terathon.com/code/tangent.html
    // (per vertex tangents)

    if (index === null || attributes.position === undefined || attributes.normal === undefined || attributes.uv === undefined) {
      console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
      return;
    }
    const positionAttribute = attributes.position;
    const normalAttribute = attributes.normal;
    const uvAttribute = attributes.uv;
    if (this.hasAttribute('tangent') === false) {
      this.setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
    }
    const tangentAttribute = this.getAttribute('tangent');
    const tan1 = [],
      tan2 = [];
    for (let i = 0; i < positionAttribute.count; i++) {
      tan1[i] = new Vector3();
      tan2[i] = new Vector3();
    }
    const vA = new Vector3(),
      vB = new Vector3(),
      vC = new Vector3(),
      uvA = new Vector2(),
      uvB = new Vector2(),
      uvC = new Vector2(),
      sdir = new Vector3(),
      tdir = new Vector3();
    function handleTriangle(a, b, c) {
      vA.fromBufferAttribute(positionAttribute, a);
      vB.fromBufferAttribute(positionAttribute, b);
      vC.fromBufferAttribute(positionAttribute, c);
      uvA.fromBufferAttribute(uvAttribute, a);
      uvB.fromBufferAttribute(uvAttribute, b);
      uvC.fromBufferAttribute(uvAttribute, c);
      vB.sub(vA);
      vC.sub(vA);
      uvB.sub(uvA);
      uvC.sub(uvA);
      const r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

      // silently ignore degenerate uv triangles having coincident or colinear vertices

      if (!isFinite(r)) return;
      sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
      tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);
      tan1[a].add(sdir);
      tan1[b].add(sdir);
      tan1[c].add(sdir);
      tan2[a].add(tdir);
      tan2[b].add(tdir);
      tan2[c].add(tdir);
    }
    let groups = this.groups;
    if (groups.length === 0) {
      groups = [{
        start: 0,
        count: index.count
      }];
    }
    for (let i = 0, il = groups.length; i < il; ++i) {
      const group = groups[i];
      const start = group.start;
      const count = group.count;
      for (let j = start, jl = start + count; j < jl; j += 3) {
        handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
      }
    }
    const tmp = new Vector3(),
      tmp2 = new Vector3();
    const n = new Vector3(),
      n2 = new Vector3();
    function handleVertex(v) {
      n.fromBufferAttribute(normalAttribute, v);
      n2.copy(n);
      const t = tan1[v];

      // Gram-Schmidt orthogonalize

      tmp.copy(t);
      tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

      // Calculate handedness

      tmp2.crossVectors(n2, t);
      const test = tmp2.dot(tan2[v]);
      const w = test < 0.0 ? -1.0 : 1.0;
      tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
    }
    for (let i = 0, il = groups.length; i < il; ++i) {
      const group = groups[i];
      const start = group.start;
      const count = group.count;
      for (let j = start, jl = start + count; j < jl; j += 3) {
        handleVertex(index.getX(j + 0));
        handleVertex(index.getX(j + 1));
        handleVertex(index.getX(j + 2));
      }
    }
  }
  computeVertexNormals() {
    const index = this.index;
    const positionAttribute = this.getAttribute('position');
    if (positionAttribute !== undefined) {
      let normalAttribute = this.getAttribute('normal');
      if (normalAttribute === undefined) {
        normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
        this.setAttribute('normal', normalAttribute);
      } else {
        // reset existing normals to zero

        for (let i = 0, il = normalAttribute.count; i < il; i++) {
          normalAttribute.setXYZ(i, 0, 0, 0);
        }
      }
      const pA = new Vector3(),
        pB = new Vector3(),
        pC = new Vector3();
      const nA = new Vector3(),
        nB = new Vector3(),
        nC = new Vector3();
      const cb = new Vector3(),
        ab = new Vector3();

      // indexed elements

      if (index) {
        for (let i = 0, il = index.count; i < il; i += 3) {
          const vA = index.getX(i + 0);
          const vB = index.getX(i + 1);
          const vC = index.getX(i + 2);
          pA.fromBufferAttribute(positionAttribute, vA);
          pB.fromBufferAttribute(positionAttribute, vB);
          pC.fromBufferAttribute(positionAttribute, vC);
          cb.subVectors(pC, pB);
          ab.subVectors(pA, pB);
          cb.cross(ab);
          nA.fromBufferAttribute(normalAttribute, vA);
          nB.fromBufferAttribute(normalAttribute, vB);
          nC.fromBufferAttribute(normalAttribute, vC);
          nA.add(cb);
          nB.add(cb);
          nC.add(cb);
          normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
          normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
          normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
        }
      } else {
        // non-indexed elements (unconnected triangle soup)

        for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
          pA.fromBufferAttribute(positionAttribute, i + 0);
          pB.fromBufferAttribute(positionAttribute, i + 1);
          pC.fromBufferAttribute(positionAttribute, i + 2);
          cb.subVectors(pC, pB);
          ab.subVectors(pA, pB);
          cb.cross(ab);
          normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
          normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
          normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
        }
      }
      this.normalizeNormals();
      normalAttribute.needsUpdate = true;
    }
  }
  normalizeNormals() {
    const normals = this.attributes.normal;
    for (let i = 0, il = normals.count; i < il; i++) {
      _vector.fromBufferAttribute(normals, i);
      _vector.normalize();
      normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
    }
  }
  toNonIndexed() {
    function convertBufferAttribute(attribute, indices) {
      const array = attribute.array;
      const itemSize = attribute.itemSize;
      const normalized = attribute.normalized;
      const array2 = new array.constructor(indices.length * itemSize);
      let index = 0,
        index2 = 0;
      for (let i = 0, l = indices.length; i < l; i++) {
        if (attribute.isInterleavedBufferAttribute) {
          index = indices[i] * attribute.data.stride + attribute.offset;
        } else {
          index = indices[i] * itemSize;
        }
        for (let j = 0; j < itemSize; j++) {
          array2[index2++] = array[index++];
        }
      }
      return new BufferAttribute(array2, itemSize, normalized);
    }

    //

    if (this.index === null) {
      console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
      return this;
    }
    const geometry2 = new BufferGeometry();
    const indices = this.index.array;
    const attributes = this.attributes;

    // attributes

    for (const name in attributes) {
      const attribute = attributes[name];
      const newAttribute = convertBufferAttribute(attribute, indices);
      geometry2.setAttribute(name, newAttribute);
    }

    // morph attributes

    const morphAttributes = this.morphAttributes;
    for (const name in morphAttributes) {
      const morphArray = [];
      const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

      for (let i = 0, il = morphAttribute.length; i < il; i++) {
        const attribute = morphAttribute[i];
        const newAttribute = convertBufferAttribute(attribute, indices);
        morphArray.push(newAttribute);
      }
      geometry2.morphAttributes[name] = morphArray;
    }
    geometry2.morphTargetsRelative = this.morphTargetsRelative;

    // groups

    const groups = this.groups;
    for (let i = 0, l = groups.length; i < l; i++) {
      const group = groups[i];
      geometry2.addGroup(group.start, group.count, group.materialIndex);
    }
    return geometry2;
  }
  toJSON() {
    const data = {
      metadata: {
        version: 4.6,
        type: 'BufferGeometry',
        generator: 'BufferGeometry.toJSON'
      }
    };

    // standard BufferGeometry serialization

    data.uuid = this.uuid;
    data.type = this.type;
    if (this.name !== '') data.name = this.name;
    if (Object.keys(this.userData).length > 0) data.userData = this.userData;
    if (this.parameters !== undefined) {
      const parameters = this.parameters;
      for (const key in parameters) {
        if (parameters[key] !== undefined) data[key] = parameters[key];
      }
      return data;
    }

    // for simplicity the code assumes attributes are not shared across geometries, see #15811

    data.data = {
      attributes: {}
    };
    const index = this.index;
    if (index !== null) {
      data.data.index = {
        type: index.array.constructor.name,
        array: Array.prototype.slice.call(index.array)
      };
    }
    const attributes = this.attributes;
    for (const key in attributes) {
      const attribute = attributes[key];
      data.data.attributes[key] = attribute.toJSON(data.data);
    }
    const morphAttributes = {};
    let hasMorphAttributes = false;
    for (const key in this.morphAttributes) {
      const attributeArray = this.morphAttributes[key];
      const array = [];
      for (let i = 0, il = attributeArray.length; i < il; i++) {
        const attribute = attributeArray[i];
        array.push(attribute.toJSON(data.data));
      }
      if (array.length > 0) {
        morphAttributes[key] = array;
        hasMorphAttributes = true;
      }
    }
    if (hasMorphAttributes) {
      data.data.morphAttributes = morphAttributes;
      data.data.morphTargetsRelative = this.morphTargetsRelative;
    }
    const groups = this.groups;
    if (groups.length > 0) {
      data.data.groups = JSON.parse(JSON.stringify(groups));
    }
    const boundingSphere = this.boundingSphere;
    if (boundingSphere !== null) {
      data.data.boundingSphere = {
        center: boundingSphere.center.toArray(),
        radius: boundingSphere.radius
      };
    }
    return data;
  }
  clone() {
    return new this.constructor().copy(this);
  }
  copy(source) {
    // reset

    this.index = null;
    this.attributes = {};
    this.morphAttributes = {};
    this.groups = [];
    this.boundingBox = null;
    this.boundingSphere = null;

    // used for storing cloned, shared data

    const data = {};

    // name

    this.name = source.name;

    // index

    const index = source.index;
    if (index !== null) {
      this.setIndex(index.clone(data));
    }

    // attributes

    const attributes = source.attributes;
    for (const name in attributes) {
      const attribute = attributes[name];
      this.setAttribute(name, attribute.clone(data));
    }

    // morph attributes

    const morphAttributes = source.morphAttributes;
    for (const name in morphAttributes) {
      const array = [];
      const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

      for (let i = 0, l = morphAttribute.length; i < l; i++) {
        array.push(morphAttribute[i].clone(data));
      }
      this.morphAttributes[name] = array;
    }
    this.morphTargetsRelative = source.morphTargetsRelative;

    // groups

    const groups = source.groups;
    for (let i = 0, l = groups.length; i < l; i++) {
      const group = groups[i];
      this.addGroup(group.start, group.count, group.materialIndex);
    }

    // bounding box

    const boundingBox = source.boundingBox;
    if (boundingBox !== null) {
      this.boundingBox = boundingBox.clone();
    }

    // bounding sphere

    const boundingSphere = source.boundingSphere;
    if (boundingSphere !== null) {
      this.boundingSphere = boundingSphere.clone();
    }

    // draw range

    this.drawRange.start = source.drawRange.start;
    this.drawRange.count = source.drawRange.count;

    // user data

    this.userData = source.userData;
    return this;
  }
  dispose() {
    this.dispatchEvent({
      type: 'dispose'
    });
  }
}
export { BufferGeometry };
import { Vector3 } from '../math/Vector3.js';
Vector3
Vector3
Vector3
'../math/Vector3.js'
import { Vector2 } from '../math/Vector2.js';
Vector2
Vector2
Vector2
'../math/Vector2.js'
import { Box3 } from '../math/Box3.js';
Box3
Box3
Box3
'../math/Box3.js'
import { EventDispatcher } from './EventDispatcher.js';
EventDispatcher
EventDispatcher
EventDispatcher
'./EventDispatcher.js'
import { BufferAttribute, Float32BufferAttribute, Uint16BufferAttribute, Uint32BufferAttribute } from './BufferAttribute.js';
BufferAttribute
BufferAttribute
BufferAttribute
Float32BufferAttribute
Float32BufferAttribute
Float32BufferAttribute
Uint16BufferAttribute
Uint16BufferAttribute
Uint16BufferAttribute
Uint32BufferAttribute
Uint32BufferAttribute
Uint32BufferAttribute
'./BufferAttribute.js'
import { Sphere } from '../math/Sphere.js';
Sphere
Sphere
Sphere
'../math/Sphere.js'
import { Object3D } from './Object3D.js';
Object3D
Object3D
Object3D
'./Object3D.js'
import { Matrix4 } from '../math/Matrix4.js';
Matrix4
Matrix4
Matrix4
'../math/Matrix4.js'
import { Matrix3 } from '../math/Matrix3.js';
Matrix3
Matrix3
Matrix3
'../math/Matrix3.js'
import * as MathUtils from '../math/MathUtils.js';
* as MathUtils
MathUtils
'../math/MathUtils.js'
import { arrayNeedsUint32 } from '../utils.js';
arrayNeedsUint32
arrayNeedsUint32
arrayNeedsUint32
'../utils.js'
let _id = 0;
_id = 0
_id
0
const _m1 = /*@__PURE__*/new Matrix4();
_m1 = /*@__PURE__*/new Matrix4()
_m1
/*@__PURE__*/new Matrix4()
Matrix4
const _obj = /*@__PURE__*/new Object3D();
_obj = /*@__PURE__*/new Object3D()
_obj
/*@__PURE__*/new Object3D()
Object3D
const _offset = /*@__PURE__*/new Vector3();
_offset = /*@__PURE__*/new Vector3()
_offset
/*@__PURE__*/new Vector3()
Vector3
const _box = /*@__PURE__*/new Box3();
_box = /*@__PURE__*/new Box3()
_box
/*@__PURE__*/new Box3()
Box3
const _boxMorphTargets = /*@__PURE__*/new Box3();
_boxMorphTargets = /*@__PURE__*/new Box3()
_boxMorphTargets
/*@__PURE__*/new Box3()
Box3
const _vector = /*@__PURE__*/new Vector3();
_vector = /*@__PURE__*/new Vector3()
_vector
/*@__PURE__*/new Vector3()
Vector3
class BufferGeometry extends EventDispatcher {
  constructor() {
    super();
    this.isBufferGeometry = true;
    Object.defineProperty(this, 'id', {
      value: _id++
    });
    this.uuid = MathUtils.generateUUID();
    this.name = '';
    this.type = 'BufferGeometry';
    this.index = null;
    this.attributes = {};
    this.morphAttributes = {};
    this.morphTargetsRelative = false;
    this.groups = [];
    this.boundingBox = null;
    this.boundingSphere = null;
    this.drawRange = {
      start: 0,
      count: Infinity
    };
    this.userData = {};
  }
  getIndex() {
    return this.index;
  }
  setIndex(index) {
    if (Array.isArray(index)) {
      this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
    } else {
      this.index = index;
    }
    return this;
  }
  getAttribute(name) {
    return this.attributes[name];
  }
  setAttribute(name, attribute) {
    this.attributes[name] = attribute;
    return this;
  }
  deleteAttribute(name) {
    delete this.attributes[name];
    return this;
  }
  hasAttribute(name) {
    return this.attributes[name] !== undefined;
  }
  addGroup(start, count, materialIndex = 0) {
    this.groups.push({
      start: start,
      count: count,
      materialIndex: materialIndex
    });
  }
  clearGroups() {
    this.groups = [];
  }
  setDrawRange(start, count) {
    this.drawRange.start = start;
    this.drawRange.count = count;
  }
  applyMatrix4(matrix) {
    const position = this.attributes.position;
    if (position !== undefined) {
      position.applyMatrix4(matrix);
      position.needsUpdate = true;
    }
    const normal = this.attributes.normal;
    if (normal !== undefined) {
      const normalMatrix = new Matrix3().getNormalMatrix(matrix);
      normal.applyNormalMatrix(normalMatrix);
      normal.needsUpdate = true;
    }
    const tangent = this.attributes.tangent;
    if (tangent !== undefined) {
      tangent.transformDirection(matrix);
      tangent.needsUpdate = true;
    }
    if (this.boundingBox !== null) {
      this.computeBoundingBox();
    }
    if (this.boundingSphere !== null) {
      this.computeBoundingSphere();
    }
    return this;
  }
  applyQuaternion(q) {
    _m1.makeRotationFromQuaternion(q);
    this.applyMatrix4(_m1);
    return this;
  }
  rotateX(angle) {
    // rotate geometry around world x-axis

    _m1.makeRotationX(angle);
    this.applyMatrix4(_m1);
    return this;
  }
  rotateY(angle) {
    // rotate geometry around world y-axis

    _m1.makeRotationY(angle);
    this.applyMatrix4(_m1);
    return this;
  }
  rotateZ(angle) {
    // rotate geometry around world z-axis

    _m1.makeRotationZ(angle);
    this.applyMatrix4(_m1);
    return this;
  }
  translate(x, y, z) {
    // translate geometry

    _m1.makeTranslation(x, y, z);
    this.applyMatrix4(_m1);
    return this;
  }
  scale(x, y, z) {
    // scale geometry

    _m1.makeScale(x, y, z);
    this.applyMatrix4(_m1);
    return this;
  }
  lookAt(vector) {
    _obj.lookAt(vector);
    _obj.updateMatrix();
    this.applyMatrix4(_obj.matrix);
    return this;
  }
  center() {
    this.computeBoundingBox();
    this.boundingBox.getCenter(_offset).negate();
    this.translate(_offset.x, _offset.y, _offset.z);
    return this;
  }
  setFromPoints(points) {
    const position = [];
    for (let i = 0, l = points.length; i < l; i++) {
      const point = points[i];
      position.push(point.x, point.y, point.z || 0);
    }
    this.setAttribute('position', new Float32BufferAttribute(position, 3));
    return this;
  }
  computeBoundingBox() {
    if (this.boundingBox === null) {
      this.boundingBox = new Box3();
    }
    const position = this.attributes.position;
    const morphAttributesPosition = this.morphAttributes.position;
    if (position && position.isGLBufferAttribute) {
      console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
      this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity));
      return;
    }
    if (position !== undefined) {
      this.boundingBox.setFromBufferAttribute(position);

      // process morph attributes if present

      if (morphAttributesPosition) {
        for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
          const morphAttribute = morphAttributesPosition[i];
          _box.setFromBufferAttribute(morphAttribute);
          if (this.morphTargetsRelative) {
            _vector.addVectors(this.boundingBox.min, _box.min);
            this.boundingBox.expandByPoint(_vector);
            _vector.addVectors(this.boundingBox.max, _box.max);
            this.boundingBox.expandByPoint(_vector);
          } else {
            this.boundingBox.expandByPoint(_box.min);
            this.boundingBox.expandByPoint(_box.max);
          }
        }
      }
    } else {
      this.boundingBox.makeEmpty();
    }
    if (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) {
      console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
    }
  }
  computeBoundingSphere() {
    if (this.boundingSphere === null) {
      this.boundingSphere = new Sphere();
    }
    const position = this.attributes.position;
    const morphAttributesPosition = this.morphAttributes.position;
    if (position && position.isGLBufferAttribute) {
      console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
      this.boundingSphere.set(new Vector3(), Infinity);
      return;
    }
    if (position) {
      // first, find the center of the bounding sphere

      const center = this.boundingSphere.center;
      _box.setFromBufferAttribute(position);

      // process morph attributes if present

      if (morphAttributesPosition) {
        for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
          const morphAttribute = morphAttributesPosition[i];
          _boxMorphTargets.setFromBufferAttribute(morphAttribute);
          if (this.morphTargetsRelative) {
            _vector.addVectors(_box.min, _boxMorphTargets.min);
            _box.expandByPoint(_vector);
            _vector.addVectors(_box.max, _boxMorphTargets.max);
            _box.expandByPoint(_vector);
          } else {
            _box.expandByPoint(_boxMorphTargets.min);
            _box.expandByPoint(_boxMorphTargets.max);
          }
        }
      }
      _box.getCenter(center);

      // second, try to find a boundingSphere with a radius smaller than the
      // boundingSphere of the boundingBox: sqrt(3) smaller in the best case

      let maxRadiusSq = 0;
      for (let i = 0, il = position.count; i < il; i++) {
        _vector.fromBufferAttribute(position, i);
        maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
      }

      // process morph attributes if present

      if (morphAttributesPosition) {
        for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
          const morphAttribute = morphAttributesPosition[i];
          const morphTargetsRelative = this.morphTargetsRelative;
          for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
            _vector.fromBufferAttribute(morphAttribute, j);
            if (morphTargetsRelative) {
              _offset.fromBufferAttribute(position, j);
              _vector.add(_offset);
            }
            maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
          }
        }
      }
      this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
      if (isNaN(this.boundingSphere.radius)) {
        console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
      }
    }
  }
  computeTangents() {
    const index = this.index;
    const attributes = this.attributes;

    // based on http://www.terathon.com/code/tangent.html
    // (per vertex tangents)

    if (index === null || attributes.position === undefined || attributes.normal === undefined || attributes.uv === undefined) {
      console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
      return;
    }
    const positionAttribute = attributes.position;
    const normalAttribute = attributes.normal;
    const uvAttribute = attributes.uv;
    if (this.hasAttribute('tangent') === false) {
      this.setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
    }
    const tangentAttribute = this.getAttribute('tangent');
    const tan1 = [],
      tan2 = [];
    for (let i = 0; i < positionAttribute.count; i++) {
      tan1[i] = new Vector3();
      tan2[i] = new Vector3();
    }
    const vA = new Vector3(),
      vB = new Vector3(),
      vC = new Vector3(),
      uvA = new Vector2(),
      uvB = new Vector2(),
      uvC = new Vector2(),
      sdir = new Vector3(),
      tdir = new Vector3();
    function handleTriangle(a, b, c) {
      vA.fromBufferAttribute(positionAttribute, a);
      vB.fromBufferAttribute(positionAttribute, b);
      vC.fromBufferAttribute(positionAttribute, c);
      uvA.fromBufferAttribute(uvAttribute, a);
      uvB.fromBufferAttribute(uvAttribute, b);
      uvC.fromBufferAttribute(uvAttribute, c);
      vB.sub(vA);
      vC.sub(vA);
      uvB.sub(uvA);
      uvC.sub(uvA);
      const r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

      // silently ignore degenerate uv triangles having coincident or colinear vertices

      if (!isFinite(r)) return;
      sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
      tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);
      tan1[a].add(sdir);
      tan1[b].add(sdir);
      tan1[c].add(sdir);
      tan2[a].add(tdir);
      tan2[b].add(tdir);
      tan2[c].add(tdir);
    }
    let groups = this.groups;
    if (groups.length === 0) {
      groups = [{
        start: 0,
        count: index.count
      }];
    }
    for (let i = 0, il = groups.length; i < il; ++i) {
      const group = groups[i];
      const start = group.start;
      const count = group.count;
      for (let j = start, jl = start + count; j < jl; j += 3) {
        handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
      }
    }
    const tmp = new Vector3(),
      tmp2 = new Vector3();
    const n = new Vector3(),
      n2 = new Vector3();
    function handleVertex(v) {
      n.fromBufferAttribute(normalAttribute, v);
      n2.copy(n);
      const t = tan1[v];

      // Gram-Schmidt orthogonalize

      tmp.copy(t);
      tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

      // Calculate handedness

      tmp2.crossVectors(n2, t);
      const test = tmp2.dot(tan2[v]);
      const w = test < 0.0 ? -1.0 : 1.0;
      tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
    }
    for (let i = 0, il = groups.length; i < il; ++i) {
      const group = groups[i];
      const start = group.start;
      const count = group.count;
      for (let j = start, jl = start + count; j < jl; j += 3) {
        handleVertex(index.getX(j + 0));
        handleVertex(index.getX(j + 1));
        handleVertex(index.getX(j + 2));
      }
    }
  }
  computeVertexNormals() {
    const index = this.index;
    const positionAttribute = this.getAttribute('position');
    if (positionAttribute !== undefined) {
      let normalAttribute = this.getAttribute('normal');
      if (normalAttribute === undefined) {
        normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
        this.setAttribute('normal', normalAttribute);
      } else {
        // reset existing normals to zero

        for (let i = 0, il = normalAttribute.count; i < il; i++) {
          normalAttribute.setXYZ(i, 0, 0, 0);
        }
      }
      const pA = new Vector3(),
        pB = new Vector3(),
        pC = new Vector3();
      const nA = new Vector3(),
        nB = new Vector3(),
        nC = new Vector3();
      const cb = new Vector3(),
        ab = new Vector3();

      // indexed elements

      if (index) {
        for (let i = 0, il = index.count; i < il; i += 3) {
          const vA = index.getX(i + 0);
          const vB = index.getX(i + 1);
          const vC = index.getX(i + 2);
          pA.fromBufferAttribute(positionAttribute, vA);
          pB.fromBufferAttribute(positionAttribute, vB);
          pC.fromBufferAttribute(positionAttribute, vC);
          cb.subVectors(pC, pB);
          ab.subVectors(pA, pB);
          cb.cross(ab);
          nA.fromBufferAttribute(normalAttribute, vA);
          nB.fromBufferAttribute(normalAttribute, vB);
          nC.fromBufferAttribute(normalAttribute, vC);
          nA.add(cb);
          nB.add(cb);
          nC.add(cb);
          normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
          normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
          normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
        }
      } else {
        // non-indexed elements (unconnected triangle soup)

        for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
          pA.fromBufferAttribute(positionAttribute, i + 0);
          pB.fromBufferAttribute(positionAttribute, i + 1);
          pC.fromBufferAttribute(positionAttribute, i + 2);
          cb.subVectors(pC, pB);
          ab.subVectors(pA, pB);
          cb.cross(ab);
          normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
          normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
          normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
        }
      }
      this.normalizeNormals();
      normalAttribute.needsUpdate = true;
    }
  }
  normalizeNormals() {
    const normals = this.attributes.normal;
    for (let i = 0, il = normals.count; i < il; i++) {
      _vector.fromBufferAttribute(normals, i);
      _vector.normalize();
      normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
    }
  }
  toNonIndexed() {
    function convertBufferAttribute(attribute, indices) {
      const array = attribute.array;
      const itemSize = attribute.itemSize;
      const normalized = attribute.normalized;
      const array2 = new array.constructor(indices.length * itemSize);
      let index = 0,
        index2 = 0;
      for (let i = 0, l = indices.length; i < l; i++) {
        if (attribute.isInterleavedBufferAttribute) {
          index = indices[i] * attribute.data.stride + attribute.offset;
        } else {
          index = indices[i] * itemSize;
        }
        for (let j = 0; j < itemSize; j++) {
          array2[index2++] = array[index++];
        }
      }
      return new BufferAttribute(array2, itemSize, normalized);
    }

    //

    if (this.index === null) {
      console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
      return this;
    }
    const geometry2 = new BufferGeometry();
    const indices = this.index.array;
    const attributes = this.attributes;

    // attributes

    for (const name in attributes) {
      const attribute = attributes[name];
      const newAttribute = convertBufferAttribute(attribute, indices);
      geometry2.setAttribute(name, newAttribute);
    }

    // morph attributes

    const morphAttributes = this.morphAttributes;
    for (const name in morphAttributes) {
      const morphArray = [];
      const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

      for (let i = 0, il = morphAttribute.length; i < il; i++) {
        const attribute = morphAttribute[i];
        const newAttribute = convertBufferAttribute(attribute, indices);
        morphArray.push(newAttribute);
      }
      geometry2.morphAttributes[name] = morphArray;
    }
    geometry2.morphTargetsRelative = this.morphTargetsRelative;

    // groups

    const groups = this.groups;
    for (let i = 0, l = groups.length; i < l; i++) {
      const group = groups[i];
      geometry2.addGroup(group.start, group.count, group.materialIndex);
    }
    return geometry2;
  }
  toJSON() {
    const data = {
      metadata: {
        version: 4.6,
        type: 'BufferGeometry',
        generator: 'BufferGeometry.toJSON'
      }
    };

    // standard BufferGeometry serialization

    data.uuid = this.uuid;
    data.type = this.type;
    if (this.name !== '') data.name = this.name;
    if (Object.keys(this.userData).length > 0) data.userData = this.userData;
    if (this.parameters !== undefined) {
      const parameters = this.parameters;
      for (const key in parameters) {
        if (parameters[key] !== undefined) data[key] = parameters[key];
      }
      return data;
    }

    // for simplicity the code assumes attributes are not shared across geometries, see #15811

    data.data = {
      attributes: {}
    };
    const index = this.index;
    if (index !== null) {
      data.data.index = {
        type: index.array.constructor.name,
        array: Array.prototype.slice.call(index.array)
      };
    }
    const attributes = this.attributes;
    for (const key in attributes) {
      const attribute = attributes[key];
      data.data.attributes[key] = attribute.toJSON(data.data);
    }
    const morphAttributes = {};
    let hasMorphAttributes = false;
    for (const key in this.morphAttributes) {
      const attributeArray = this.morphAttributes[key];
      const array = [];
      for (let i = 0, il = attributeArray.length; i < il; i++) {
        const attribute = attributeArray[i];
        array.push(attribute.toJSON(data.data));
      }
      if (array.length > 0) {
        morphAttributes[key] = array;
        hasMorphAttributes = true;
      }
    }
    if (hasMorphAttributes) {
      data.data.morphAttributes = morphAttributes;
      data.data.morphTargetsRelative = this.morphTargetsRelative;
    }
    const groups = this.groups;
    if (groups.length > 0) {
      data.data.groups = JSON.parse(JSON.stringify(groups));
    }
    const boundingSphere = this.boundingSphere;
    if (boundingSphere !== null) {
      data.data.boundingSphere = {
        center: boundingSphere.center.toArray(),
        radius: boundingSphere.radius
      };
    }
    return data;
  }
  clone() {
    return new this.constructor().copy(this);
  }
  copy(source) {
    // reset

    this.index = null;
    this.attributes = {};
    this.morphAttributes = {};
    this.groups = [];
    this.boundingBox = null;
    this.boundingSphere = null;

    // used for storing cloned, shared data

    const data = {};

    // name

    this.name = source.name;

    // index

    const index = source.index;
    if (index !== null) {
      this.setIndex(index.clone(data));
    }

    // attributes

    const attributes = source.attributes;
    for (const name in attributes) {
      const attribute = attributes[name];
      this.setAttribute(name, attribute.clone(data));
    }

    // morph attributes

    const morphAttributes = source.morphAttributes;
    for (const name in morphAttributes) {
      const array = [];
      const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

      for (let i = 0, l = morphAttribute.length; i < l; i++) {
        array.push(morphAttribute[i].clone(data));
      }
      this.morphAttributes[name] = array;
    }
    this.morphTargetsRelative = source.morphTargetsRelative;

    // groups

    const groups = source.groups;
    for (let i = 0, l = groups.length; i < l; i++) {
      const group = groups[i];
      this.addGroup(group.start, group.count, group.materialIndex);
    }

    // bounding box

    const boundingBox = source.boundingBox;
    if (boundingBox !== null) {
      this.boundingBox = boundingBox.clone();
    }

    // bounding sphere

    const boundingSphere = source.boundingSphere;
    if (boundingSphere !== null) {
      this.boundingSphere = boundingSphere.clone();
    }

    // draw range

    this.drawRange.start = source.drawRange.start;
    this.drawRange.count = source.drawRange.count;

    // user data

    this.userData = source.userData;
    return this;
  }
  dispose() {
    this.dispatchEvent({
      type: 'dispose'
    });
  }
}
BufferGeometry
{
  constructor() {
    super();
    this.isBufferGeometry = true;
    Object.defineProperty(this, 'id', {
      value: _id++
    });
    this.uuid = MathUtils.generateUUID();
    this.name = '';
    this.type = 'BufferGeometry';
    this.index = null;
    this.attributes = {};
    this.morphAttributes = {};
    this.morphTargetsRelative = false;
    this.groups = [];
    this.boundingBox = null;
    this.boundingSphere = null;
    this.drawRange = {
      start: 0,
      count: Infinity
    };
    this.userData = {};
  }
  getIndex() {
    return this.index;
  }
  setIndex(index) {
    if (Array.isArray(index)) {
      this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
    } else {
      this.index = index;
    }
    return this;
  }
  getAttribute(name) {
    return this.attributes[name];
  }
  setAttribute(name, attribute) {
    this.attributes[name] = attribute;
    return this;
  }
  deleteAttribute(name) {
    delete this.attributes[name];
    return this;
  }
  hasAttribute(name) {
    return this.attributes[name] !== undefined;
  }
  addGroup(start, count, materialIndex = 0) {
    this.groups.push({
      start: start,
      count: count,
      materialIndex: materialIndex
    });
  }
  clearGroups() {
    this.groups = [];
  }
  setDrawRange(start, count) {
    this.drawRange.start = start;
    this.drawRange.count = count;
  }
  applyMatrix4(matrix) {
    const position = this.attributes.position;
    if (position !== undefined) {
      position.applyMatrix4(matrix);
      position.needsUpdate = true;
    }
    const normal = this.attributes.normal;
    if (normal !== undefined) {
      const normalMatrix = new Matrix3().getNormalMatrix(matrix);
      normal.applyNormalMatrix(normalMatrix);
      normal.needsUpdate = true;
    }
    const tangent = this.attributes.tangent;
    if (tangent !== undefined) {
      tangent.transformDirection(matrix);
      tangent.needsUpdate = true;
    }
    if (this.boundingBox !== null) {
      this.computeBoundingBox();
    }
    if (this.boundingSphere !== null) {
      this.computeBoundingSphere();
    }
    return this;
  }
  applyQuaternion(q) {
    _m1.makeRotationFromQuaternion(q);
    this.applyMatrix4(_m1);
    return this;
  }
  rotateX(angle) {
    // rotate geometry around world x-axis

    _m1.makeRotationX(angle);
    this.applyMatrix4(_m1);
    return this;
  }
  rotateY(angle) {
    // rotate geometry around world y-axis

    _m1.makeRotationY(angle);
    this.applyMatrix4(_m1);
    return this;
  }
  rotateZ(angle) {
    // rotate geometry around world z-axis

    _m1.makeRotationZ(angle);
    this.applyMatrix4(_m1);
    return this;
  }
  translate(x, y, z) {
    // translate geometry

    _m1.makeTranslation(x, y, z);
    this.applyMatrix4(_m1);
    return this;
  }
  scale(x, y, z) {
    // scale geometry

    _m1.makeScale(x, y, z);
    this.applyMatrix4(_m1);
    return this;
  }
  lookAt(vector) {
    _obj.lookAt(vector);
    _obj.updateMatrix();
    this.applyMatrix4(_obj.matrix);
    return this;
  }
  center() {
    this.computeBoundingBox();
    this.boundingBox.getCenter(_offset).negate();
    this.translate(_offset.x, _offset.y, _offset.z);
    return this;
  }
  setFromPoints(points) {
    const position = [];
    for (let i = 0, l = points.length; i < l; i++) {
      const point = points[i];
      position.push(point.x, point.y, point.z || 0);
    }
    this.setAttribute('position', new Float32BufferAttribute(position, 3));
    return this;
  }
  computeBoundingBox() {
    if (this.boundingBox === null) {
      this.boundingBox = new Box3();
    }
    const position = this.attributes.position;
    const morphAttributesPosition = this.morphAttributes.position;
    if (position && position.isGLBufferAttribute) {
      console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
      this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity));
      return;
    }
    if (position !== undefined) {
      this.boundingBox.setFromBufferAttribute(position);

      // process morph attributes if present

      if (morphAttributesPosition) {
        for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
          const morphAttribute = morphAttributesPosition[i];
          _box.setFromBufferAttribute(morphAttribute);
          if (this.morphTargetsRelative) {
            _vector.addVectors(this.boundingBox.min, _box.min);
            this.boundingBox.expandByPoint(_vector);
            _vector.addVectors(this.boundingBox.max, _box.max);
            this.boundingBox.expandByPoint(_vector);
          } else {
            this.boundingBox.expandByPoint(_box.min);
            this.boundingBox.expandByPoint(_box.max);
          }
        }
      }
    } else {
      this.boundingBox.makeEmpty();
    }
    if (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) {
      console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
    }
  }
  computeBoundingSphere() {
    if (this.boundingSphere === null) {
      this.boundingSphere = new Sphere();
    }
    const position = this.attributes.position;
    const morphAttributesPosition = this.morphAttributes.position;
    if (position && position.isGLBufferAttribute) {
      console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
      this.boundingSphere.set(new Vector3(), Infinity);
      return;
    }
    if (position) {
      // first, find the center of the bounding sphere

      const center = this.boundingSphere.center;
      _box.setFromBufferAttribute(position);

      // process morph attributes if present

      if (morphAttributesPosition) {
        for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
          const morphAttribute = morphAttributesPosition[i];
          _boxMorphTargets.setFromBufferAttribute(morphAttribute);
          if (this.morphTargetsRelative) {
            _vector.addVectors(_box.min, _boxMorphTargets.min);
            _box.expandByPoint(_vector);
            _vector.addVectors(_box.max, _boxMorphTargets.max);
            _box.expandByPoint(_vector);
          } else {
            _box.expandByPoint(_boxMorphTargets.min);
            _box.expandByPoint(_boxMorphTargets.max);
          }
        }
      }
      _box.getCenter(center);

      // second, try to find a boundingSphere with a radius smaller than the
      // boundingSphere of the boundingBox: sqrt(3) smaller in the best case

      let maxRadiusSq = 0;
      for (let i = 0, il = position.count; i < il; i++) {
        _vector.fromBufferAttribute(position, i);
        maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
      }

      // process morph attributes if present

      if (morphAttributesPosition) {
        for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
          const morphAttribute = morphAttributesPosition[i];
          const morphTargetsRelative = this.morphTargetsRelative;
          for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
            _vector.fromBufferAttribute(morphAttribute, j);
            if (morphTargetsRelative) {
              _offset.fromBufferAttribute(position, j);
              _vector.add(_offset);
            }
            maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
          }
        }
      }
      this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
      if (isNaN(this.boundingSphere.radius)) {
        console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
      }
    }
  }
  computeTangents() {
    const index = this.index;
    const attributes = this.attributes;

    // based on http://www.terathon.com/code/tangent.html
    // (per vertex tangents)

    if (index === null || attributes.position === undefined || attributes.normal === undefined || attributes.uv === undefined) {
      console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
      return;
    }
    const positionAttribute = attributes.position;
    const normalAttribute = attributes.normal;
    const uvAttribute = attributes.uv;
    if (this.hasAttribute('tangent') === false) {
      this.setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
    }
    const tangentAttribute = this.getAttribute('tangent');
    const tan1 = [],
      tan2 = [];
    for (let i = 0; i < positionAttribute.count; i++) {
      tan1[i] = new Vector3();
      tan2[i] = new Vector3();
    }
    const vA = new Vector3(),
      vB = new Vector3(),
      vC = new Vector3(),
      uvA = new Vector2(),
      uvB = new Vector2(),
      uvC = new Vector2(),
      sdir = new Vector3(),
      tdir = new Vector3();
    function handleTriangle(a, b, c) {
      vA.fromBufferAttribute(positionAttribute, a);
      vB.fromBufferAttribute(positionAttribute, b);
      vC.fromBufferAttribute(positionAttribute, c);
      uvA.fromBufferAttribute(uvAttribute, a);
      uvB.fromBufferAttribute(uvAttribute, b);
      uvC.fromBufferAttribute(uvAttribute, c);
      vB.sub(vA);
      vC.sub(vA);
      uvB.sub(uvA);
      uvC.sub(uvA);
      const r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

      // silently ignore degenerate uv triangles having coincident or colinear vertices

      if (!isFinite(r)) return;
      sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
      tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);
      tan1[a].add(sdir);
      tan1[b].add(sdir);
      tan1[c].add(sdir);
      tan2[a].add(tdir);
      tan2[b].add(tdir);
      tan2[c].add(tdir);
    }
    let groups = this.groups;
    if (groups.length === 0) {
      groups = [{
        start: 0,
        count: index.count
      }];
    }
    for (let i = 0, il = groups.length; i < il; ++i) {
      const group = groups[i];
      const start = group.start;
      const count = group.count;
      for (let j = start, jl = start + count; j < jl; j += 3) {
        handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
      }
    }
    const tmp = new Vector3(),
      tmp2 = new Vector3();
    const n = new Vector3(),
      n2 = new Vector3();
    function handleVertex(v) {
      n.fromBufferAttribute(normalAttribute, v);
      n2.copy(n);
      const t = tan1[v];

      // Gram-Schmidt orthogonalize

      tmp.copy(t);
      tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

      // Calculate handedness

      tmp2.crossVectors(n2, t);
      const test = tmp2.dot(tan2[v]);
      const w = test < 0.0 ? -1.0 : 1.0;
      tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
    }
    for (let i = 0, il = groups.length; i < il; ++i) {
      const group = groups[i];
      const start = group.start;
      const count = group.count;
      for (let j = start, jl = start + count; j < jl; j += 3) {
        handleVertex(index.getX(j + 0));
        handleVertex(index.getX(j + 1));
        handleVertex(index.getX(j + 2));
      }
    }
  }
  computeVertexNormals() {
    const index = this.index;
    const positionAttribute = this.getAttribute('position');
    if (positionAttribute !== undefined) {
      let normalAttribute = this.getAttribute('normal');
      if (normalAttribute === undefined) {
        normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
        this.setAttribute('normal', normalAttribute);
      } else {
        // reset existing normals to zero

        for (let i = 0, il = normalAttribute.count; i < il; i++) {
          normalAttribute.setXYZ(i, 0, 0, 0);
        }
      }
      const pA = new Vector3(),
        pB = new Vector3(),
        pC = new Vector3();
      const nA = new Vector3(),
        nB = new Vector3(),
        nC = new Vector3();
      const cb = new Vector3(),
        ab = new Vector3();

      // indexed elements

      if (index) {
        for (let i = 0, il = index.count; i < il; i += 3) {
          const vA = index.getX(i + 0);
          const vB = index.getX(i + 1);
          const vC = index.getX(i + 2);
          pA.fromBufferAttribute(positionAttribute, vA);
          pB.fromBufferAttribute(positionAttribute, vB);
          pC.fromBufferAttribute(positionAttribute, vC);
          cb.subVectors(pC, pB);
          ab.subVectors(pA, pB);
          cb.cross(ab);
          nA.fromBufferAttribute(normalAttribute, vA);
          nB.fromBufferAttribute(normalAttribute, vB);
          nC.fromBufferAttribute(normalAttribute, vC);
          nA.add(cb);
          nB.add(cb);
          nC.add(cb);
          normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
          normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
          normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
        }
      } else {
        // non-indexed elements (unconnected triangle soup)

        for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
          pA.fromBufferAttribute(positionAttribute, i + 0);
          pB.fromBufferAttribute(positionAttribute, i + 1);
          pC.fromBufferAttribute(positionAttribute, i + 2);
          cb.subVectors(pC, pB);
          ab.subVectors(pA, pB);
          cb.cross(ab);
          normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
          normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
          normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
        }
      }
      this.normalizeNormals();
      normalAttribute.needsUpdate = true;
    }
  }
  normalizeNormals() {
    const normals = this.attributes.normal;
    for (let i = 0, il = normals.count; i < il; i++) {
      _vector.fromBufferAttribute(normals, i);
      _vector.normalize();
      normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
    }
  }
  toNonIndexed() {
    function convertBufferAttribute(attribute, indices) {
      const array = attribute.array;
      const itemSize = attribute.itemSize;
      const normalized = attribute.normalized;
      const array2 = new array.constructor(indices.length * itemSize);
      let index = 0,
        index2 = 0;
      for (let i = 0, l = indices.length; i < l; i++) {
        if (attribute.isInterleavedBufferAttribute) {
          index = indices[i] * attribute.data.stride + attribute.offset;
        } else {
          index = indices[i] * itemSize;
        }
        for (let j = 0; j < itemSize; j++) {
          array2[index2++] = array[index++];
        }
      }
      return new BufferAttribute(array2, itemSize, normalized);
    }

    //

    if (this.index === null) {
      console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
      return this;
    }
    const geometry2 = new BufferGeometry();
    const indices = this.index.array;
    const attributes = this.attributes;

    // attributes

    for (const name in attributes) {
      const attribute = attributes[name];
      const newAttribute = convertBufferAttribute(attribute, indices);
      geometry2.setAttribute(name, newAttribute);
    }

    // morph attributes

    const morphAttributes = this.morphAttributes;
    for (const name in morphAttributes) {
      const morphArray = [];
      const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

      for (let i = 0, il = morphAttribute.length; i < il; i++) {
        const attribute = morphAttribute[i];
        const newAttribute = convertBufferAttribute(attribute, indices);
        morphArray.push(newAttribute);
      }
      geometry2.morphAttributes[name] = morphArray;
    }
    geometry2.morphTargetsRelative = this.morphTargetsRelative;

    // groups

    const groups = this.groups;
    for (let i = 0, l = groups.length; i < l; i++) {
      const group = groups[i];
      geometry2.addGroup(group.start, group.count, group.materialIndex);
    }
    return geometry2;
  }
  toJSON() {
    const data = {
      metadata: {
        version: 4.6,
        type: 'BufferGeometry',
        generator: 'BufferGeometry.toJSON'
      }
    };

    // standard BufferGeometry serialization

    data.uuid = this.uuid;
    data.type = this.type;
    if (this.name !== '') data.name = this.name;
    if (Object.keys(this.userData).length > 0) data.userData = this.userData;
    if (this.parameters !== undefined) {
      const parameters = this.parameters;
      for (const key in parameters) {
        if (parameters[key] !== undefined) data[key] = parameters[key];
      }
      return data;
    }

    // for simplicity the code assumes attributes are not shared across geometries, see #15811

    data.data = {
      attributes: {}
    };
    const index = this.index;
    if (index !== null) {
      data.data.index = {
        type: index.array.constructor.name,
        array: Array.prototype.slice.call(index.array)
      };
    }
    const attributes = this.attributes;
    for (const key in attributes) {
      const attribute = attributes[key];
      data.data.attributes[key] = attribute.toJSON(data.data);
    }
    const morphAttributes = {};
    let hasMorphAttributes = false;
    for (const key in this.morphAttributes) {
      const attributeArray = this.morphAttributes[key];
      const array = [];
      for (let i = 0, il = attributeArray.length; i < il; i++) {
        const attribute = attributeArray[i];
        array.push(attribute.toJSON(data.data));
      }
      if (array.length > 0) {
        morphAttributes[key] = array;
        hasMorphAttributes = true;
      }
    }
    if (hasMorphAttributes) {
      data.data.morphAttributes = morphAttributes;
      data.data.morphTargetsRelative = this.morphTargetsRelative;
    }
    const groups = this.groups;
    if (groups.length > 0) {
      data.data.groups = JSON.parse(JSON.stringify(groups));
    }
    const boundingSphere = this.boundingSphere;
    if (boundingSphere !== null) {
      data.data.boundingSphere = {
        center: boundingSphere.center.toArray(),
        radius: boundingSphere.radius
      };
    }
    return data;
  }
  clone() {
    return new this.constructor().copy(this);
  }
  copy(source) {
    // reset

    this.index = null;
    this.attributes = {};
    this.morphAttributes = {};
    this.groups = [];
    this.boundingBox = null;
    this.boundingSphere = null;

    // used for storing cloned, shared data

    const data = {};

    // name

    this.name = source.name;

    // index

    const index = source.index;
    if (index !== null) {
      this.setIndex(index.clone(data));
    }

    // attributes

    const attributes = source.attributes;
    for (const name in attributes) {
      const attribute = attributes[name];
      this.setAttribute(name, attribute.clone(data));
    }

    // morph attributes

    const morphAttributes = source.morphAttributes;
    for (const name in morphAttributes) {
      const array = [];
      const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

      for (let i = 0, l = morphAttribute.length; i < l; i++) {
        array.push(morphAttribute[i].clone(data));
      }
      this.morphAttributes[name] = array;
    }
    this.morphTargetsRelative = source.morphTargetsRelative;

    // groups

    const groups = source.groups;
    for (let i = 0, l = groups.length; i < l; i++) {
      const group = groups[i];
      this.addGroup(group.start, group.count, group.materialIndex);
    }

    // bounding box

    const boundingBox = source.boundingBox;
    if (boundingBox !== null) {
      this.boundingBox = boundingBox.clone();
    }

    // bounding sphere

    const boundingSphere = source.boundingSphere;
    if (boundingSphere !== null) {
      this.boundingSphere = boundingSphere.clone();
    }

    // draw range

    this.drawRange.start = source.drawRange.start;
    this.drawRange.count = source.drawRange.count;

    // user data

    this.userData = source.userData;
    return this;
  }
  dispose() {
    this.dispatchEvent({
      type: 'dispose'
    });
  }
}
constructor() {
  super();
  this.isBufferGeometry = true;
  Object.defineProperty(this, 'id', {
    value: _id++
  });
  this.uuid = MathUtils.generateUUID();
  this.name = '';
  this.type = 'BufferGeometry';
  this.index = null;
  this.attributes = {};
  this.morphAttributes = {};
  this.morphTargetsRelative = false;
  this.groups = [];
  this.boundingBox = null;
  this.boundingSphere = null;
  this.drawRange = {
    start: 0,
    count: Infinity
  };
  this.userData = {};
}
constructor() {
  super();
  this.isBufferGeometry = true;
  Object.defineProperty(this, 'id', {
    value: _id++
  });
  this.uuid = MathUtils.generateUUID();
  this.name = '';
  this.type = 'BufferGeometry';
  this.index = null;
  this.attributes = {};
  this.morphAttributes = {};
  this.morphTargetsRelative = false;
  this.groups = [];
  this.boundingBox = null;
  this.boundingSphere = null;
  this.drawRange = {
    start: 0,
    count: Infinity
  };
  this.userData = {};
}
constructor
{
  super();
  this.isBufferGeometry = true;
  Object.defineProperty(this, 'id', {
    value: _id++
  });
  this.uuid = MathUtils.generateUUID();
  this.name = '';
  this.type = 'BufferGeometry';
  this.index = null;
  this.attributes = {};
  this.morphAttributes = {};
  this.morphTargetsRelative = false;
  this.groups = [];
  this.boundingBox = null;
  this.boundingSphere = null;
  this.drawRange = {
    start: 0,
    count: Infinity
  };
  this.userData = {};
}
super();
super()
super
this.isBufferGeometry = true;
this.isBufferGeometry = true
this.isBufferGeometry
this
isBufferGeometry
true
Object.defineProperty(this, 'id', {
  value: _id++
});
Object.defineProperty(this, 'id', {
  value: _id++
})
Object.defineProperty
Object
defineProperty
this
'id'
{
  value: _id++
}
value: _id++
value
_id++
_id
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
this.type = 'BufferGeometry';
this.type = 'BufferGeometry'
this.type
this
type
'BufferGeometry'
this.index = null;
this.index = null
this.index
this
index
null
this.attributes = {};
this.attributes = {}
this.attributes
this
attributes
{}
this.morphAttributes = {};
this.morphAttributes = {}
this.morphAttributes
this
morphAttributes
{}
this.morphTargetsRelative = false;
this.morphTargetsRelative = false
this.morphTargetsRelative
this
morphTargetsRelative
false
this.groups = [];
this.groups = []
this.groups
this
groups
[]
this.boundingBox = null;
this.boundingBox = null
this.boundingBox
this
boundingBox
null
this.boundingSphere = null;
this.boundingSphere = null
this.boundingSphere
this
boundingSphere
null
this.drawRange = {
  start: 0,
  count: Infinity
};
this.drawRange = {
  start: 0,
  count: Infinity
}
this.drawRange
this
drawRange
{
  start: 0,
  count: Infinity
}
start: 0
start
0
count: Infinity
count
Infinity
this.userData = {};
this.userData = {}
this.userData
this
userData
{}
getIndex() {
  return this.index;
}
getIndex() {
  return this.index;
}
getIndex
{
  return this.index;
}
return this.index;
this.index
this
index
setIndex(index) {
  if (Array.isArray(index)) {
    this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
  } else {
    this.index = index;
  }
  return this;
}
setIndex(index) {
  if (Array.isArray(index)) {
    this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
  } else {
    this.index = index;
  }
  return this;
}
setIndex
index
{
  if (Array.isArray(index)) {
    this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
  } else {
    this.index = index;
  }
  return this;
}
if (Array.isArray(index)) {
  this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
} else {
  this.index = index;
}
Array.isArray(index)
Array.isArray
Array
isArray
index
{
  this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
}
this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1)
this.index
this
index
new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1)
arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute
arrayNeedsUint32(index)
arrayNeedsUint32
index
Uint32BufferAttribute
Uint16BufferAttribute
index
1
{
  this.index = index;
}
this.index = index;
this.index = index
this.index
this
index
index
return this;
this
getAttribute(name) {
  return this.attributes[name];
}
getAttribute(name) {
  return this.attributes[name];
}
getAttribute
name
{
  return this.attributes[name];
}
return this.attributes[name];
this.attributes[name]
this.attributes
this
attributes
name
setAttribute(name, attribute) {
  this.attributes[name] = attribute;
  return this;
}
setAttribute(name, attribute) {
  this.attributes[name] = attribute;
  return this;
}
setAttribute
name
attribute
{
  this.attributes[name] = attribute;
  return this;
}
this.attributes[name] = attribute;
this.attributes[name] = attribute
this.attributes[name]
this.attributes
this
attributes
name
attribute
return this;
this
deleteAttribute(name) {
  delete this.attributes[name];
  return this;
}
deleteAttribute(name) {
  delete this.attributes[name];
  return this;
}
deleteAttribute
name
{
  delete this.attributes[name];
  return this;
}
delete this.attributes[name];
delete this.attributes[name]
this.attributes[name]
this.attributes
this
attributes
name
return this;
this
hasAttribute(name) {
  return this.attributes[name] !== undefined;
}
hasAttribute(name) {
  return this.attributes[name] !== undefined;
}
hasAttribute
name
{
  return this.attributes[name] !== undefined;
}
return this.attributes[name] !== undefined;
this.attributes[name] !== undefined
this.attributes[name]
this.attributes
this
attributes
name
undefined
addGroup(start, count, materialIndex = 0) {
  this.groups.push({
    start: start,
    count: count,
    materialIndex: materialIndex
  });
}
addGroup(start, count, materialIndex = 0) {
  this.groups.push({
    start: start,
    count: count,
    materialIndex: materialIndex
  });
}
addGroup
start
count
materialIndex = 0
materialIndex
0
{
  this.groups.push({
    start: start,
    count: count,
    materialIndex: materialIndex
  });
}
this.groups.push({
  start: start,
  count: count,
  materialIndex: materialIndex
});
this.groups.push({
  start: start,
  count: count,
  materialIndex: materialIndex
})
this.groups.push
this.groups
this
groups
push
{
  start: start,
  count: count,
  materialIndex: materialIndex
}
start: start
start
start
count: count
count
count
materialIndex: materialIndex
materialIndex
materialIndex
clearGroups() {
  this.groups = [];
}
clearGroups() {
  this.groups = [];
}
clearGroups
{
  this.groups = [];
}
this.groups = [];
this.groups = []
this.groups
this
groups
[]
setDrawRange(start, count) {
  this.drawRange.start = start;
  this.drawRange.count = count;
}
setDrawRange(start, count) {
  this.drawRange.start = start;
  this.drawRange.count = count;
}
setDrawRange
start
count
{
  this.drawRange.start = start;
  this.drawRange.count = count;
}
this.drawRange.start = start;
this.drawRange.start = start
this.drawRange.start
this.drawRange
this
drawRange
start
start
this.drawRange.count = count;
this.drawRange.count = count
this.drawRange.count
this.drawRange
this
drawRange
count
count
applyMatrix4(matrix) {
  const position = this.attributes.position;
  if (position !== undefined) {
    position.applyMatrix4(matrix);
    position.needsUpdate = true;
  }
  const normal = this.attributes.normal;
  if (normal !== undefined) {
    const normalMatrix = new Matrix3().getNormalMatrix(matrix);
    normal.applyNormalMatrix(normalMatrix);
    normal.needsUpdate = true;
  }
  const tangent = this.attributes.tangent;
  if (tangent !== undefined) {
    tangent.transformDirection(matrix);
    tangent.needsUpdate = true;
  }
  if (this.boundingBox !== null) {
    this.computeBoundingBox();
  }
  if (this.boundingSphere !== null) {
    this.computeBoundingSphere();
  }
  return this;
}
applyMatrix4(matrix) {
  const position = this.attributes.position;
  if (position !== undefined) {
    position.applyMatrix4(matrix);
    position.needsUpdate = true;
  }
  const normal = this.attributes.normal;
  if (normal !== undefined) {
    const normalMatrix = new Matrix3().getNormalMatrix(matrix);
    normal.applyNormalMatrix(normalMatrix);
    normal.needsUpdate = true;
  }
  const tangent = this.attributes.tangent;
  if (tangent !== undefined) {
    tangent.transformDirection(matrix);
    tangent.needsUpdate = true;
  }
  if (this.boundingBox !== null) {
    this.computeBoundingBox();
  }
  if (this.boundingSphere !== null) {
    this.computeBoundingSphere();
  }
  return this;
}
applyMatrix4
matrix
{
  const position = this.attributes.position;
  if (position !== undefined) {
    position.applyMatrix4(matrix);
    position.needsUpdate = true;
  }
  const normal = this.attributes.normal;
  if (normal !== undefined) {
    const normalMatrix = new Matrix3().getNormalMatrix(matrix);
    normal.applyNormalMatrix(normalMatrix);
    normal.needsUpdate = true;
  }
  const tangent = this.attributes.tangent;
  if (tangent !== undefined) {
    tangent.transformDirection(matrix);
    tangent.needsUpdate = true;
  }
  if (this.boundingBox !== null) {
    this.computeBoundingBox();
  }
  if (this.boundingSphere !== null) {
    this.computeBoundingSphere();
  }
  return this;
}
const position = this.attributes.position;
position = this.attributes.position
position
this.attributes.position
this.attributes
this
attributes
position
if (position !== undefined) {
  position.applyMatrix4(matrix);
  position.needsUpdate = true;
}
position !== undefined
position
undefined
{
  position.applyMatrix4(matrix);
  position.needsUpdate = true;
}
position.applyMatrix4(matrix);
position.applyMatrix4(matrix)
position.applyMatrix4
position
applyMatrix4
matrix
position.needsUpdate = true;
position.needsUpdate = true
position.needsUpdate
position
needsUpdate
true
const normal = this.attributes.normal;
normal = this.attributes.normal
normal
this.attributes.normal
this.attributes
this
attributes
normal
if (normal !== undefined) {
  const normalMatrix = new Matrix3().getNormalMatrix(matrix);
  normal.applyNormalMatrix(normalMatrix);
  normal.needsUpdate = true;
}
normal !== undefined
normal
undefined
{
  const normalMatrix = new Matrix3().getNormalMatrix(matrix);
  normal.applyNormalMatrix(normalMatrix);
  normal.needsUpdate = true;
}
const normalMatrix = new Matrix3().getNormalMatrix(matrix);
normalMatrix = new Matrix3().getNormalMatrix(matrix)
normalMatrix
new Matrix3().getNormalMatrix(matrix)
new Matrix3().getNormalMatrix
new Matrix3()
Matrix3
getNormalMatrix
matrix
normal.applyNormalMatrix(normalMatrix);
normal.applyNormalMatrix(normalMatrix)
normal.applyNormalMatrix
normal
applyNormalMatrix
normalMatrix
normal.needsUpdate = true;
normal.needsUpdate = true
normal.needsUpdate
normal
needsUpdate
true
const tangent = this.attributes.tangent;
tangent = this.attributes.tangent
tangent
this.attributes.tangent
this.attributes
this
attributes
tangent
if (tangent !== undefined) {
  tangent.transformDirection(matrix);
  tangent.needsUpdate = true;
}
tangent !== undefined
tangent
undefined
{
  tangent.transformDirection(matrix);
  tangent.needsUpdate = true;
}
tangent.transformDirection(matrix);
tangent.transformDirection(matrix)
tangent.transformDirection
tangent
transformDirection
matrix
tangent.needsUpdate = true;
tangent.needsUpdate = true
tangent.needsUpdate
tangent
needsUpdate
true
if (this.boundingBox !== null) {
  this.computeBoundingBox();
}
this.boundingBox !== null
this.boundingBox
this
boundingBox
null
{
  this.computeBoundingBox();
}
this.computeBoundingBox();
this.computeBoundingBox()
this.computeBoundingBox
this
computeBoundingBox
if (this.boundingSphere !== null) {
  this.computeBoundingSphere();
}
this.boundingSphere !== null
this.boundingSphere
this
boundingSphere
null
{
  this.computeBoundingSphere();
}
this.computeBoundingSphere();
this.computeBoundingSphere()
this.computeBoundingSphere
this
computeBoundingSphere
return this;
this
applyQuaternion(q) {
  _m1.makeRotationFromQuaternion(q);
  this.applyMatrix4(_m1);
  return this;
}
applyQuaternion(q) {
  _m1.makeRotationFromQuaternion(q);
  this.applyMatrix4(_m1);
  return this;
}
applyQuaternion
q
{
  _m1.makeRotationFromQuaternion(q);
  this.applyMatrix4(_m1);
  return this;
}
_m1.makeRotationFromQuaternion(q);
_m1.makeRotationFromQuaternion(q)
_m1.makeRotationFromQuaternion
_m1
makeRotationFromQuaternion
q
this.applyMatrix4(_m1);
this.applyMatrix4(_m1)
this.applyMatrix4
this
applyMatrix4
_m1
return this;
this
rotateX(angle) {
  // rotate geometry around world x-axis

  _m1.makeRotationX(angle);
  this.applyMatrix4(_m1);
  return this;
}
rotateX(angle) {
  // rotate geometry around world x-axis

  _m1.makeRotationX(angle);
  this.applyMatrix4(_m1);
  return this;
}
rotateX
angle
{
  // rotate geometry around world x-axis

  _m1.makeRotationX(angle);
  this.applyMatrix4(_m1);
  return this;
}
// rotate geometry around world x-axis

_m1.makeRotationX(angle);
_m1.makeRotationX(angle)
_m1.makeRotationX
_m1
makeRotationX
angle
this.applyMatrix4(_m1);
this.applyMatrix4(_m1)
this.applyMatrix4
this
applyMatrix4
_m1
return this;
this
rotateY(angle) {
  // rotate geometry around world y-axis

  _m1.makeRotationY(angle);
  this.applyMatrix4(_m1);
  return this;
}
rotateY(angle) {
  // rotate geometry around world y-axis

  _m1.makeRotationY(angle);
  this.applyMatrix4(_m1);
  return this;
}
rotateY
angle
{
  // rotate geometry around world y-axis

  _m1.makeRotationY(angle);
  this.applyMatrix4(_m1);
  return this;
}
// rotate geometry around world y-axis

_m1.makeRotationY(angle);
_m1.makeRotationY(angle)
_m1.makeRotationY
_m1
makeRotationY
angle
this.applyMatrix4(_m1);
this.applyMatrix4(_m1)
this.applyMatrix4
this
applyMatrix4
_m1
return this;
this
rotateZ(angle) {
  // rotate geometry around world z-axis

  _m1.makeRotationZ(angle);
  this.applyMatrix4(_m1);
  return this;
}
rotateZ(angle) {
  // rotate geometry around world z-axis

  _m1.makeRotationZ(angle);
  this.applyMatrix4(_m1);
  return this;
}
rotateZ
angle
{
  // rotate geometry around world z-axis

  _m1.makeRotationZ(angle);
  this.applyMatrix4(_m1);
  return this;
}
// rotate geometry around world z-axis

_m1.makeRotationZ(angle);
_m1.makeRotationZ(angle)
_m1.makeRotationZ
_m1
makeRotationZ
angle
this.applyMatrix4(_m1);
this.applyMatrix4(_m1)
this.applyMatrix4
this
applyMatrix4
_m1
return this;
this
translate(x, y, z) {
  // translate geometry

  _m1.makeTranslation(x, y, z);
  this.applyMatrix4(_m1);
  return this;
}
translate(x, y, z) {
  // translate geometry

  _m1.makeTranslation(x, y, z);
  this.applyMatrix4(_m1);
  return this;
}
translate
x
y
z
{
  // translate geometry

  _m1.makeTranslation(x, y, z);
  this.applyMatrix4(_m1);
  return this;
}
// translate geometry

_m1.makeTranslation(x, y, z);
_m1.makeTranslation(x, y, z)
_m1.makeTranslation
_m1
makeTranslation
x
y
z
this.applyMatrix4(_m1);
this.applyMatrix4(_m1)
this.applyMatrix4
this
applyMatrix4
_m1
return this;
this
scale(x, y, z) {
  // scale geometry

  _m1.makeScale(x, y, z);
  this.applyMatrix4(_m1);
  return this;
}
scale(x, y, z) {
  // scale geometry

  _m1.makeScale(x, y, z);
  this.applyMatrix4(_m1);
  return this;
}
scale
x
y
z
{
  // scale geometry

  _m1.makeScale(x, y, z);
  this.applyMatrix4(_m1);
  return this;
}
// scale geometry

_m1.makeScale(x, y, z);
_m1.makeScale(x, y, z)
_m1.makeScale
_m1
makeScale
x
y
z
this.applyMatrix4(_m1);
this.applyMatrix4(_m1)
this.applyMatrix4
this
applyMatrix4
_m1
return this;
this
lookAt(vector) {
  _obj.lookAt(vector);
  _obj.updateMatrix();
  this.applyMatrix4(_obj.matrix);
  return this;
}
lookAt(vector) {
  _obj.lookAt(vector);
  _obj.updateMatrix();
  this.applyMatrix4(_obj.matrix);
  return this;
}
lookAt
vector
{
  _obj.lookAt(vector);
  _obj.updateMatrix();
  this.applyMatrix4(_obj.matrix);
  return this;
}
_obj.lookAt(vector);
_obj.lookAt(vector)
_obj.lookAt
_obj
lookAt
vector
_obj.updateMatrix();
_obj.updateMatrix()
_obj.updateMatrix
_obj
updateMatrix
this.applyMatrix4(_obj.matrix);
this.applyMatrix4(_obj.matrix)
this.applyMatrix4
this
applyMatrix4
_obj.matrix
_obj
matrix
return this;
this
center() {
  this.computeBoundingBox();
  this.boundingBox.getCenter(_offset).negate();
  this.translate(_offset.x, _offset.y, _offset.z);
  return this;
}
center() {
  this.computeBoundingBox();
  this.boundingBox.getCenter(_offset).negate();
  this.translate(_offset.x, _offset.y, _offset.z);
  return this;
}
center
{
  this.computeBoundingBox();
  this.boundingBox.getCenter(_offset).negate();
  this.translate(_offset.x, _offset.y, _offset.z);
  return this;
}
this.computeBoundingBox();
this.computeBoundingBox()
this.computeBoundingBox
this
computeBoundingBox
this.boundingBox.getCenter(_offset).negate();
this.boundingBox.getCenter(_offset).negate()
this.boundingBox.getCenter(_offset).negate
this.boundingBox.getCenter(_offset)
this.boundingBox.getCenter
this.boundingBox
this
boundingBox
getCenter
_offset
negate
this.translate(_offset.x, _offset.y, _offset.z);
this.translate(_offset.x, _offset.y, _offset.z)
this.translate
this
translate
_offset.x
_offset
x
_offset.y
_offset
y
_offset.z
_offset
z
return this;
this
setFromPoints(points) {
  const position = [];
  for (let i = 0, l = points.length; i < l; i++) {
    const point = points[i];
    position.push(point.x, point.y, point.z || 0);
  }
  this.setAttribute('position', new Float32BufferAttribute(position, 3));
  return this;
}
setFromPoints(points) {
  const position = [];
  for (let i = 0, l = points.length; i < l; i++) {
    const point = points[i];
    position.push(point.x, point.y, point.z || 0);
  }
  this.setAttribute('position', new Float32BufferAttribute(position, 3));
  return this;
}
setFromPoints
points
{
  const position = [];
  for (let i = 0, l = points.length; i < l; i++) {
    const point = points[i];
    position.push(point.x, point.y, point.z || 0);
  }
  this.setAttribute('position', new Float32BufferAttribute(position, 3));
  return this;
}
const position = [];
position = []
position
[]
for (let i = 0, l = points.length; i < l; i++) {
  const point = points[i];
  position.push(point.x, point.y, point.z || 0);
}
let i = 0,
  l = points.length;
i = 0
i
0
l = points.length
l
points.length
points
length
i < l
i
l
i++
i
{
  const point = points[i];
  position.push(point.x, point.y, point.z || 0);
}
const point = points[i];
point = points[i]
point
points[i]
points
i
position.push(point.x, point.y, point.z || 0);
position.push(point.x, point.y, point.z || 0)
position.push
position
push
point.x
point
x
point.y
point
y
point.z || 0
point.z
point
z
0
this.setAttribute('position', new Float32BufferAttribute(position, 3));
this.setAttribute('position', new Float32BufferAttribute(position, 3))
this.setAttribute
this
setAttribute
'position'
new Float32BufferAttribute(position, 3)
Float32BufferAttribute
position
3
return this;
this
computeBoundingBox() {
  if (this.boundingBox === null) {
    this.boundingBox = new Box3();
  }
  const position = this.attributes.position;
  const morphAttributesPosition = this.morphAttributes.position;
  if (position && position.isGLBufferAttribute) {
    console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
    this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity));
    return;
  }
  if (position !== undefined) {
    this.boundingBox.setFromBufferAttribute(position);

    // process morph attributes if present

    if (morphAttributesPosition) {
      for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
        const morphAttribute = morphAttributesPosition[i];
        _box.setFromBufferAttribute(morphAttribute);
        if (this.morphTargetsRelative) {
          _vector.addVectors(this.boundingBox.min, _box.min);
          this.boundingBox.expandByPoint(_vector);
          _vector.addVectors(this.boundingBox.max, _box.max);
          this.boundingBox.expandByPoint(_vector);
        } else {
          this.boundingBox.expandByPoint(_box.min);
          this.boundingBox.expandByPoint(_box.max);
        }
      }
    }
  } else {
    this.boundingBox.makeEmpty();
  }
  if (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) {
    console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
  }
}
computeBoundingBox() {
  if (this.boundingBox === null) {
    this.boundingBox = new Box3();
  }
  const position = this.attributes.position;
  const morphAttributesPosition = this.morphAttributes.position;
  if (position && position.isGLBufferAttribute) {
    console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
    this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity));
    return;
  }
  if (position !== undefined) {
    this.boundingBox.setFromBufferAttribute(position);

    // process morph attributes if present

    if (morphAttributesPosition) {
      for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
        const morphAttribute = morphAttributesPosition[i];
        _box.setFromBufferAttribute(morphAttribute);
        if (this.morphTargetsRelative) {
          _vector.addVectors(this.boundingBox.min, _box.min);
          this.boundingBox.expandByPoint(_vector);
          _vector.addVectors(this.boundingBox.max, _box.max);
          this.boundingBox.expandByPoint(_vector);
        } else {
          this.boundingBox.expandByPoint(_box.min);
          this.boundingBox.expandByPoint(_box.max);
        }
      }
    }
  } else {
    this.boundingBox.makeEmpty();
  }
  if (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) {
    console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
  }
}
computeBoundingBox
{
  if (this.boundingBox === null) {
    this.boundingBox = new Box3();
  }
  const position = this.attributes.position;
  const morphAttributesPosition = this.morphAttributes.position;
  if (position && position.isGLBufferAttribute) {
    console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
    this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity));
    return;
  }
  if (position !== undefined) {
    this.boundingBox.setFromBufferAttribute(position);

    // process morph attributes if present

    if (morphAttributesPosition) {
      for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
        const morphAttribute = morphAttributesPosition[i];
        _box.setFromBufferAttribute(morphAttribute);
        if (this.morphTargetsRelative) {
          _vector.addVectors(this.boundingBox.min, _box.min);
          this.boundingBox.expandByPoint(_vector);
          _vector.addVectors(this.boundingBox.max, _box.max);
          this.boundingBox.expandByPoint(_vector);
        } else {
          this.boundingBox.expandByPoint(_box.min);
          this.boundingBox.expandByPoint(_box.max);
        }
      }
    }
  } else {
    this.boundingBox.makeEmpty();
  }
  if (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) {
    console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
  }
}
if (this.boundingBox === null) {
  this.boundingBox = new Box3();
}
this.boundingBox === null
this.boundingBox
this
boundingBox
null
{
  this.boundingBox = new Box3();
}
this.boundingBox = new Box3();
this.boundingBox = new Box3()
this.boundingBox
this
boundingBox
new Box3()
Box3
const position = this.attributes.position;
position = this.attributes.position
position
this.attributes.position
this.attributes
this
attributes
position
const morphAttributesPosition = this.morphAttributes.position;
morphAttributesPosition = this.morphAttributes.position
morphAttributesPosition
this.morphAttributes.position
this.morphAttributes
this
morphAttributes
position
if (position && position.isGLBufferAttribute) {
  console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
  this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity));
  return;
}
position && position.isGLBufferAttribute
position
position.isGLBufferAttribute
position
isGLBufferAttribute
{
  console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
  this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity));
  return;
}
console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this)
console.error
console
error
'THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.'
this
this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity));
this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity))
this.boundingBox.set
this.boundingBox
this
boundingBox
set
new Vector3(-Infinity, -Infinity, -Infinity)
Vector3
-Infinity
Infinity
-Infinity
Infinity
-Infinity
Infinity
new Vector3(+Infinity, +Infinity, +Infinity)
Vector3
+Infinity
Infinity
+Infinity
Infinity
+Infinity
Infinity
return;
if (position !== undefined) {
  this.boundingBox.setFromBufferAttribute(position);

  // process morph attributes if present

  if (morphAttributesPosition) {
    for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
      const morphAttribute = morphAttributesPosition[i];
      _box.setFromBufferAttribute(morphAttribute);
      if (this.morphTargetsRelative) {
        _vector.addVectors(this.boundingBox.min, _box.min);
        this.boundingBox.expandByPoint(_vector);
        _vector.addVectors(this.boundingBox.max, _box.max);
        this.boundingBox.expandByPoint(_vector);
      } else {
        this.boundingBox.expandByPoint(_box.min);
        this.boundingBox.expandByPoint(_box.max);
      }
    }
  }
} else {
  this.boundingBox.makeEmpty();
}
position !== undefined
position
undefined
{
  this.boundingBox.setFromBufferAttribute(position);

  // process morph attributes if present

  if (morphAttributesPosition) {
    for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
      const morphAttribute = morphAttributesPosition[i];
      _box.setFromBufferAttribute(morphAttribute);
      if (this.morphTargetsRelative) {
        _vector.addVectors(this.boundingBox.min, _box.min);
        this.boundingBox.expandByPoint(_vector);
        _vector.addVectors(this.boundingBox.max, _box.max);
        this.boundingBox.expandByPoint(_vector);
      } else {
        this.boundingBox.expandByPoint(_box.min);
        this.boundingBox.expandByPoint(_box.max);
      }
    }
  }
}
this.boundingBox.setFromBufferAttribute(position);

// process morph attributes if present
this.boundingBox.setFromBufferAttribute(position)
this.boundingBox.setFromBufferAttribute
this.boundingBox
this
boundingBox
setFromBufferAttribute
position
// process morph attributes if present

if (morphAttributesPosition) {
  for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
    const morphAttribute = morphAttributesPosition[i];
    _box.setFromBufferAttribute(morphAttribute);
    if (this.morphTargetsRelative) {
      _vector.addVectors(this.boundingBox.min, _box.min);
      this.boundingBox.expandByPoint(_vector);
      _vector.addVectors(this.boundingBox.max, _box.max);
      this.boundingBox.expandByPoint(_vector);
    } else {
      this.boundingBox.expandByPoint(_box.min);
      this.boundingBox.expandByPoint(_box.max);
    }
  }
}
morphAttributesPosition
{
  for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
    const morphAttribute = morphAttributesPosition[i];
    _box.setFromBufferAttribute(morphAttribute);
    if (this.morphTargetsRelative) {
      _vector.addVectors(this.boundingBox.min, _box.min);
      this.boundingBox.expandByPoint(_vector);
      _vector.addVectors(this.boundingBox.max, _box.max);
      this.boundingBox.expandByPoint(_vector);
    } else {
      this.boundingBox.expandByPoint(_box.min);
      this.boundingBox.expandByPoint(_box.max);
    }
  }
}
for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
  const morphAttribute = morphAttributesPosition[i];
  _box.setFromBufferAttribute(morphAttribute);
  if (this.morphTargetsRelative) {
    _vector.addVectors(this.boundingBox.min, _box.min);
    this.boundingBox.expandByPoint(_vector);
    _vector.addVectors(this.boundingBox.max, _box.max);
    this.boundingBox.expandByPoint(_vector);
  } else {
    this.boundingBox.expandByPoint(_box.min);
    this.boundingBox.expandByPoint(_box.max);
  }
}
let i = 0,
  il = morphAttributesPosition.length;
i = 0
i
0
il = morphAttributesPosition.length
il
morphAttributesPosition.length
morphAttributesPosition
length
i < il
i
il
i++
i
{
  const morphAttribute = morphAttributesPosition[i];
  _box.setFromBufferAttribute(morphAttribute);
  if (this.morphTargetsRelative) {
    _vector.addVectors(this.boundingBox.min, _box.min);
    this.boundingBox.expandByPoint(_vector);
    _vector.addVectors(this.boundingBox.max, _box.max);
    this.boundingBox.expandByPoint(_vector);
  } else {
    this.boundingBox.expandByPoint(_box.min);
    this.boundingBox.expandByPoint(_box.max);
  }
}
const morphAttribute = morphAttributesPosition[i];
morphAttribute = morphAttributesPosition[i]
morphAttribute
morphAttributesPosition[i]
morphAttributesPosition
i
_box.setFromBufferAttribute(morphAttribute);
_box.setFromBufferAttribute(morphAttribute)
_box.setFromBufferAttribute
_box
setFromBufferAttribute
morphAttribute
if (this.morphTargetsRelative) {
  _vector.addVectors(this.boundingBox.min, _box.min);
  this.boundingBox.expandByPoint(_vector);
  _vector.addVectors(this.boundingBox.max, _box.max);
  this.boundingBox.expandByPoint(_vector);
} else {
  this.boundingBox.expandByPoint(_box.min);
  this.boundingBox.expandByPoint(_box.max);
}
this.morphTargetsRelative
this
morphTargetsRelative
{
  _vector.addVectors(this.boundingBox.min, _box.min);
  this.boundingBox.expandByPoint(_vector);
  _vector.addVectors(this.boundingBox.max, _box.max);
  this.boundingBox.expandByPoint(_vector);
}
_vector.addVectors(this.boundingBox.min, _box.min);
_vector.addVectors(this.boundingBox.min, _box.min)
_vector.addVectors
_vector
addVectors
this.boundingBox.min
this.boundingBox
this
boundingBox
min
_box.min
_box
min
this.boundingBox.expandByPoint(_vector);
this.boundingBox.expandByPoint(_vector)
this.boundingBox.expandByPoint
this.boundingBox
this
boundingBox
expandByPoint
_vector
_vector.addVectors(this.boundingBox.max, _box.max);
_vector.addVectors(this.boundingBox.max, _box.max)
_vector.addVectors
_vector
addVectors
this.boundingBox.max
this.boundingBox
this
boundingBox
max
_box.max
_box
max
this.boundingBox.expandByPoint(_vector);
this.boundingBox.expandByPoint(_vector)
this.boundingBox.expandByPoint
this.boundingBox
this
boundingBox
expandByPoint
_vector
{
  this.boundingBox.expandByPoint(_box.min);
  this.boundingBox.expandByPoint(_box.max);
}
this.boundingBox.expandByPoint(_box.min);
this.boundingBox.expandByPoint(_box.min)
this.boundingBox.expandByPoint
this.boundingBox
this
boundingBox
expandByPoint
_box.min
_box
min
this.boundingBox.expandByPoint(_box.max);
this.boundingBox.expandByPoint(_box.max)
this.boundingBox.expandByPoint
this.boundingBox
this
boundingBox
expandByPoint
_box.max
_box
max
{
  this.boundingBox.makeEmpty();
}
this.boundingBox.makeEmpty();
this.boundingBox.makeEmpty()
this.boundingBox.makeEmpty
this.boundingBox
this
boundingBox
makeEmpty
if (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) {
  console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
}
isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)
isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y)
isNaN(this.boundingBox.min.x)
isNaN
this.boundingBox.min.x
this.boundingBox.min
this.boundingBox
this
boundingBox
min
x
isNaN(this.boundingBox.min.y)
isNaN
this.boundingBox.min.y
this.boundingBox.min
this.boundingBox
this
boundingBox
min
y
isNaN(this.boundingBox.min.z)
isNaN
this.boundingBox.min.z
this.boundingBox.min
this.boundingBox
this
boundingBox
min
z
{
  console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
}
console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this)
console.error
console
error
'THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.'
this
computeBoundingSphere() {
  if (this.boundingSphere === null) {
    this.boundingSphere = new Sphere();
  }
  const position = this.attributes.position;
  const morphAttributesPosition = this.morphAttributes.position;
  if (position && position.isGLBufferAttribute) {
    console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
    this.boundingSphere.set(new Vector3(), Infinity);
    return;
  }
  if (position) {
    // first, find the center of the bounding sphere

    const center = this.boundingSphere.center;
    _box.setFromBufferAttribute(position);

    // process morph attributes if present

    if (morphAttributesPosition) {
      for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
        const morphAttribute = morphAttributesPosition[i];
        _boxMorphTargets.setFromBufferAttribute(morphAttribute);
        if (this.morphTargetsRelative) {
          _vector.addVectors(_box.min, _boxMorphTargets.min);
          _box.expandByPoint(_vector);
          _vector.addVectors(_box.max, _boxMorphTargets.max);
          _box.expandByPoint(_vector);
        } else {
          _box.expandByPoint(_boxMorphTargets.min);
          _box.expandByPoint(_boxMorphTargets.max);
        }
      }
    }
    _box.getCenter(center);

    // second, try to find a boundingSphere with a radius smaller than the
    // boundingSphere of the boundingBox: sqrt(3) smaller in the best case

    let maxRadiusSq = 0;
    for (let i = 0, il = position.count; i < il; i++) {
      _vector.fromBufferAttribute(position, i);
      maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
    }

    // process morph attributes if present

    if (morphAttributesPosition) {
      for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
        const morphAttribute = morphAttributesPosition[i];
        const morphTargetsRelative = this.morphTargetsRelative;
        for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
          _vector.fromBufferAttribute(morphAttribute, j);
          if (morphTargetsRelative) {
            _offset.fromBufferAttribute(position, j);
            _vector.add(_offset);
          }
          maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
        }
      }
    }
    this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
    if (isNaN(this.boundingSphere.radius)) {
      console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
    }
  }
}
computeBoundingSphere() {
  if (this.boundingSphere === null) {
    this.boundingSphere = new Sphere();
  }
  const position = this.attributes.position;
  const morphAttributesPosition = this.morphAttributes.position;
  if (position && position.isGLBufferAttribute) {
    console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
    this.boundingSphere.set(new Vector3(), Infinity);
    return;
  }
  if (position) {
    // first, find the center of the bounding sphere

    const center = this.boundingSphere.center;
    _box.setFromBufferAttribute(position);

    // process morph attributes if present

    if (morphAttributesPosition) {
      for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
        const morphAttribute = morphAttributesPosition[i];
        _boxMorphTargets.setFromBufferAttribute(morphAttribute);
        if (this.morphTargetsRelative) {
          _vector.addVectors(_box.min, _boxMorphTargets.min);
          _box.expandByPoint(_vector);
          _vector.addVectors(_box.max, _boxMorphTargets.max);
          _box.expandByPoint(_vector);
        } else {
          _box.expandByPoint(_boxMorphTargets.min);
          _box.expandByPoint(_boxMorphTargets.max);
        }
      }
    }
    _box.getCenter(center);

    // second, try to find a boundingSphere with a radius smaller than the
    // boundingSphere of the boundingBox: sqrt(3) smaller in the best case

    let maxRadiusSq = 0;
    for (let i = 0, il = position.count; i < il; i++) {
      _vector.fromBufferAttribute(position, i);
      maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
    }

    // process morph attributes if present

    if (morphAttributesPosition) {
      for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
        const morphAttribute = morphAttributesPosition[i];
        const morphTargetsRelative = this.morphTargetsRelative;
        for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
          _vector.fromBufferAttribute(morphAttribute, j);
          if (morphTargetsRelative) {
            _offset.fromBufferAttribute(position, j);
            _vector.add(_offset);
          }
          maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
        }
      }
    }
    this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
    if (isNaN(this.boundingSphere.radius)) {
      console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
    }
  }
}
computeBoundingSphere
{
  if (this.boundingSphere === null) {
    this.boundingSphere = new Sphere();
  }
  const position = this.attributes.position;
  const morphAttributesPosition = this.morphAttributes.position;
  if (position && position.isGLBufferAttribute) {
    console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
    this.boundingSphere.set(new Vector3(), Infinity);
    return;
  }
  if (position) {
    // first, find the center of the bounding sphere

    const center = this.boundingSphere.center;
    _box.setFromBufferAttribute(position);

    // process morph attributes if present

    if (morphAttributesPosition) {
      for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
        const morphAttribute = morphAttributesPosition[i];
        _boxMorphTargets.setFromBufferAttribute(morphAttribute);
        if (this.morphTargetsRelative) {
          _vector.addVectors(_box.min, _boxMorphTargets.min);
          _box.expandByPoint(_vector);
          _vector.addVectors(_box.max, _boxMorphTargets.max);
          _box.expandByPoint(_vector);
        } else {
          _box.expandByPoint(_boxMorphTargets.min);
          _box.expandByPoint(_boxMorphTargets.max);
        }
      }
    }
    _box.getCenter(center);

    // second, try to find a boundingSphere with a radius smaller than the
    // boundingSphere of the boundingBox: sqrt(3) smaller in the best case

    let maxRadiusSq = 0;
    for (let i = 0, il = position.count; i < il; i++) {
      _vector.fromBufferAttribute(position, i);
      maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
    }

    // process morph attributes if present

    if (morphAttributesPosition) {
      for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
        const morphAttribute = morphAttributesPosition[i];
        const morphTargetsRelative = this.morphTargetsRelative;
        for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
          _vector.fromBufferAttribute(morphAttribute, j);
          if (morphTargetsRelative) {
            _offset.fromBufferAttribute(position, j);
            _vector.add(_offset);
          }
          maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
        }
      }
    }
    this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
    if (isNaN(this.boundingSphere.radius)) {
      console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
    }
  }
}
if (this.boundingSphere === null) {
  this.boundingSphere = new Sphere();
}
this.boundingSphere === null
this.boundingSphere
this
boundingSphere
null
{
  this.boundingSphere = new Sphere();
}
this.boundingSphere = new Sphere();
this.boundingSphere = new Sphere()
this.boundingSphere
this
boundingSphere
new Sphere()
Sphere
const position = this.attributes.position;
position = this.attributes.position
position
this.attributes.position
this.attributes
this
attributes
position
const morphAttributesPosition = this.morphAttributes.position;
morphAttributesPosition = this.morphAttributes.position
morphAttributesPosition
this.morphAttributes.position
this.morphAttributes
this
morphAttributes
position
if (position && position.isGLBufferAttribute) {
  console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
  this.boundingSphere.set(new Vector3(), Infinity);
  return;
}
position && position.isGLBufferAttribute
position
position.isGLBufferAttribute
position
isGLBufferAttribute
{
  console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
  this.boundingSphere.set(new Vector3(), Infinity);
  return;
}
console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this)
console.error
console
error
'THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.'
this
this.boundingSphere.set(new Vector3(), Infinity);
this.boundingSphere.set(new Vector3(), Infinity)
this.boundingSphere.set
this.boundingSphere
this
boundingSphere
set
new Vector3()
Vector3
Infinity
return;
if (position) {
  // first, find the center of the bounding sphere

  const center = this.boundingSphere.center;
  _box.setFromBufferAttribute(position);

  // process morph attributes if present

  if (morphAttributesPosition) {
    for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
      const morphAttribute = morphAttributesPosition[i];
      _boxMorphTargets.setFromBufferAttribute(morphAttribute);
      if (this.morphTargetsRelative) {
        _vector.addVectors(_box.min, _boxMorphTargets.min);
        _box.expandByPoint(_vector);
        _vector.addVectors(_box.max, _boxMorphTargets.max);
        _box.expandByPoint(_vector);
      } else {
        _box.expandByPoint(_boxMorphTargets.min);
        _box.expandByPoint(_boxMorphTargets.max);
      }
    }
  }
  _box.getCenter(center);

  // second, try to find a boundingSphere with a radius smaller than the
  // boundingSphere of the boundingBox: sqrt(3) smaller in the best case

  let maxRadiusSq = 0;
  for (let i = 0, il = position.count; i < il; i++) {
    _vector.fromBufferAttribute(position, i);
    maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
  }

  // process morph attributes if present

  if (morphAttributesPosition) {
    for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
      const morphAttribute = morphAttributesPosition[i];
      const morphTargetsRelative = this.morphTargetsRelative;
      for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
        _vector.fromBufferAttribute(morphAttribute, j);
        if (morphTargetsRelative) {
          _offset.fromBufferAttribute(position, j);
          _vector.add(_offset);
        }
        maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
      }
    }
  }
  this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
  if (isNaN(this.boundingSphere.radius)) {
    console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
  }
}
position
{
  // first, find the center of the bounding sphere

  const center = this.boundingSphere.center;
  _box.setFromBufferAttribute(position);

  // process morph attributes if present

  if (morphAttributesPosition) {
    for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
      const morphAttribute = morphAttributesPosition[i];
      _boxMorphTargets.setFromBufferAttribute(morphAttribute);
      if (this.morphTargetsRelative) {
        _vector.addVectors(_box.min, _boxMorphTargets.min);
        _box.expandByPoint(_vector);
        _vector.addVectors(_box.max, _boxMorphTargets.max);
        _box.expandByPoint(_vector);
      } else {
        _box.expandByPoint(_boxMorphTargets.min);
        _box.expandByPoint(_boxMorphTargets.max);
      }
    }
  }
  _box.getCenter(center);

  // second, try to find a boundingSphere with a radius smaller than the
  // boundingSphere of the boundingBox: sqrt(3) smaller in the best case

  let maxRadiusSq = 0;
  for (let i = 0, il = position.count; i < il; i++) {
    _vector.fromBufferAttribute(position, i);
    maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
  }

  // process morph attributes if present

  if (morphAttributesPosition) {
    for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
      const morphAttribute = morphAttributesPosition[i];
      const morphTargetsRelative = this.morphTargetsRelative;
      for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
        _vector.fromBufferAttribute(morphAttribute, j);
        if (morphTargetsRelative) {
          _offset.fromBufferAttribute(position, j);
          _vector.add(_offset);
        }
        maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
      }
    }
  }
  this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
  if (isNaN(this.boundingSphere.radius)) {
    console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
  }
}
// first, find the center of the bounding sphere

const center = this.boundingSphere.center;
center = this.boundingSphere.center
center
this.boundingSphere.center
this.boundingSphere
this
boundingSphere
center
_box.setFromBufferAttribute(position);

// process morph attributes if present
_box.setFromBufferAttribute(position)
_box.setFromBufferAttribute
_box
setFromBufferAttribute
position
// process morph attributes if present

if (morphAttributesPosition) {
  for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
    const morphAttribute = morphAttributesPosition[i];
    _boxMorphTargets.setFromBufferAttribute(morphAttribute);
    if (this.morphTargetsRelative) {
      _vector.addVectors(_box.min, _boxMorphTargets.min);
      _box.expandByPoint(_vector);
      _vector.addVectors(_box.max, _boxMorphTargets.max);
      _box.expandByPoint(_vector);
    } else {
      _box.expandByPoint(_boxMorphTargets.min);
      _box.expandByPoint(_boxMorphTargets.max);
    }
  }
}
morphAttributesPosition
{
  for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
    const morphAttribute = morphAttributesPosition[i];
    _boxMorphTargets.setFromBufferAttribute(morphAttribute);
    if (this.morphTargetsRelative) {
      _vector.addVectors(_box.min, _boxMorphTargets.min);
      _box.expandByPoint(_vector);
      _vector.addVectors(_box.max, _boxMorphTargets.max);
      _box.expandByPoint(_vector);
    } else {
      _box.expandByPoint(_boxMorphTargets.min);
      _box.expandByPoint(_boxMorphTargets.max);
    }
  }
}
for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
  const morphAttribute = morphAttributesPosition[i];
  _boxMorphTargets.setFromBufferAttribute(morphAttribute);
  if (this.morphTargetsRelative) {
    _vector.addVectors(_box.min, _boxMorphTargets.min);
    _box.expandByPoint(_vector);
    _vector.addVectors(_box.max, _boxMorphTargets.max);
    _box.expandByPoint(_vector);
  } else {
    _box.expandByPoint(_boxMorphTargets.min);
    _box.expandByPoint(_boxMorphTargets.max);
  }
}
let i = 0,
  il = morphAttributesPosition.length;
i = 0
i
0
il = morphAttributesPosition.length
il
morphAttributesPosition.length
morphAttributesPosition
length
i < il
i
il
i++
i
{
  const morphAttribute = morphAttributesPosition[i];
  _boxMorphTargets.setFromBufferAttribute(morphAttribute);
  if (this.morphTargetsRelative) {
    _vector.addVectors(_box.min, _boxMorphTargets.min);
    _box.expandByPoint(_vector);
    _vector.addVectors(_box.max, _boxMorphTargets.max);
    _box.expandByPoint(_vector);
  } else {
    _box.expandByPoint(_boxMorphTargets.min);
    _box.expandByPoint(_boxMorphTargets.max);
  }
}
const morphAttribute = morphAttributesPosition[i];
morphAttribute = morphAttributesPosition[i]
morphAttribute
morphAttributesPosition[i]
morphAttributesPosition
i
_boxMorphTargets.setFromBufferAttribute(morphAttribute);
_boxMorphTargets.setFromBufferAttribute(morphAttribute)
_boxMorphTargets.setFromBufferAttribute
_boxMorphTargets
setFromBufferAttribute
morphAttribute
if (this.morphTargetsRelative) {
  _vector.addVectors(_box.min, _boxMorphTargets.min);
  _box.expandByPoint(_vector);
  _vector.addVectors(_box.max, _boxMorphTargets.max);
  _box.expandByPoint(_vector);
} else {
  _box.expandByPoint(_boxMorphTargets.min);
  _box.expandByPoint(_boxMorphTargets.max);
}
this.morphTargetsRelative
this
morphTargetsRelative
{
  _vector.addVectors(_box.min, _boxMorphTargets.min);
  _box.expandByPoint(_vector);
  _vector.addVectors(_box.max, _boxMorphTargets.max);
  _box.expandByPoint(_vector);
}
_vector.addVectors(_box.min, _boxMorphTargets.min);
_vector.addVectors(_box.min, _boxMorphTargets.min)
_vector.addVectors
_vector
addVectors
_box.min
_box
min
_boxMorphTargets.min
_boxMorphTargets
min
_box.expandByPoint(_vector);
_box.expandByPoint(_vector)
_box.expandByPoint
_box
expandByPoint
_vector
_vector.addVectors(_box.max, _boxMorphTargets.max);
_vector.addVectors(_box.max, _boxMorphTargets.max)
_vector.addVectors
_vector
addVectors
_box.max
_box
max
_boxMorphTargets.max
_boxMorphTargets
max
_box.expandByPoint(_vector);
_box.expandByPoint(_vector)
_box.expandByPoint
_box
expandByPoint
_vector
{
  _box.expandByPoint(_boxMorphTargets.min);
  _box.expandByPoint(_boxMorphTargets.max);
}
_box.expandByPoint(_boxMorphTargets.min);
_box.expandByPoint(_boxMorphTargets.min)
_box.expandByPoint
_box
expandByPoint
_boxMorphTargets.min
_boxMorphTargets
min
_box.expandByPoint(_boxMorphTargets.max);
_box.expandByPoint(_boxMorphTargets.max)
_box.expandByPoint
_box
expandByPoint
_boxMorphTargets.max
_boxMorphTargets
max
_box.getCenter(center);

// second, try to find a boundingSphere with a radius smaller than the
// boundingSphere of the boundingBox: sqrt(3) smaller in the best case
_box.getCenter(center)
_box.getCenter
_box
getCenter
center
// second, try to find a boundingSphere with a radius smaller than the
// boundingSphere of the boundingBox: sqrt(3) smaller in the best case

let maxRadiusSq = 0;
maxRadiusSq = 0
maxRadiusSq
0
for (let i = 0, il = position.count; i < il; i++) {
  _vector.fromBufferAttribute(position, i);
  maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
}

// process morph attributes if present
let i = 0,
  il = position.count;
i = 0
i
0
il = position.count
il
position.count
position
count
i < il
i
il
i++
i
{
  _vector.fromBufferAttribute(position, i);
  maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
}
_vector.fromBufferAttribute(position, i);
_vector.fromBufferAttribute(position, i)
_vector.fromBufferAttribute
_vector
fromBufferAttribute
position
i
maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector))
maxRadiusSq
Math.max(maxRadiusSq, center.distanceToSquared(_vector))
Math.max
Math
max
maxRadiusSq
center.distanceToSquared(_vector)
center.distanceToSquared
center
distanceToSquared
_vector
// process morph attributes if present

if (morphAttributesPosition) {
  for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
    const morphAttribute = morphAttributesPosition[i];
    const morphTargetsRelative = this.morphTargetsRelative;
    for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
      _vector.fromBufferAttribute(morphAttribute, j);
      if (morphTargetsRelative) {
        _offset.fromBufferAttribute(position, j);
        _vector.add(_offset);
      }
      maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
    }
  }
}
morphAttributesPosition
{
  for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
    const morphAttribute = morphAttributesPosition[i];
    const morphTargetsRelative = this.morphTargetsRelative;
    for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
      _vector.fromBufferAttribute(morphAttribute, j);
      if (morphTargetsRelative) {
        _offset.fromBufferAttribute(position, j);
        _vector.add(_offset);
      }
      maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
    }
  }
}
for (let i = 0, il = morphAttributesPosition.length; i < il; i++) {
  const morphAttribute = morphAttributesPosition[i];
  const morphTargetsRelative = this.morphTargetsRelative;
  for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
    _vector.fromBufferAttribute(morphAttribute, j);
    if (morphTargetsRelative) {
      _offset.fromBufferAttribute(position, j);
      _vector.add(_offset);
    }
    maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
  }
}
let i = 0,
  il = morphAttributesPosition.length;
i = 0
i
0
il = morphAttributesPosition.length
il
morphAttributesPosition.length
morphAttributesPosition
length
i < il
i
il
i++
i
{
  const morphAttribute = morphAttributesPosition[i];
  const morphTargetsRelative = this.morphTargetsRelative;
  for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
    _vector.fromBufferAttribute(morphAttribute, j);
    if (morphTargetsRelative) {
      _offset.fromBufferAttribute(position, j);
      _vector.add(_offset);
    }
    maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
  }
}
const morphAttribute = morphAttributesPosition[i];
morphAttribute = morphAttributesPosition[i]
morphAttribute
morphAttributesPosition[i]
morphAttributesPosition
i
const morphTargetsRelative = this.morphTargetsRelative;
morphTargetsRelative = this.morphTargetsRelative
morphTargetsRelative
this.morphTargetsRelative
this
morphTargetsRelative
for (let j = 0, jl = morphAttribute.count; j < jl; j++) {
  _vector.fromBufferAttribute(morphAttribute, j);
  if (morphTargetsRelative) {
    _offset.fromBufferAttribute(position, j);
    _vector.add(_offset);
  }
  maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
}
let j = 0,
  jl = morphAttribute.count;
j = 0
j
0
jl = morphAttribute.count
jl
morphAttribute.count
morphAttribute
count
j < jl
j
jl
j++
j
{
  _vector.fromBufferAttribute(morphAttribute, j);
  if (morphTargetsRelative) {
    _offset.fromBufferAttribute(position, j);
    _vector.add(_offset);
  }
  maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
}
_vector.fromBufferAttribute(morphAttribute, j);
_vector.fromBufferAttribute(morphAttribute, j)
_vector.fromBufferAttribute
_vector
fromBufferAttribute
morphAttribute
j
if (morphTargetsRelative) {
  _offset.fromBufferAttribute(position, j);
  _vector.add(_offset);
}
morphTargetsRelative
{
  _offset.fromBufferAttribute(position, j);
  _vector.add(_offset);
}
_offset.fromBufferAttribute(position, j);
_offset.fromBufferAttribute(position, j)
_offset.fromBufferAttribute
_offset
fromBufferAttribute
position
j
_vector.add(_offset);
_vector.add(_offset)
_vector.add
_vector
add
_offset
maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector))
maxRadiusSq
Math.max(maxRadiusSq, center.distanceToSquared(_vector))
Math.max
Math
max
maxRadiusSq
center.distanceToSquared(_vector)
center.distanceToSquared
center
distanceToSquared
_vector
this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
this.boundingSphere.radius = Math.sqrt(maxRadiusSq)
this.boundingSphere.radius
this.boundingSphere
this
boundingSphere
radius
Math.sqrt(maxRadiusSq)
Math.sqrt
Math
sqrt
maxRadiusSq
if (isNaN(this.boundingSphere.radius)) {
  console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
}
isNaN(this.boundingSphere.radius)
isNaN
this.boundingSphere.radius
this.boundingSphere
this
boundingSphere
radius
{
  console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
}
console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this)
console.error
console
error
'THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.'
this
computeTangents() {
  const index = this.index;
  const attributes = this.attributes;

  // based on http://www.terathon.com/code/tangent.html
  // (per vertex tangents)

  if (index === null || attributes.position === undefined || attributes.normal === undefined || attributes.uv === undefined) {
    console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
    return;
  }
  const positionAttribute = attributes.position;
  const normalAttribute = attributes.normal;
  const uvAttribute = attributes.uv;
  if (this.hasAttribute('tangent') === false) {
    this.setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
  }
  const tangentAttribute = this.getAttribute('tangent');
  const tan1 = [],
    tan2 = [];
  for (let i = 0; i < positionAttribute.count; i++) {
    tan1[i] = new Vector3();
    tan2[i] = new Vector3();
  }
  const vA = new Vector3(),
    vB = new Vector3(),
    vC = new Vector3(),
    uvA = new Vector2(),
    uvB = new Vector2(),
    uvC = new Vector2(),
    sdir = new Vector3(),
    tdir = new Vector3();
  function handleTriangle(a, b, c) {
    vA.fromBufferAttribute(positionAttribute, a);
    vB.fromBufferAttribute(positionAttribute, b);
    vC.fromBufferAttribute(positionAttribute, c);
    uvA.fromBufferAttribute(uvAttribute, a);
    uvB.fromBufferAttribute(uvAttribute, b);
    uvC.fromBufferAttribute(uvAttribute, c);
    vB.sub(vA);
    vC.sub(vA);
    uvB.sub(uvA);
    uvC.sub(uvA);
    const r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

    // silently ignore degenerate uv triangles having coincident or colinear vertices

    if (!isFinite(r)) return;
    sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
    tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);
    tan1[a].add(sdir);
    tan1[b].add(sdir);
    tan1[c].add(sdir);
    tan2[a].add(tdir);
    tan2[b].add(tdir);
    tan2[c].add(tdir);
  }
  let groups = this.groups;
  if (groups.length === 0) {
    groups = [{
      start: 0,
      count: index.count
    }];
  }
  for (let i = 0, il = groups.length; i < il; ++i) {
    const group = groups[i];
    const start = group.start;
    const count = group.count;
    for (let j = start, jl = start + count; j < jl; j += 3) {
      handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
    }
  }
  const tmp = new Vector3(),
    tmp2 = new Vector3();
  const n = new Vector3(),
    n2 = new Vector3();
  function handleVertex(v) {
    n.fromBufferAttribute(normalAttribute, v);
    n2.copy(n);
    const t = tan1[v];

    // Gram-Schmidt orthogonalize

    tmp.copy(t);
    tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

    // Calculate handedness

    tmp2.crossVectors(n2, t);
    const test = tmp2.dot(tan2[v]);
    const w = test < 0.0 ? -1.0 : 1.0;
    tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
  }
  for (let i = 0, il = groups.length; i < il; ++i) {
    const group = groups[i];
    const start = group.start;
    const count = group.count;
    for (let j = start, jl = start + count; j < jl; j += 3) {
      handleVertex(index.getX(j + 0));
      handleVertex(index.getX(j + 1));
      handleVertex(index.getX(j + 2));
    }
  }
}
computeTangents() {
  const index = this.index;
  const attributes = this.attributes;

  // based on http://www.terathon.com/code/tangent.html
  // (per vertex tangents)

  if (index === null || attributes.position === undefined || attributes.normal === undefined || attributes.uv === undefined) {
    console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
    return;
  }
  const positionAttribute = attributes.position;
  const normalAttribute = attributes.normal;
  const uvAttribute = attributes.uv;
  if (this.hasAttribute('tangent') === false) {
    this.setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
  }
  const tangentAttribute = this.getAttribute('tangent');
  const tan1 = [],
    tan2 = [];
  for (let i = 0; i < positionAttribute.count; i++) {
    tan1[i] = new Vector3();
    tan2[i] = new Vector3();
  }
  const vA = new Vector3(),
    vB = new Vector3(),
    vC = new Vector3(),
    uvA = new Vector2(),
    uvB = new Vector2(),
    uvC = new Vector2(),
    sdir = new Vector3(),
    tdir = new Vector3();
  function handleTriangle(a, b, c) {
    vA.fromBufferAttribute(positionAttribute, a);
    vB.fromBufferAttribute(positionAttribute, b);
    vC.fromBufferAttribute(positionAttribute, c);
    uvA.fromBufferAttribute(uvAttribute, a);
    uvB.fromBufferAttribute(uvAttribute, b);
    uvC.fromBufferAttribute(uvAttribute, c);
    vB.sub(vA);
    vC.sub(vA);
    uvB.sub(uvA);
    uvC.sub(uvA);
    const r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

    // silently ignore degenerate uv triangles having coincident or colinear vertices

    if (!isFinite(r)) return;
    sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
    tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);
    tan1[a].add(sdir);
    tan1[b].add(sdir);
    tan1[c].add(sdir);
    tan2[a].add(tdir);
    tan2[b].add(tdir);
    tan2[c].add(tdir);
  }
  let groups = this.groups;
  if (groups.length === 0) {
    groups = [{
      start: 0,
      count: index.count
    }];
  }
  for (let i = 0, il = groups.length; i < il; ++i) {
    const group = groups[i];
    const start = group.start;
    const count = group.count;
    for (let j = start, jl = start + count; j < jl; j += 3) {
      handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
    }
  }
  const tmp = new Vector3(),
    tmp2 = new Vector3();
  const n = new Vector3(),
    n2 = new Vector3();
  function handleVertex(v) {
    n.fromBufferAttribute(normalAttribute, v);
    n2.copy(n);
    const t = tan1[v];

    // Gram-Schmidt orthogonalize

    tmp.copy(t);
    tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

    // Calculate handedness

    tmp2.crossVectors(n2, t);
    const test = tmp2.dot(tan2[v]);
    const w = test < 0.0 ? -1.0 : 1.0;
    tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
  }
  for (let i = 0, il = groups.length; i < il; ++i) {
    const group = groups[i];
    const start = group.start;
    const count = group.count;
    for (let j = start, jl = start + count; j < jl; j += 3) {
      handleVertex(index.getX(j + 0));
      handleVertex(index.getX(j + 1));
      handleVertex(index.getX(j + 2));
    }
  }
}
function handleTriangle(a, b, c) {
  vA.fromBufferAttribute(positionAttribute, a);
  vB.fromBufferAttribute(positionAttribute, b);
  vC.fromBufferAttribute(positionAttribute, c);
  uvA.fromBufferAttribute(uvAttribute, a);
  uvB.fromBufferAttribute(uvAttribute, b);
  uvC.fromBufferAttribute(uvAttribute, c);
  vB.sub(vA);
  vC.sub(vA);
  uvB.sub(uvA);
  uvC.sub(uvA);
  const r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

  // silently ignore degenerate uv triangles having coincident or colinear vertices

  if (!isFinite(r)) return;
  sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
  tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);
  tan1[a].add(sdir);
  tan1[b].add(sdir);
  tan1[c].add(sdir);
  tan2[a].add(tdir);
  tan2[b].add(tdir);
  tan2[c].add(tdir);
}
handleTriangle
a
b
c
{
  vA.fromBufferAttribute(positionAttribute, a);
  vB.fromBufferAttribute(positionAttribute, b);
  vC.fromBufferAttribute(positionAttribute, c);
  uvA.fromBufferAttribute(uvAttribute, a);
  uvB.fromBufferAttribute(uvAttribute, b);
  uvC.fromBufferAttribute(uvAttribute, c);
  vB.sub(vA);
  vC.sub(vA);
  uvB.sub(uvA);
  uvC.sub(uvA);
  const r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

  // silently ignore degenerate uv triangles having coincident or colinear vertices

  if (!isFinite(r)) return;
  sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
  tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);
  tan1[a].add(sdir);
  tan1[b].add(sdir);
  tan1[c].add(sdir);
  tan2[a].add(tdir);
  tan2[b].add(tdir);
  tan2[c].add(tdir);
}
vA.fromBufferAttribute(positionAttribute, a);
vA.fromBufferAttribute(positionAttribute, a)
vA.fromBufferAttribute
vA
fromBufferAttribute
positionAttribute
a
vB.fromBufferAttribute(positionAttribute, b);
vB.fromBufferAttribute(positionAttribute, b)
vB.fromBufferAttribute
vB
fromBufferAttribute
positionAttribute
b
vC.fromBufferAttribute(positionAttribute, c);
vC.fromBufferAttribute(positionAttribute, c)
vC.fromBufferAttribute
vC
fromBufferAttribute
positionAttribute
c
uvA.fromBufferAttribute(uvAttribute, a);
uvA.fromBufferAttribute(uvAttribute, a)
uvA.fromBufferAttribute
uvA
fromBufferAttribute
uvAttribute
a
uvB.fromBufferAttribute(uvAttribute, b);
uvB.fromBufferAttribute(uvAttribute, b)
uvB.fromBufferAttribute
uvB
fromBufferAttribute
uvAttribute
b
uvC.fromBufferAttribute(uvAttribute, c);
uvC.fromBufferAttribute(uvAttribute, c)
uvC.fromBufferAttribute
uvC
fromBufferAttribute
uvAttribute
c
vB.sub(vA);
vB.sub(vA)
vB.sub
vB
sub
vA
vC.sub(vA);
vC.sub(vA)
vC.sub
vC
sub
vA
uvB.sub(uvA);
uvB.sub(uvA)
uvB.sub
uvB
sub
uvA
uvC.sub(uvA);
uvC.sub(uvA)
uvC.sub
uvC
sub
uvA
const r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

// silently ignore degenerate uv triangles having coincident or colinear vertices
r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y)
r
1.0 / (uvB.x * uvC.y - uvC.x * uvB.y)
1.0
uvB.x * uvC.y - uvC.x * uvB.y
uvB.x * uvC.y
uvB.x
uvB
x
uvC.y
uvC
y
uvC.x * uvB.y
uvC.x
uvC
x
uvB.y
uvB
y
// silently ignore degenerate uv triangles having coincident or colinear vertices

if (!isFinite(r)) return;
!isFinite(r)
isFinite(r)
isFinite
r
return;
sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r)
sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar
sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y)
sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector
sdir.copy(vB).multiplyScalar(uvC.y)
sdir.copy(vB).multiplyScalar
sdir.copy(vB)
sdir.copy
sdir
copy
vB
multiplyScalar
uvC.y
uvC
y
addScaledVector
vC
-uvB.y
uvB.y
uvB
y
multiplyScalar
r
tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);
tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r)
tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar
tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x)
tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector
tdir.copy(vC).multiplyScalar(uvB.x)
tdir.copy(vC).multiplyScalar
tdir.copy(vC)
tdir.copy
tdir
copy
vC
multiplyScalar
uvB.x
uvB
x
addScaledVector
vB
-uvC.x
uvC.x
uvC
x
multiplyScalar
r
tan1[a].add(sdir);
tan1[a].add(sdir)
tan1[a].add
tan1[a]
tan1
a
add
sdir
tan1[b].add(sdir);
tan1[b].add(sdir)
tan1[b].add
tan1[b]
tan1
b
add
sdir
tan1[c].add(sdir);
tan1[c].add(sdir)
tan1[c].add
tan1[c]
tan1
c
add
sdir
tan2[a].add(tdir);
tan2[a].add(tdir)
tan2[a].add
tan2[a]
tan2
a
add
tdir
tan2[b].add(tdir);
tan2[b].add(tdir)
tan2[b].add
tan2[b]
tan2
b
add
tdir
tan2[c].add(tdir);
tan2[c].add(tdir)
tan2[c].add
tan2[c]
tan2
c
add
tdir
let groups = this.groups;
groups = this.groups
groups
this.groups
this
groups
if (groups.length === 0) {
  groups = [{
    start: 0,
    count: index.count
  }];
}
groups.length === 0
groups.length
groups
length
0
{
  groups = [{
    start: 0,
    count: index.count
  }];
}
groups = [{
  start: 0,
  count: index.count
}];
groups = [{
  start: 0,
  count: index.count
}]
groups
[{
  start: 0,
  count: index.count
}]
{
  start: 0,
  count: index.count
}
start: 0
start
0
count: index.count
count
index.count
index
count
for (let i = 0, il = groups.length; i < il; ++i) {
  const group = groups[i];
  const start = group.start;
  const count = group.count;
  for (let j = start, jl = start + count; j < jl; j += 3) {
    handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
  }
}
let i = 0,
  il = groups.length;
i = 0
i
0
il = groups.length
il
groups.length
groups
length
i < il
i
il
++i
i
{
  const group = groups[i];
  const start = group.start;
  const count = group.count;
  for (let j = start, jl = start + count; j < jl; j += 3) {
    handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
  }
}
const group = groups[i];
group = groups[i]
group
groups[i]
groups
i
const start = group.start;
start = group.start
start
group.start
group
start
const count = group.count;
count = group.count
count
group.count
group
count
for (let j = start, jl = start + count; j < jl; j += 3) {
  handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
}
let j = start,
  jl = start + count;
j = start
j
start
jl = start + count
jl
start + count
start
count
j < jl
j
jl
j += 3
j
3
{
  handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
}
handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2))
handleTriangle
index.getX(j + 0)
index.getX
index
getX
j + 0
j
0
index.getX(j + 1)
index.getX
index
getX
j + 1
j
1
index.getX(j + 2)
index.getX
index
getX
j + 2
j
2
const tmp = new Vector3(),
  tmp2 = new Vector3();
tmp = new Vector3()
tmp
new Vector3()
Vector3
tmp2 = new Vector3()
tmp2
new Vector3()
Vector3
const n = new Vector3(),
  n2 = new Vector3();
n = new Vector3()
n
new Vector3()
Vector3
n2 = new Vector3()
n2
new Vector3()
Vector3
function handleVertex(v) {
  n.fromBufferAttribute(normalAttribute, v);
  n2.copy(n);
  const t = tan1[v];

  // Gram-Schmidt orthogonalize

  tmp.copy(t);
  tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

  // Calculate handedness

  tmp2.crossVectors(n2, t);
  const test = tmp2.dot(tan2[v]);
  const w = test < 0.0 ? -1.0 : 1.0;
  tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
}
function handleVertex(v) {
  n.fromBufferAttribute(normalAttribute, v);
  n2.copy(n);
  const t = tan1[v];

  // Gram-Schmidt orthogonalize

  tmp.copy(t);
  tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

  // Calculate handedness

  tmp2.crossVectors(n2, t);
  const test = tmp2.dot(tan2[v]);
  const w = test < 0.0 ? -1.0 : 1.0;
  tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
}
handleVertex
v
{
  n.fromBufferAttribute(normalAttribute, v);
  n2.copy(n);
  const t = tan1[v];

  // Gram-Schmidt orthogonalize

  tmp.copy(t);
  tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

  // Calculate handedness

  tmp2.crossVectors(n2, t);
  const test = tmp2.dot(tan2[v]);
  const w = test < 0.0 ? -1.0 : 1.0;
  tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
}
n.fromBufferAttribute(normalAttribute, v);
n.fromBufferAttribute(normalAttribute, v)
n.fromBufferAttribute
n
fromBufferAttribute
normalAttribute
v
n2.copy(n);
n2.copy(n)
n2.copy
n2
copy
n
const t = tan1[v];

// Gram-Schmidt orthogonalize
t = tan1[v]
t
tan1[v]
tan1
v
// Gram-Schmidt orthogonalize

tmp.copy(t);
tmp.copy(t)
tmp.copy
tmp
copy
t
tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

// Calculate handedness
tmp.sub(n.multiplyScalar(n.dot(t))).normalize()
tmp.sub(n.multiplyScalar(n.dot(t))).normalize
tmp.sub(n.multiplyScalar(n.dot(t)))
tmp.sub
tmp
sub
n.multiplyScalar(n.dot(t))
n.multiplyScalar
n
multiplyScalar
n.dot(t)
n.dot
n
dot
t
normalize
// Calculate handedness

tmp2.crossVectors(n2, t);
tmp2.crossVectors(n2, t)
tmp2.crossVectors
tmp2
crossVectors
n2
t
const test = tmp2.dot(tan2[v]);
test = tmp2.dot(tan2[v])
test
tmp2.dot(tan2[v])
tmp2.dot
tmp2
dot
tan2[v]
tan2
v
const w = test < 0.0 ? -1.0 : 1.0;
w = test < 0.0 ? -1.0 : 1.0
w
test < 0.0 ? -1.0 : 1.0
test < 0.0
test
0.0
-1.0
1.0
1.0
tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w)
tangentAttribute.setXYZW
tangentAttribute
setXYZW
v
tmp.x
tmp
x
tmp.y
tmp
y
tmp.z
tmp
z
w
for (let i = 0, il = groups.length; i < il; ++i) {
  const group = groups[i];
  const start = group.start;
  const count = group.count;
  for (let j = start, jl = start + count; j < jl; j += 3) {
    handleVertex(index.getX(j + 0));
    handleVertex(index.getX(j + 1));
    handleVertex(index.getX(j + 2));
  }
}
let i = 0,
  il = groups.length;
i = 0
i
0
il = groups.length
il
groups.length
groups
length
i < il
i
il
++i
i
{
  const group = groups[i];
  const start = group.start;
  const count = group.count;
  for (let j = start, jl = start + count; j < jl; j += 3) {
    handleVertex(index.getX(j + 0));
    handleVertex(index.getX(j + 1));
    handleVertex(index.getX(j + 2));
  }
}
const group = groups[i];
group = groups[i]
group
groups[i]
groups
i
const start = group.start;
start = group.start
start
group.start
group
start
const count = group.count;
count = group.count
count
group.count
group
count
for (let j = start, jl = start + count; j < jl; j += 3) {
  handleVertex(index.getX(j + 0));
  handleVertex(index.getX(j + 1));
  handleVertex(index.getX(j + 2));
}
let j = start,
  jl = start + count;
j = start
j
start
jl = start + count
jl
start + count
start
count
j < jl
j
jl
j += 3
j
3
{
  handleVertex(index.getX(j + 0));
  handleVertex(index.getX(j + 1));
  handleVertex(index.getX(j + 2));
}
handleVertex(index.getX(j + 0));
handleVertex(index.getX(j + 0))
handleVertex
index.getX(j + 0)
index.getX
index
getX
j + 0
j
0
handleVertex(index.getX(j + 1));
handleVertex(index.getX(j + 1))
handleVertex
index.getX(j + 1)
index.getX
index
getX
j + 1
j
1
handleVertex(index.getX(j + 2));
handleVertex(index.getX(j + 2))
handleVertex
index.getX(j + 2)
index.getX
index
getX
j + 2
j
2
computeVertexNormals() {
  const index = this.index;
  const positionAttribute = this.getAttribute('position');
  if (positionAttribute !== undefined) {
    let normalAttribute = this.getAttribute('normal');
    if (normalAttribute === undefined) {
      normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
      this.setAttribute('normal', normalAttribute);
    } else {
      // reset existing normals to zero

      for (let i = 0, il = normalAttribute.count; i < il; i++) {
        normalAttribute.setXYZ(i, 0, 0, 0);
      }
    }
    const pA = new Vector3(),
      pB = new Vector3(),
      pC = new Vector3();
    const nA = new Vector3(),
      nB = new Vector3(),
      nC = new Vector3();
    const cb = new Vector3(),
      ab = new Vector3();

    // indexed elements

    if (index) {
      for (let i = 0, il = index.count; i < il; i += 3) {
        const vA = index.getX(i + 0);
        const vB = index.getX(i + 1);
        const vC = index.getX(i + 2);
        pA.fromBufferAttribute(positionAttribute, vA);
        pB.fromBufferAttribute(positionAttribute, vB);
        pC.fromBufferAttribute(positionAttribute, vC);
        cb.subVectors(pC, pB);
        ab.subVectors(pA, pB);
        cb.cross(ab);
        nA.fromBufferAttribute(normalAttribute, vA);
        nB.fromBufferAttribute(normalAttribute, vB);
        nC.fromBufferAttribute(normalAttribute, vC);
        nA.add(cb);
        nB.add(cb);
        nC.add(cb);
        normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
        normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
        normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
      }
    } else {
      // non-indexed elements (unconnected triangle soup)

      for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
        pA.fromBufferAttribute(positionAttribute, i + 0);
        pB.fromBufferAttribute(positionAttribute, i + 1);
        pC.fromBufferAttribute(positionAttribute, i + 2);
        cb.subVectors(pC, pB);
        ab.subVectors(pA, pB);
        cb.cross(ab);
        normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
        normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
        normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
      }
    }
    this.normalizeNormals();
    normalAttribute.needsUpdate = true;
  }
}
computeTangents
{
  const index = this.index;
  const attributes = this.attributes;

  // based on http://www.terathon.com/code/tangent.html
  // (per vertex tangents)

  if (index === null || attributes.position === undefined || attributes.normal === undefined || attributes.uv === undefined) {
    console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
    return;
  }
  const positionAttribute = attributes.position;
  const normalAttribute = attributes.normal;
  const uvAttribute = attributes.uv;
  if (this.hasAttribute('tangent') === false) {
    this.setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
  }
  const tangentAttribute = this.getAttribute('tangent');
  const tan1 = [],
    tan2 = [];
  for (let i = 0; i < positionAttribute.count; i++) {
    tan1[i] = new Vector3();
    tan2[i] = new Vector3();
  }
  const vA = new Vector3(),
    vB = new Vector3(),
    vC = new Vector3(),
    uvA = new Vector2(),
    uvB = new Vector2(),
    uvC = new Vector2(),
    sdir = new Vector3(),
    tdir = new Vector3();
  function handleTriangle(a, b, c) {
    vA.fromBufferAttribute(positionAttribute, a);
    vB.fromBufferAttribute(positionAttribute, b);
    vC.fromBufferAttribute(positionAttribute, c);
    uvA.fromBufferAttribute(uvAttribute, a);
    uvB.fromBufferAttribute(uvAttribute, b);
    uvC.fromBufferAttribute(uvAttribute, c);
    vB.sub(vA);
    vC.sub(vA);
    uvB.sub(uvA);
    uvC.sub(uvA);
    const r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

    // silently ignore degenerate uv triangles having coincident or colinear vertices

    if (!isFinite(r)) return;
    sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
    tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);
    tan1[a].add(sdir);
    tan1[b].add(sdir);
    tan1[c].add(sdir);
    tan2[a].add(tdir);
    tan2[b].add(tdir);
    tan2[c].add(tdir);
  }
  let groups = this.groups;
  if (groups.length === 0) {
    groups = [{
      start: 0,
      count: index.count
    }];
  }
  for (let i = 0, il = groups.length; i < il; ++i) {
    const group = groups[i];
    const start = group.start;
    const count = group.count;
    for (let j = start, jl = start + count; j < jl; j += 3) {
      handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
    }
  }
  const tmp = new Vector3(),
    tmp2 = new Vector3();
  const n = new Vector3(),
    n2 = new Vector3();
  function handleVertex(v) {
    n.fromBufferAttribute(normalAttribute, v);
    n2.copy(n);
    const t = tan1[v];

    // Gram-Schmidt orthogonalize

    tmp.copy(t);
    tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

    // Calculate handedness

    tmp2.crossVectors(n2, t);
    const test = tmp2.dot(tan2[v]);
    const w = test < 0.0 ? -1.0 : 1.0;
    tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
  }
  for (let i = 0, il = groups.length; i < il; ++i) {
    const group = groups[i];
    const start = group.start;
    const count = group.count;
    for (let j = start, jl = start + count; j < jl; j += 3) {
      handleVertex(index.getX(j + 0));
      handleVertex(index.getX(j + 1));
      handleVertex(index.getX(j + 2));
    }
  }
}
const index = this.index;
index = this.index
index
this.index
this
index
const attributes = this.attributes;

// based on http://www.terathon.com/code/tangent.html
// (per vertex tangents)
attributes = this.attributes
attributes
this.attributes
this
attributes
// based on http://www.terathon.com/code/tangent.html
// (per vertex tangents)

if (index === null || attributes.position === undefined || attributes.normal === undefined || attributes.uv === undefined) {
  console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
  return;
}
index === null || attributes.position === undefined || attributes.normal === undefined || attributes.uv === undefined
index === null || attributes.position === undefined || attributes.normal === undefined
index === null || attributes.position === undefined
index === null
index
null
attributes.position === undefined
attributes.position
attributes
position
undefined
attributes.normal === undefined
attributes.normal
attributes
normal
undefined
attributes.uv === undefined
attributes.uv
attributes
uv
undefined
{
  console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
  return;
}
console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)')
console.error
console
error
'THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)'
return;
const positionAttribute = attributes.position;
positionAttribute = attributes.position
positionAttribute
attributes.position
attributes
position
const normalAttribute = attributes.normal;
normalAttribute = attributes.normal
normalAttribute
attributes.normal
attributes
normal
const uvAttribute = attributes.uv;
uvAttribute = attributes.uv
uvAttribute
attributes.uv
attributes
uv
if (this.hasAttribute('tangent') === false) {
  this.setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
}
this.hasAttribute('tangent') === false
this.hasAttribute('tangent')
this.hasAttribute
this
hasAttribute
'tangent'
false
{
  this.setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
}
this.setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
this.setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4))
this.setAttribute
this
setAttribute
'tangent'
new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4)
BufferAttribute
new Float32Array(4 * positionAttribute.count)
Float32Array
4 * positionAttribute.count
4
positionAttribute.count
positionAttribute
count
4
const tangentAttribute = this.getAttribute('tangent');
tangentAttribute = this.getAttribute('tangent')
tangentAttribute
this.getAttribute('tangent')
this.getAttribute
this
getAttribute
'tangent'
const tan1 = [],
  tan2 = [];
tan1 = []
tan1
[]
tan2 = []
tan2
[]
for (let i = 0; i < positionAttribute.count; i++) {
  tan1[i] = new Vector3();
  tan2[i] = new Vector3();
}
let i = 0;
i = 0
i
0
i < positionAttribute.count
i
positionAttribute.count
positionAttribute
count
i++
i
{
  tan1[i] = new Vector3();
  tan2[i] = new Vector3();
}
tan1[i] = new Vector3();
tan1[i] = new Vector3()
tan1[i]
tan1
i
new Vector3()
Vector3
tan2[i] = new Vector3();
tan2[i] = new Vector3()
tan2[i]
tan2
i
new Vector3()
Vector3
const vA = new Vector3(),
  vB = new Vector3(),
  vC = new Vector3(),
  uvA = new Vector2(),
  uvB = new Vector2(),
  uvC = new Vector2(),
  sdir = new Vector3(),
  tdir = new Vector3();
vA = new Vector3()
vA
new Vector3()
Vector3
vB = new Vector3()
vB
new Vector3()
Vector3
vC = new Vector3()
vC
new Vector3()
Vector3
uvA = new Vector2()
uvA
new Vector2()
Vector2
uvB = new Vector2()
uvB
new Vector2()
Vector2
uvC = new Vector2()
uvC
new Vector2()
Vector2
sdir = new Vector3()
sdir
new Vector3()
Vector3
tdir = new Vector3()
tdir
new Vector3()
Vector3
function handleTriangle(a, b, c) {
  vA.fromBufferAttribute(positionAttribute, a);
  vB.fromBufferAttribute(positionAttribute, b);
  vC.fromBufferAttribute(positionAttribute, c);
  uvA.fromBufferAttribute(uvAttribute, a);
  uvB.fromBufferAttribute(uvAttribute, b);
  uvC.fromBufferAttribute(uvAttribute, c);
  vB.sub(vA);
  vC.sub(vA);
  uvB.sub(uvA);
  uvC.sub(uvA);
  const r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

  // silently ignore degenerate uv triangles having coincident or colinear vertices

  if (!isFinite(r)) return;
  sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
  tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);
  tan1[a].add(sdir);
  tan1[b].add(sdir);
  tan1[c].add(sdir);
  tan2[a].add(tdir);
  tan2[b].add(tdir);
  tan2[c].add(tdir);
}
computeVertexNormals() {
  const index = this.index;
  const positionAttribute = this.getAttribute('position');
  if (positionAttribute !== undefined) {
    let normalAttribute = this.getAttribute('normal');
    if (normalAttribute === undefined) {
      normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
      this.setAttribute('normal', normalAttribute);
    } else {
      // reset existing normals to zero

      for (let i = 0, il = normalAttribute.count; i < il; i++) {
        normalAttribute.setXYZ(i, 0, 0, 0);
      }
    }
    const pA = new Vector3(),
      pB = new Vector3(),
      pC = new Vector3();
    const nA = new Vector3(),
      nB = new Vector3(),
      nC = new Vector3();
    const cb = new Vector3(),
      ab = new Vector3();

    // indexed elements

    if (index) {
      for (let i = 0, il = index.count; i < il; i += 3) {
        const vA = index.getX(i + 0);
        const vB = index.getX(i + 1);
        const vC = index.getX(i + 2);
        pA.fromBufferAttribute(positionAttribute, vA);
        pB.fromBufferAttribute(positionAttribute, vB);
        pC.fromBufferAttribute(positionAttribute, vC);
        cb.subVectors(pC, pB);
        ab.subVectors(pA, pB);
        cb.cross(ab);
        nA.fromBufferAttribute(normalAttribute, vA);
        nB.fromBufferAttribute(normalAttribute, vB);
        nC.fromBufferAttribute(normalAttribute, vC);
        nA.add(cb);
        nB.add(cb);
        nC.add(cb);
        normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
        normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
        normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
      }
    } else {
      // non-indexed elements (unconnected triangle soup)

      for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
        pA.fromBufferAttribute(positionAttribute, i + 0);
        pB.fromBufferAttribute(positionAttribute, i + 1);
        pC.fromBufferAttribute(positionAttribute, i + 2);
        cb.subVectors(pC, pB);
        ab.subVectors(pA, pB);
        cb.cross(ab);
        normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
        normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
        normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
      }
    }
    this.normalizeNormals();
    normalAttribute.needsUpdate = true;
  }
}
computeVertexNormals
{
  const index = this.index;
  const positionAttribute = this.getAttribute('position');
  if (positionAttribute !== undefined) {
    let normalAttribute = this.getAttribute('normal');
    if (normalAttribute === undefined) {
      normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
      this.setAttribute('normal', normalAttribute);
    } else {
      // reset existing normals to zero

      for (let i = 0, il = normalAttribute.count; i < il; i++) {
        normalAttribute.setXYZ(i, 0, 0, 0);
      }
    }
    const pA = new Vector3(),
      pB = new Vector3(),
      pC = new Vector3();
    const nA = new Vector3(),
      nB = new Vector3(),
      nC = new Vector3();
    const cb = new Vector3(),
      ab = new Vector3();

    // indexed elements

    if (index) {
      for (let i = 0, il = index.count; i < il; i += 3) {
        const vA = index.getX(i + 0);
        const vB = index.getX(i + 1);
        const vC = index.getX(i + 2);
        pA.fromBufferAttribute(positionAttribute, vA);
        pB.fromBufferAttribute(positionAttribute, vB);
        pC.fromBufferAttribute(positionAttribute, vC);
        cb.subVectors(pC, pB);
        ab.subVectors(pA, pB);
        cb.cross(ab);
        nA.fromBufferAttribute(normalAttribute, vA);
        nB.fromBufferAttribute(normalAttribute, vB);
        nC.fromBufferAttribute(normalAttribute, vC);
        nA.add(cb);
        nB.add(cb);
        nC.add(cb);
        normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
        normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
        normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
      }
    } else {
      // non-indexed elements (unconnected triangle soup)

      for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
        pA.fromBufferAttribute(positionAttribute, i + 0);
        pB.fromBufferAttribute(positionAttribute, i + 1);
        pC.fromBufferAttribute(positionAttribute, i + 2);
        cb.subVectors(pC, pB);
        ab.subVectors(pA, pB);
        cb.cross(ab);
        normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
        normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
        normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
      }
    }
    this.normalizeNormals();
    normalAttribute.needsUpdate = true;
  }
}
const index = this.index;
index = this.index
index
this.index
this
index
const positionAttribute = this.getAttribute('position');
positionAttribute = this.getAttribute('position')
positionAttribute
this.getAttribute('position')
this.getAttribute
this
getAttribute
'position'
if (positionAttribute !== undefined) {
  let normalAttribute = this.getAttribute('normal');
  if (normalAttribute === undefined) {
    normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
    this.setAttribute('normal', normalAttribute);
  } else {
    // reset existing normals to zero

    for (let i = 0, il = normalAttribute.count; i < il; i++) {
      normalAttribute.setXYZ(i, 0, 0, 0);
    }
  }
  const pA = new Vector3(),
    pB = new Vector3(),
    pC = new Vector3();
  const nA = new Vector3(),
    nB = new Vector3(),
    nC = new Vector3();
  const cb = new Vector3(),
    ab = new Vector3();

  // indexed elements

  if (index) {
    for (let i = 0, il = index.count; i < il; i += 3) {
      const vA = index.getX(i + 0);
      const vB = index.getX(i + 1);
      const vC = index.getX(i + 2);
      pA.fromBufferAttribute(positionAttribute, vA);
      pB.fromBufferAttribute(positionAttribute, vB);
      pC.fromBufferAttribute(positionAttribute, vC);
      cb.subVectors(pC, pB);
      ab.subVectors(pA, pB);
      cb.cross(ab);
      nA.fromBufferAttribute(normalAttribute, vA);
      nB.fromBufferAttribute(normalAttribute, vB);
      nC.fromBufferAttribute(normalAttribute, vC);
      nA.add(cb);
      nB.add(cb);
      nC.add(cb);
      normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
      normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
      normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
    }
  } else {
    // non-indexed elements (unconnected triangle soup)

    for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
      pA.fromBufferAttribute(positionAttribute, i + 0);
      pB.fromBufferAttribute(positionAttribute, i + 1);
      pC.fromBufferAttribute(positionAttribute, i + 2);
      cb.subVectors(pC, pB);
      ab.subVectors(pA, pB);
      cb.cross(ab);
      normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
      normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
      normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
    }
  }
  this.normalizeNormals();
  normalAttribute.needsUpdate = true;
}
positionAttribute !== undefined
positionAttribute
undefined
{
  let normalAttribute = this.getAttribute('normal');
  if (normalAttribute === undefined) {
    normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
    this.setAttribute('normal', normalAttribute);
  } else {
    // reset existing normals to zero

    for (let i = 0, il = normalAttribute.count; i < il; i++) {
      normalAttribute.setXYZ(i, 0, 0, 0);
    }
  }
  const pA = new Vector3(),
    pB = new Vector3(),
    pC = new Vector3();
  const nA = new Vector3(),
    nB = new Vector3(),
    nC = new Vector3();
  const cb = new Vector3(),
    ab = new Vector3();

  // indexed elements

  if (index) {
    for (let i = 0, il = index.count; i < il; i += 3) {
      const vA = index.getX(i + 0);
      const vB = index.getX(i + 1);
      const vC = index.getX(i + 2);
      pA.fromBufferAttribute(positionAttribute, vA);
      pB.fromBufferAttribute(positionAttribute, vB);
      pC.fromBufferAttribute(positionAttribute, vC);
      cb.subVectors(pC, pB);
      ab.subVectors(pA, pB);
      cb.cross(ab);
      nA.fromBufferAttribute(normalAttribute, vA);
      nB.fromBufferAttribute(normalAttribute, vB);
      nC.fromBufferAttribute(normalAttribute, vC);
      nA.add(cb);
      nB.add(cb);
      nC.add(cb);
      normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
      normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
      normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
    }
  } else {
    // non-indexed elements (unconnected triangle soup)

    for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
      pA.fromBufferAttribute(positionAttribute, i + 0);
      pB.fromBufferAttribute(positionAttribute, i + 1);
      pC.fromBufferAttribute(positionAttribute, i + 2);
      cb.subVectors(pC, pB);
      ab.subVectors(pA, pB);
      cb.cross(ab);
      normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
      normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
      normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
    }
  }
  this.normalizeNormals();
  normalAttribute.needsUpdate = true;
}
let normalAttribute = this.getAttribute('normal');
normalAttribute = this.getAttribute('normal')
normalAttribute
this.getAttribute('normal')
this.getAttribute
this
getAttribute
'normal'
if (normalAttribute === undefined) {
  normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
  this.setAttribute('normal', normalAttribute);
} else {
  // reset existing normals to zero

  for (let i = 0, il = normalAttribute.count; i < il; i++) {
    normalAttribute.setXYZ(i, 0, 0, 0);
  }
}
normalAttribute === undefined
normalAttribute
undefined
{
  normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
  this.setAttribute('normal', normalAttribute);
}
normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3)
normalAttribute
new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3)
BufferAttribute
new Float32Array(positionAttribute.count * 3)
Float32Array
positionAttribute.count * 3
positionAttribute.count
positionAttribute
count
3
3
this.setAttribute('normal', normalAttribute);
this.setAttribute('normal', normalAttribute)
this.setAttribute
this
setAttribute
'normal'
normalAttribute
{
  // reset existing normals to zero

  for (let i = 0, il = normalAttribute.count; i < il; i++) {
    normalAttribute.setXYZ(i, 0, 0, 0);
  }
}
// reset existing normals to zero

for (let i = 0, il = normalAttribute.count; i < il; i++) {
  normalAttribute.setXYZ(i, 0, 0, 0);
}
let i = 0,
  il = normalAttribute.count;
i = 0
i
0
il = normalAttribute.count
il
normalAttribute.count
normalAttribute
count
i < il
i
il
i++
i
{
  normalAttribute.setXYZ(i, 0, 0, 0);
}
normalAttribute.setXYZ(i, 0, 0, 0);
normalAttribute.setXYZ(i, 0, 0, 0)
normalAttribute.setXYZ
normalAttribute
setXYZ
i
0
0
0
const pA = new Vector3(),
  pB = new Vector3(),
  pC = new Vector3();
pA = new Vector3()
pA
new Vector3()
Vector3
pB = new Vector3()
pB
new Vector3()
Vector3
pC = new Vector3()
pC
new Vector3()
Vector3
const nA = new Vector3(),
  nB = new Vector3(),
  nC = new Vector3();
nA = new Vector3()
nA
new Vector3()
Vector3
nB = new Vector3()
nB
new Vector3()
Vector3
nC = new Vector3()
nC
new Vector3()
Vector3
const cb = new Vector3(),
  ab = new Vector3();

// indexed elements
cb = new Vector3()
cb
new Vector3()
Vector3
ab = new Vector3()
ab
new Vector3()
Vector3
// indexed elements

if (index) {
  for (let i = 0, il = index.count; i < il; i += 3) {
    const vA = index.getX(i + 0);
    const vB = index.getX(i + 1);
    const vC = index.getX(i + 2);
    pA.fromBufferAttribute(positionAttribute, vA);
    pB.fromBufferAttribute(positionAttribute, vB);
    pC.fromBufferAttribute(positionAttribute, vC);
    cb.subVectors(pC, pB);
    ab.subVectors(pA, pB);
    cb.cross(ab);
    nA.fromBufferAttribute(normalAttribute, vA);
    nB.fromBufferAttribute(normalAttribute, vB);
    nC.fromBufferAttribute(normalAttribute, vC);
    nA.add(cb);
    nB.add(cb);
    nC.add(cb);
    normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
    normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
    normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
  }
} else {
  // non-indexed elements (unconnected triangle soup)

  for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
    pA.fromBufferAttribute(positionAttribute, i + 0);
    pB.fromBufferAttribute(positionAttribute, i + 1);
    pC.fromBufferAttribute(positionAttribute, i + 2);
    cb.subVectors(pC, pB);
    ab.subVectors(pA, pB);
    cb.cross(ab);
    normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
    normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
    normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
  }
}
index
{
  for (let i = 0, il = index.count; i < il; i += 3) {
    const vA = index.getX(i + 0);
    const vB = index.getX(i + 1);
    const vC = index.getX(i + 2);
    pA.fromBufferAttribute(positionAttribute, vA);
    pB.fromBufferAttribute(positionAttribute, vB);
    pC.fromBufferAttribute(positionAttribute, vC);
    cb.subVectors(pC, pB);
    ab.subVectors(pA, pB);
    cb.cross(ab);
    nA.fromBufferAttribute(normalAttribute, vA);
    nB.fromBufferAttribute(normalAttribute, vB);
    nC.fromBufferAttribute(normalAttribute, vC);
    nA.add(cb);
    nB.add(cb);
    nC.add(cb);
    normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
    normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
    normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
  }
}
for (let i = 0, il = index.count; i < il; i += 3) {
  const vA = index.getX(i + 0);
  const vB = index.getX(i + 1);
  const vC = index.getX(i + 2);
  pA.fromBufferAttribute(positionAttribute, vA);
  pB.fromBufferAttribute(positionAttribute, vB);
  pC.fromBufferAttribute(positionAttribute, vC);
  cb.subVectors(pC, pB);
  ab.subVectors(pA, pB);
  cb.cross(ab);
  nA.fromBufferAttribute(normalAttribute, vA);
  nB.fromBufferAttribute(normalAttribute, vB);
  nC.fromBufferAttribute(normalAttribute, vC);
  nA.add(cb);
  nB.add(cb);
  nC.add(cb);
  normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
  normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
  normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
}
let i = 0,
  il = index.count;
i = 0
i
0
il = index.count
il
index.count
index
count
i < il
i
il
i += 3
i
3
{
  const vA = index.getX(i + 0);
  const vB = index.getX(i + 1);
  const vC = index.getX(i + 2);
  pA.fromBufferAttribute(positionAttribute, vA);
  pB.fromBufferAttribute(positionAttribute, vB);
  pC.fromBufferAttribute(positionAttribute, vC);
  cb.subVectors(pC, pB);
  ab.subVectors(pA, pB);
  cb.cross(ab);
  nA.fromBufferAttribute(normalAttribute, vA);
  nB.fromBufferAttribute(normalAttribute, vB);
  nC.fromBufferAttribute(normalAttribute, vC);
  nA.add(cb);
  nB.add(cb);
  nC.add(cb);
  normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
  normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
  normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
}
const vA = index.getX(i + 0);
vA = index.getX(i + 0)
vA
index.getX(i + 0)
index.getX
index
getX
i + 0
i
0
const vB = index.getX(i + 1);
vB = index.getX(i + 1)
vB
index.getX(i + 1)
index.getX
index
getX
i + 1
i
1
const vC = index.getX(i + 2);
vC = index.getX(i + 2)
vC
index.getX(i + 2)
index.getX
index
getX
i + 2
i
2
pA.fromBufferAttribute(positionAttribute, vA);
pA.fromBufferAttribute(positionAttribute, vA)
pA.fromBufferAttribute
pA
fromBufferAttribute
positionAttribute
vA
pB.fromBufferAttribute(positionAttribute, vB);
pB.fromBufferAttribute(positionAttribute, vB)
pB.fromBufferAttribute
pB
fromBufferAttribute
positionAttribute
vB
pC.fromBufferAttribute(positionAttribute, vC);
pC.fromBufferAttribute(positionAttribute, vC)
pC.fromBufferAttribute
pC
fromBufferAttribute
positionAttribute
vC
cb.subVectors(pC, pB);
cb.subVectors(pC, pB)
cb.subVectors
cb
subVectors
pC
pB
ab.subVectors(pA, pB);
ab.subVectors(pA, pB)
ab.subVectors
ab
subVectors
pA
pB
cb.cross(ab);
cb.cross(ab)
cb.cross
cb
cross
ab
nA.fromBufferAttribute(normalAttribute, vA);
nA.fromBufferAttribute(normalAttribute, vA)
nA.fromBufferAttribute
nA
fromBufferAttribute
normalAttribute
vA
nB.fromBufferAttribute(normalAttribute, vB);
nB.fromBufferAttribute(normalAttribute, vB)
nB.fromBufferAttribute
nB
fromBufferAttribute
normalAttribute
vB
nC.fromBufferAttribute(normalAttribute, vC);
nC.fromBufferAttribute(normalAttribute, vC)
nC.fromBufferAttribute
nC
fromBufferAttribute
normalAttribute
vC
nA.add(cb);
nA.add(cb)
nA.add
nA
add
cb
nB.add(cb);
nB.add(cb)
nB.add
nB
add
cb
nC.add(cb);
nC.add(cb)
nC.add
nC
add
cb
normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z)
normalAttribute.setXYZ
normalAttribute
setXYZ
vA
nA.x
nA
x
nA.y
nA
y
nA.z
nA
z
normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z)
normalAttribute.setXYZ
normalAttribute
setXYZ
vB
nB.x
nB
x
nB.y
nB
y
nB.z
nB
z
normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z)
normalAttribute.setXYZ
normalAttribute
setXYZ
vC
nC.x
nC
x
nC.y
nC
y
nC.z
nC
z
{
  // non-indexed elements (unconnected triangle soup)

  for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
    pA.fromBufferAttribute(positionAttribute, i + 0);
    pB.fromBufferAttribute(positionAttribute, i + 1);
    pC.fromBufferAttribute(positionAttribute, i + 2);
    cb.subVectors(pC, pB);
    ab.subVectors(pA, pB);
    cb.cross(ab);
    normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
    normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
    normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
  }
}
// non-indexed elements (unconnected triangle soup)

for (let i = 0, il = positionAttribute.count; i < il; i += 3) {
  pA.fromBufferAttribute(positionAttribute, i + 0);
  pB.fromBufferAttribute(positionAttribute, i + 1);
  pC.fromBufferAttribute(positionAttribute, i + 2);
  cb.subVectors(pC, pB);
  ab.subVectors(pA, pB);
  cb.cross(ab);
  normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
  normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
  normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
}
let i = 0,
  il = positionAttribute.count;
i = 0
i
0
il = positionAttribute.count
il
positionAttribute.count
positionAttribute
count
i < il
i
il
i += 3
i
3
{
  pA.fromBufferAttribute(positionAttribute, i + 0);
  pB.fromBufferAttribute(positionAttribute, i + 1);
  pC.fromBufferAttribute(positionAttribute, i + 2);
  cb.subVectors(pC, pB);
  ab.subVectors(pA, pB);
  cb.cross(ab);
  normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
  normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
  normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
}
pA.fromBufferAttribute(positionAttribute, i + 0);
pA.fromBufferAttribute(positionAttribute, i + 0)
pA.fromBufferAttribute
pA
fromBufferAttribute
positionAttribute
i + 0
i
0
pB.fromBufferAttribute(positionAttribute, i + 1);
pB.fromBufferAttribute(positionAttribute, i + 1)
pB.fromBufferAttribute
pB
fromBufferAttribute
positionAttribute
i + 1
i
1
pC.fromBufferAttribute(positionAttribute, i + 2);
pC.fromBufferAttribute(positionAttribute, i + 2)
pC.fromBufferAttribute
pC
fromBufferAttribute
positionAttribute
i + 2
i
2
cb.subVectors(pC, pB);
cb.subVectors(pC, pB)
cb.subVectors
cb
subVectors
pC
pB
ab.subVectors(pA, pB);
ab.subVectors(pA, pB)
ab.subVectors
ab
subVectors
pA
pB
cb.cross(ab);
cb.cross(ab)
cb.cross
cb
cross
ab
normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z)
normalAttribute.setXYZ
normalAttribute
setXYZ
i + 0
i
0
cb.x
cb
x
cb.y
cb
y
cb.z
cb
z
normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z)
normalAttribute.setXYZ
normalAttribute
setXYZ
i + 1
i
1
cb.x
cb
x
cb.y
cb
y
cb.z
cb
z
normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z)
normalAttribute.setXYZ
normalAttribute
setXYZ
i + 2
i
2
cb.x
cb
x
cb.y
cb
y
cb.z
cb
z
this.normalizeNormals();
this.normalizeNormals()
this.normalizeNormals
this
normalizeNormals
normalAttribute.needsUpdate = true;
normalAttribute.needsUpdate = true
normalAttribute.needsUpdate
normalAttribute
needsUpdate
true
normalizeNormals() {
  const normals = this.attributes.normal;
  for (let i = 0, il = normals.count; i < il; i++) {
    _vector.fromBufferAttribute(normals, i);
    _vector.normalize();
    normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
  }
}
normalizeNormals() {
  const normals = this.attributes.normal;
  for (let i = 0, il = normals.count; i < il; i++) {
    _vector.fromBufferAttribute(normals, i);
    _vector.normalize();
    normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
  }
}
normalizeNormals
{
  const normals = this.attributes.normal;
  for (let i = 0, il = normals.count; i < il; i++) {
    _vector.fromBufferAttribute(normals, i);
    _vector.normalize();
    normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
  }
}
const normals = this.attributes.normal;
normals = this.attributes.normal
normals
this.attributes.normal
this.attributes
this
attributes
normal
for (let i = 0, il = normals.count; i < il; i++) {
  _vector.fromBufferAttribute(normals, i);
  _vector.normalize();
  normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
}
let i = 0,
  il = normals.count;
i = 0
i
0
il = normals.count
il
normals.count
normals
count
i < il
i
il
i++
i
{
  _vector.fromBufferAttribute(normals, i);
  _vector.normalize();
  normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
}
_vector.fromBufferAttribute(normals, i);
_vector.fromBufferAttribute(normals, i)
_vector.fromBufferAttribute
_vector
fromBufferAttribute
normals
i
_vector.normalize();
_vector.normalize()
_vector.normalize
_vector
normalize
normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
normals.setXYZ(i, _vector.x, _vector.y, _vector.z)
normals.setXYZ
normals
setXYZ
i
_vector.x
_vector
x
_vector.y
_vector
y
_vector.z
_vector
z
toNonIndexed() {
  function convertBufferAttribute(attribute, indices) {
    const array = attribute.array;
    const itemSize = attribute.itemSize;
    const normalized = attribute.normalized;
    const array2 = new array.constructor(indices.length * itemSize);
    let index = 0,
      index2 = 0;
    for (let i = 0, l = indices.length; i < l; i++) {
      if (attribute.isInterleavedBufferAttribute) {
        index = indices[i] * attribute.data.stride + attribute.offset;
      } else {
        index = indices[i] * itemSize;
      }
      for (let j = 0; j < itemSize; j++) {
        array2[index2++] = array[index++];
      }
    }
    return new BufferAttribute(array2, itemSize, normalized);
  }

  //

  if (this.index === null) {
    console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
    return this;
  }
  const geometry2 = new BufferGeometry();
  const indices = this.index.array;
  const attributes = this.attributes;

  // attributes

  for (const name in attributes) {
    const attribute = attributes[name];
    const newAttribute = convertBufferAttribute(attribute, indices);
    geometry2.setAttribute(name, newAttribute);
  }

  // morph attributes

  const morphAttributes = this.morphAttributes;
  for (const name in morphAttributes) {
    const morphArray = [];
    const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

    for (let i = 0, il = morphAttribute.length; i < il; i++) {
      const attribute = morphAttribute[i];
      const newAttribute = convertBufferAttribute(attribute, indices);
      morphArray.push(newAttribute);
    }
    geometry2.morphAttributes[name] = morphArray;
  }
  geometry2.morphTargetsRelative = this.morphTargetsRelative;

  // groups

  const groups = this.groups;
  for (let i = 0, l = groups.length; i < l; i++) {
    const group = groups[i];
    geometry2.addGroup(group.start, group.count, group.materialIndex);
  }
  return geometry2;
}
toNonIndexed() {
  function convertBufferAttribute(attribute, indices) {
    const array = attribute.array;
    const itemSize = attribute.itemSize;
    const normalized = attribute.normalized;
    const array2 = new array.constructor(indices.length * itemSize);
    let index = 0,
      index2 = 0;
    for (let i = 0, l = indices.length; i < l; i++) {
      if (attribute.isInterleavedBufferAttribute) {
        index = indices[i] * attribute.data.stride + attribute.offset;
      } else {
        index = indices[i] * itemSize;
      }
      for (let j = 0; j < itemSize; j++) {
        array2[index2++] = array[index++];
      }
    }
    return new BufferAttribute(array2, itemSize, normalized);
  }

  //

  if (this.index === null) {
    console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
    return this;
  }
  const geometry2 = new BufferGeometry();
  const indices = this.index.array;
  const attributes = this.attributes;

  // attributes

  for (const name in attributes) {
    const attribute = attributes[name];
    const newAttribute = convertBufferAttribute(attribute, indices);
    geometry2.setAttribute(name, newAttribute);
  }

  // morph attributes

  const morphAttributes = this.morphAttributes;
  for (const name in morphAttributes) {
    const morphArray = [];
    const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

    for (let i = 0, il = morphAttribute.length; i < il; i++) {
      const attribute = morphAttribute[i];
      const newAttribute = convertBufferAttribute(attribute, indices);
      morphArray.push(newAttribute);
    }
    geometry2.morphAttributes[name] = morphArray;
  }
  geometry2.morphTargetsRelative = this.morphTargetsRelative;

  // groups

  const groups = this.groups;
  for (let i = 0, l = groups.length; i < l; i++) {
    const group = groups[i];
    geometry2.addGroup(group.start, group.count, group.materialIndex);
  }
  return geometry2;
}
function convertBufferAttribute(attribute, indices) {
  const array = attribute.array;
  const itemSize = attribute.itemSize;
  const normalized = attribute.normalized;
  const array2 = new array.constructor(indices.length * itemSize);
  let index = 0,
    index2 = 0;
  for (let i = 0, l = indices.length; i < l; i++) {
    if (attribute.isInterleavedBufferAttribute) {
      index = indices[i] * attribute.data.stride + attribute.offset;
    } else {
      index = indices[i] * itemSize;
    }
    for (let j = 0; j < itemSize; j++) {
      array2[index2++] = array[index++];
    }
  }
  return new BufferAttribute(array2, itemSize, normalized);
}

//
convertBufferAttribute
attribute
indices
{
  const array = attribute.array;
  const itemSize = attribute.itemSize;
  const normalized = attribute.normalized;
  const array2 = new array.constructor(indices.length * itemSize);
  let index = 0,
    index2 = 0;
  for (let i = 0, l = indices.length; i < l; i++) {
    if (attribute.isInterleavedBufferAttribute) {
      index = indices[i] * attribute.data.stride + attribute.offset;
    } else {
      index = indices[i] * itemSize;
    }
    for (let j = 0; j < itemSize; j++) {
      array2[index2++] = array[index++];
    }
  }
  return new BufferAttribute(array2, itemSize, normalized);
}
const array = attribute.array;
array = attribute.array
array
attribute.array
attribute
array
const itemSize = attribute.itemSize;
itemSize = attribute.itemSize
itemSize
attribute.itemSize
attribute
itemSize
const normalized = attribute.normalized;
normalized = attribute.normalized
normalized
attribute.normalized
attribute
normalized
const array2 = new array.constructor(indices.length * itemSize);
array2 = new array.constructor(indices.length * itemSize)
array2
new array.constructor(indices.length * itemSize)
array.constructor
array
constructor
indices.length * itemSize
indices.length
indices
length
itemSize
let index = 0,
  index2 = 0;
index = 0
index
0
index2 = 0
index2
0
for (let i = 0, l = indices.length; i < l; i++) {
  if (attribute.isInterleavedBufferAttribute) {
    index = indices[i] * attribute.data.stride + attribute.offset;
  } else {
    index = indices[i] * itemSize;
  }
  for (let j = 0; j < itemSize; j++) {
    array2[index2++] = array[index++];
  }
}
let i = 0,
  l = indices.length;
i = 0
i
0
l = indices.length
l
indices.length
indices
length
i < l
i
l
i++
i
{
  if (attribute.isInterleavedBufferAttribute) {
    index = indices[i] * attribute.data.stride + attribute.offset;
  } else {
    index = indices[i] * itemSize;
  }
  for (let j = 0; j < itemSize; j++) {
    array2[index2++] = array[index++];
  }
}
if (attribute.isInterleavedBufferAttribute) {
  index = indices[i] * attribute.data.stride + attribute.offset;
} else {
  index = indices[i] * itemSize;
}
attribute.isInterleavedBufferAttribute
attribute
isInterleavedBufferAttribute
{
  index = indices[i] * attribute.data.stride + attribute.offset;
}
index = indices[i] * attribute.data.stride + attribute.offset;
index = indices[i] * attribute.data.stride + attribute.offset
index
indices[i] * attribute.data.stride + attribute.offset
indices[i] * attribute.data.stride
indices[i]
indices
i
attribute.data.stride
attribute.data
attribute
data
stride
attribute.offset
attribute
offset
{
  index = indices[i] * itemSize;
}
index = indices[i] * itemSize;
index = indices[i] * itemSize
index
indices[i] * itemSize
indices[i]
indices
i
itemSize
for (let j = 0; j < itemSize; j++) {
  array2[index2++] = array[index++];
}
let j = 0;
j = 0
j
0
j < itemSize
j
itemSize
j++
j
{
  array2[index2++] = array[index++];
}
array2[index2++] = array[index++];
array2[index2++] = array[index++]
array2[index2++]
array2
index2++
index2
array[index++]
array
index++
index
return new BufferAttribute(array2, itemSize, normalized);
new BufferAttribute(array2, itemSize, normalized)
BufferAttribute
array2
itemSize
normalized
//

if (this.index === null) {
  console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
  return this;
}
this.index === null
this.index
this
index
null
{
  console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
  return this;
}
console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.')
console.warn
console
warn
'THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.'
return this;
this
const geometry2 = new BufferGeometry();
geometry2 = new BufferGeometry()
geometry2
new BufferGeometry()
BufferGeometry
const indices = this.index.array;
indices = this.index.array
indices
this.index.array
this.index
this
index
array
const attributes = this.attributes;

// attributes
attributes = this.attributes
attributes
this.attributes
this
attributes
// attributes

for (const name in attributes) {
  const attribute = attributes[name];
  const newAttribute = convertBufferAttribute(attribute, indices);
  geometry2.setAttribute(name, newAttribute);
}

// morph attributes
const name;
name
name
attributes
{
  const attribute = attributes[name];
  const newAttribute = convertBufferAttribute(attribute, indices);
  geometry2.setAttribute(name, newAttribute);
}
const attribute = attributes[name];
attribute = attributes[name]
attribute
attributes[name]
attributes
name
const newAttribute = convertBufferAttribute(attribute, indices);
newAttribute = convertBufferAttribute(attribute, indices)
newAttribute
convertBufferAttribute(attribute, indices)
convertBufferAttribute
attribute
indices
geometry2.setAttribute(name, newAttribute);
geometry2.setAttribute(name, newAttribute)
geometry2.setAttribute
geometry2
setAttribute
name
newAttribute
// morph attributes

const morphAttributes = this.morphAttributes;
morphAttributes = this.morphAttributes
morphAttributes
this.morphAttributes
this
morphAttributes
for (const name in morphAttributes) {
  const morphArray = [];
  const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

  for (let i = 0, il = morphAttribute.length; i < il; i++) {
    const attribute = morphAttribute[i];
    const newAttribute = convertBufferAttribute(attribute, indices);
    morphArray.push(newAttribute);
  }
  geometry2.morphAttributes[name] = morphArray;
}
const name;
name
name
morphAttributes
{
  const morphArray = [];
  const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

  for (let i = 0, il = morphAttribute.length; i < il; i++) {
    const attribute = morphAttribute[i];
    const newAttribute = convertBufferAttribute(attribute, indices);
    morphArray.push(newAttribute);
  }
  geometry2.morphAttributes[name] = morphArray;
}
const morphArray = [];
morphArray = []
morphArray
[]
const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes
morphAttribute = morphAttributes[name]
morphAttribute
morphAttributes[name]
morphAttributes
name
// morphAttribute: array of Float32BufferAttributes

for (let i = 0, il = morphAttribute.length; i < il; i++) {
  const attribute = morphAttribute[i];
  const newAttribute = convertBufferAttribute(attribute, indices);
  morphArray.push(newAttribute);
}
let i = 0,
  il = morphAttribute.length;
i = 0
i
0
il = morphAttribute.length
il
morphAttribute.length
morphAttribute
length
i < il
i
il
i++
i
{
  const attribute = morphAttribute[i];
  const newAttribute = convertBufferAttribute(attribute, indices);
  morphArray.push(newAttribute);
}
const attribute = morphAttribute[i];
attribute = morphAttribute[i]
attribute
morphAttribute[i]
morphAttribute
i
const newAttribute = convertBufferAttribute(attribute, indices);
newAttribute = convertBufferAttribute(attribute, indices)
newAttribute
convertBufferAttribute(attribute, indices)
convertBufferAttribute
attribute
indices
morphArray.push(newAttribute);
morphArray.push(newAttribute)
morphArray.push
morphArray
push
newAttribute
geometry2.morphAttributes[name] = morphArray;
geometry2.morphAttributes[name] = morphArray
geometry2.morphAttributes[name]
geometry2.morphAttributes
geometry2
morphAttributes
name
morphArray
geometry2.morphTargetsRelative = this.morphTargetsRelative;

// groups
geometry2.morphTargetsRelative = this.morphTargetsRelative
geometry2.morphTargetsRelative
geometry2
morphTargetsRelative
this.morphTargetsRelative
this
morphTargetsRelative
// groups

const groups = this.groups;
groups = this.groups
groups
this.groups
this
groups
for (let i = 0, l = groups.length; i < l; i++) {
  const group = groups[i];
  geometry2.addGroup(group.start, group.count, group.materialIndex);
}
let i = 0,
  l = groups.length;
i = 0
i
0
l = groups.length
l
groups.length
groups
length
i < l
i
l
i++
i
{
  const group = groups[i];
  geometry2.addGroup(group.start, group.count, group.materialIndex);
}
const group = groups[i];
group = groups[i]
group
groups[i]
groups
i
geometry2.addGroup(group.start, group.count, group.materialIndex);
geometry2.addGroup(group.start, group.count, group.materialIndex)
geometry2.addGroup
geometry2
addGroup
group.start
group
start
group.count
group
count
group.materialIndex
group
materialIndex
return geometry2;
geometry2
toJSON() {
  const data = {
    metadata: {
      version: 4.6,
      type: 'BufferGeometry',
      generator: 'BufferGeometry.toJSON'
    }
  };

  // standard BufferGeometry serialization

  data.uuid = this.uuid;
  data.type = this.type;
  if (this.name !== '') data.name = this.name;
  if (Object.keys(this.userData).length > 0) data.userData = this.userData;
  if (this.parameters !== undefined) {
    const parameters = this.parameters;
    for (const key in parameters) {
      if (parameters[key] !== undefined) data[key] = parameters[key];
    }
    return data;
  }

  // for simplicity the code assumes attributes are not shared across geometries, see #15811

  data.data = {
    attributes: {}
  };
  const index = this.index;
  if (index !== null) {
    data.data.index = {
      type: index.array.constructor.name,
      array: Array.prototype.slice.call(index.array)
    };
  }
  const attributes = this.attributes;
  for (const key in attributes) {
    const attribute = attributes[key];
    data.data.attributes[key] = attribute.toJSON(data.data);
  }
  const morphAttributes = {};
  let hasMorphAttributes = false;
  for (const key in this.morphAttributes) {
    const attributeArray = this.morphAttributes[key];
    const array = [];
    for (let i = 0, il = attributeArray.length; i < il; i++) {
      const attribute = attributeArray[i];
      array.push(attribute.toJSON(data.data));
    }
    if (array.length > 0) {
      morphAttributes[key] = array;
      hasMorphAttributes = true;
    }
  }
  if (hasMorphAttributes) {
    data.data.morphAttributes = morphAttributes;
    data.data.morphTargetsRelative = this.morphTargetsRelative;
  }
  const groups = this.groups;
  if (groups.length > 0) {
    data.data.groups = JSON.parse(JSON.stringify(groups));
  }
  const boundingSphere = this.boundingSphere;
  if (boundingSphere !== null) {
    data.data.boundingSphere = {
      center: boundingSphere.center.toArray(),
      radius: boundingSphere.radius
    };
  }
  return data;
}
toNonIndexed
{
  function convertBufferAttribute(attribute, indices) {
    const array = attribute.array;
    const itemSize = attribute.itemSize;
    const normalized = attribute.normalized;
    const array2 = new array.constructor(indices.length * itemSize);
    let index = 0,
      index2 = 0;
    for (let i = 0, l = indices.length; i < l; i++) {
      if (attribute.isInterleavedBufferAttribute) {
        index = indices[i] * attribute.data.stride + attribute.offset;
      } else {
        index = indices[i] * itemSize;
      }
      for (let j = 0; j < itemSize; j++) {
        array2[index2++] = array[index++];
      }
    }
    return new BufferAttribute(array2, itemSize, normalized);
  }

  //

  if (this.index === null) {
    console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
    return this;
  }
  const geometry2 = new BufferGeometry();
  const indices = this.index.array;
  const attributes = this.attributes;

  // attributes

  for (const name in attributes) {
    const attribute = attributes[name];
    const newAttribute = convertBufferAttribute(attribute, indices);
    geometry2.setAttribute(name, newAttribute);
  }

  // morph attributes

  const morphAttributes = this.morphAttributes;
  for (const name in morphAttributes) {
    const morphArray = [];
    const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

    for (let i = 0, il = morphAttribute.length; i < il; i++) {
      const attribute = morphAttribute[i];
      const newAttribute = convertBufferAttribute(attribute, indices);
      morphArray.push(newAttribute);
    }
    geometry2.morphAttributes[name] = morphArray;
  }
  geometry2.morphTargetsRelative = this.morphTargetsRelative;

  // groups

  const groups = this.groups;
  for (let i = 0, l = groups.length; i < l; i++) {
    const group = groups[i];
    geometry2.addGroup(group.start, group.count, group.materialIndex);
  }
  return geometry2;
}
function convertBufferAttribute(attribute, indices) {
  const array = attribute.array;
  const itemSize = attribute.itemSize;
  const normalized = attribute.normalized;
  const array2 = new array.constructor(indices.length * itemSize);
  let index = 0,
    index2 = 0;
  for (let i = 0, l = indices.length; i < l; i++) {
    if (attribute.isInterleavedBufferAttribute) {
      index = indices[i] * attribute.data.stride + attribute.offset;
    } else {
      index = indices[i] * itemSize;
    }
    for (let j = 0; j < itemSize; j++) {
      array2[index2++] = array[index++];
    }
  }
  return new BufferAttribute(array2, itemSize, normalized);
}

//
toJSON() {
  const data = {
    metadata: {
      version: 4.6,
      type: 'BufferGeometry',
      generator: 'BufferGeometry.toJSON'
    }
  };

  // standard BufferGeometry serialization

  data.uuid = this.uuid;
  data.type = this.type;
  if (this.name !== '') data.name = this.name;
  if (Object.keys(this.userData).length > 0) data.userData = this.userData;
  if (this.parameters !== undefined) {
    const parameters = this.parameters;
    for (const key in parameters) {
      if (parameters[key] !== undefined) data[key] = parameters[key];
    }
    return data;
  }

  // for simplicity the code assumes attributes are not shared across geometries, see #15811

  data.data = {
    attributes: {}
  };
  const index = this.index;
  if (index !== null) {
    data.data.index = {
      type: index.array.constructor.name,
      array: Array.prototype.slice.call(index.array)
    };
  }
  const attributes = this.attributes;
  for (const key in attributes) {
    const attribute = attributes[key];
    data.data.attributes[key] = attribute.toJSON(data.data);
  }
  const morphAttributes = {};
  let hasMorphAttributes = false;
  for (const key in this.morphAttributes) {
    const attributeArray = this.morphAttributes[key];
    const array = [];
    for (let i = 0, il = attributeArray.length; i < il; i++) {
      const attribute = attributeArray[i];
      array.push(attribute.toJSON(data.data));
    }
    if (array.length > 0) {
      morphAttributes[key] = array;
      hasMorphAttributes = true;
    }
  }
  if (hasMorphAttributes) {
    data.data.morphAttributes = morphAttributes;
    data.data.morphTargetsRelative = this.morphTargetsRelative;
  }
  const groups = this.groups;
  if (groups.length > 0) {
    data.data.groups = JSON.parse(JSON.stringify(groups));
  }
  const boundingSphere = this.boundingSphere;
  if (boundingSphere !== null) {
    data.data.boundingSphere = {
      center: boundingSphere.center.toArray(),
      radius: boundingSphere.radius
    };
  }
  return data;
}
toJSON
{
  const data = {
    metadata: {
      version: 4.6,
      type: 'BufferGeometry',
      generator: 'BufferGeometry.toJSON'
    }
  };

  // standard BufferGeometry serialization

  data.uuid = this.uuid;
  data.type = this.type;
  if (this.name !== '') data.name = this.name;
  if (Object.keys(this.userData).length > 0) data.userData = this.userData;
  if (this.parameters !== undefined) {
    const parameters = this.parameters;
    for (const key in parameters) {
      if (parameters[key] !== undefined) data[key] = parameters[key];
    }
    return data;
  }

  // for simplicity the code assumes attributes are not shared across geometries, see #15811

  data.data = {
    attributes: {}
  };
  const index = this.index;
  if (index !== null) {
    data.data.index = {
      type: index.array.constructor.name,
      array: Array.prototype.slice.call(index.array)
    };
  }
  const attributes = this.attributes;
  for (const key in attributes) {
    const attribute = attributes[key];
    data.data.attributes[key] = attribute.toJSON(data.data);
  }
  const morphAttributes = {};
  let hasMorphAttributes = false;
  for (const key in this.morphAttributes) {
    const attributeArray = this.morphAttributes[key];
    const array = [];
    for (let i = 0, il = attributeArray.length; i < il; i++) {
      const attribute = attributeArray[i];
      array.push(attribute.toJSON(data.data));
    }
    if (array.length > 0) {
      morphAttributes[key] = array;
      hasMorphAttributes = true;
    }
  }
  if (hasMorphAttributes) {
    data.data.morphAttributes = morphAttributes;
    data.data.morphTargetsRelative = this.morphTargetsRelative;
  }
  const groups = this.groups;
  if (groups.length > 0) {
    data.data.groups = JSON.parse(JSON.stringify(groups));
  }
  const boundingSphere = this.boundingSphere;
  if (boundingSphere !== null) {
    data.data.boundingSphere = {
      center: boundingSphere.center.toArray(),
      radius: boundingSphere.radius
    };
  }
  return data;
}
const data = {
  metadata: {
    version: 4.6,
    type: 'BufferGeometry',
    generator: 'BufferGeometry.toJSON'
  }
};

// standard BufferGeometry serialization
data = {
  metadata: {
    version: 4.6,
    type: 'BufferGeometry',
    generator: 'BufferGeometry.toJSON'
  }
}
data
{
  metadata: {
    version: 4.6,
    type: 'BufferGeometry',
    generator: 'BufferGeometry.toJSON'
  }
}
metadata: {
  version: 4.6,
  type: 'BufferGeometry',
  generator: 'BufferGeometry.toJSON'
}
metadata
{
  version: 4.6,
  type: 'BufferGeometry',
  generator: 'BufferGeometry.toJSON'
}
version: 4.6
version
4.6
type: 'BufferGeometry'
type
'BufferGeometry'
generator: 'BufferGeometry.toJSON'
generator
'BufferGeometry.toJSON'
// standard BufferGeometry serialization

data.uuid = this.uuid;
data.uuid = this.uuid
data.uuid
data
uuid
this.uuid
this
uuid
data.type = this.type;
data.type = this.type
data.type
data
type
this.type
this
type
if (this.name !== '') data.name = this.name;
this.name !== ''
this.name
this
name
''
data.name = this.name;
data.name = this.name
data.name
data
name
this.name
this
name
if (Object.keys(this.userData).length > 0) data.userData = this.userData;
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
data.userData = this.userData;
data.userData = this.userData
data.userData
data
userData
this.userData
this
userData
if (this.parameters !== undefined) {
  const parameters = this.parameters;
  for (const key in parameters) {
    if (parameters[key] !== undefined) data[key] = parameters[key];
  }
  return data;
}

// for simplicity the code assumes attributes are not shared across geometries, see #15811
this.parameters !== undefined
this.parameters
this
parameters
undefined
{
  const parameters = this.parameters;
  for (const key in parameters) {
    if (parameters[key] !== undefined) data[key] = parameters[key];
  }
  return data;
}
const parameters = this.parameters;
parameters = this.parameters
parameters
this.parameters
this
parameters
for (const key in parameters) {
  if (parameters[key] !== undefined) data[key] = parameters[key];
}
const key;
key
key
parameters
{
  if (parameters[key] !== undefined) data[key] = parameters[key];
}
if (parameters[key] !== undefined) data[key] = parameters[key];
parameters[key] !== undefined
parameters[key]
parameters
key
undefined
data[key] = parameters[key];
data[key] = parameters[key]
data[key]
data
key
parameters[key]
parameters
key
return data;
data
// for simplicity the code assumes attributes are not shared across geometries, see #15811

data.data = {
  attributes: {}
};
data.data = {
  attributes: {}
}
data.data
data
data
{
  attributes: {}
}
attributes: {}
attributes
{}
const index = this.index;
index = this.index
index
this.index
this
index
if (index !== null) {
  data.data.index = {
    type: index.array.constructor.name,
    array: Array.prototype.slice.call(index.array)
  };
}
index !== null
index
null
{
  data.data.index = {
    type: index.array.constructor.name,
    array: Array.prototype.slice.call(index.array)
  };
}
data.data.index = {
  type: index.array.constructor.name,
  array: Array.prototype.slice.call(index.array)
};
data.data.index = {
  type: index.array.constructor.name,
  array: Array.prototype.slice.call(index.array)
}
data.data.index
data.data
data
data
index
{
  type: index.array.constructor.name,
  array: Array.prototype.slice.call(index.array)
}
type: index.array.constructor.name
type
index.array.constructor.name
index.array.constructor
index.array
index
array
constructor
name
array: Array.prototype.slice.call(index.array)
array
Array.prototype.slice.call(index.array)
Array.prototype.slice.call
Array.prototype.slice
Array.prototype
Array
prototype
slice
call
index.array
index
array
const attributes = this.attributes;
attributes = this.attributes
attributes
this.attributes
this
attributes
for (const key in attributes) {
  const attribute = attributes[key];
  data.data.attributes[key] = attribute.toJSON(data.data);
}
const key;
key
key
attributes
{
  const attribute = attributes[key];
  data.data.attributes[key] = attribute.toJSON(data.data);
}
const attribute = attributes[key];
attribute = attributes[key]
attribute
attributes[key]
attributes
key
data.data.attributes[key] = attribute.toJSON(data.data);
data.data.attributes[key] = attribute.toJSON(data.data)
data.data.attributes[key]
data.data.attributes
data.data
data
data
attributes
key
attribute.toJSON(data.data)
attribute.toJSON
attribute
toJSON
data.data
data
data
const morphAttributes = {};
morphAttributes = {}
morphAttributes
{}
let hasMorphAttributes = false;
hasMorphAttributes = false
hasMorphAttributes
false
for (const key in this.morphAttributes) {
  const attributeArray = this.morphAttributes[key];
  const array = [];
  for (let i = 0, il = attributeArray.length; i < il; i++) {
    const attribute = attributeArray[i];
    array.push(attribute.toJSON(data.data));
  }
  if (array.length > 0) {
    morphAttributes[key] = array;
    hasMorphAttributes = true;
  }
}
const key;
key
key
this.morphAttributes
this
morphAttributes
{
  const attributeArray = this.morphAttributes[key];
  const array = [];
  for (let i = 0, il = attributeArray.length; i < il; i++) {
    const attribute = attributeArray[i];
    array.push(attribute.toJSON(data.data));
  }
  if (array.length > 0) {
    morphAttributes[key] = array;
    hasMorphAttributes = true;
  }
}
const attributeArray = this.morphAttributes[key];
attributeArray = this.morphAttributes[key]
attributeArray
this.morphAttributes[key]
this.morphAttributes
this
morphAttributes
key
const array = [];
array = []
array
[]
for (let i = 0, il = attributeArray.length; i < il; i++) {
  const attribute = attributeArray[i];
  array.push(attribute.toJSON(data.data));
}
let i = 0,
  il = attributeArray.length;
i = 0
i
0
il = attributeArray.length
il
attributeArray.length
attributeArray
length
i < il
i
il
i++
i
{
  const attribute = attributeArray[i];
  array.push(attribute.toJSON(data.data));
}
const attribute = attributeArray[i];
attribute = attributeArray[i]
attribute
attributeArray[i]
attributeArray
i
array.push(attribute.toJSON(data.data));
array.push(attribute.toJSON(data.data))
array.push
array
push
attribute.toJSON(data.data)
attribute.toJSON
attribute
toJSON
data.data
data
data
if (array.length > 0) {
  morphAttributes[key] = array;
  hasMorphAttributes = true;
}
array.length > 0
array.length
array
length
0
{
  morphAttributes[key] = array;
  hasMorphAttributes = true;
}
morphAttributes[key] = array;
morphAttributes[key] = array
morphAttributes[key]
morphAttributes
key
array
hasMorphAttributes = true;
hasMorphAttributes = true
hasMorphAttributes
true
if (hasMorphAttributes) {
  data.data.morphAttributes = morphAttributes;
  data.data.morphTargetsRelative = this.morphTargetsRelative;
}
hasMorphAttributes
{
  data.data.morphAttributes = morphAttributes;
  data.data.morphTargetsRelative = this.morphTargetsRelative;
}
data.data.morphAttributes = morphAttributes;
data.data.morphAttributes = morphAttributes
data.data.morphAttributes
data.data
data
data
morphAttributes
morphAttributes
data.data.morphTargetsRelative = this.morphTargetsRelative;
data.data.morphTargetsRelative = this.morphTargetsRelative
data.data.morphTargetsRelative
data.data
data
data
morphTargetsRelative
this.morphTargetsRelative
this
morphTargetsRelative
const groups = this.groups;
groups = this.groups
groups
this.groups
this
groups
if (groups.length > 0) {
  data.data.groups = JSON.parse(JSON.stringify(groups));
}
groups.length > 0
groups.length
groups
length
0
{
  data.data.groups = JSON.parse(JSON.stringify(groups));
}
data.data.groups = JSON.parse(JSON.stringify(groups));
data.data.groups = JSON.parse(JSON.stringify(groups))
data.data.groups
data.data
data
data
groups
JSON.parse(JSON.stringify(groups))
JSON.parse
JSON
parse
JSON.stringify(groups)
JSON.stringify
JSON
stringify
groups
const boundingSphere = this.boundingSphere;
boundingSphere = this.boundingSphere
boundingSphere
this.boundingSphere
this
boundingSphere
if (boundingSphere !== null) {
  data.data.boundingSphere = {
    center: boundingSphere.center.toArray(),
    radius: boundingSphere.radius
  };
}
boundingSphere !== null
boundingSphere
null
{
  data.data.boundingSphere = {
    center: boundingSphere.center.toArray(),
    radius: boundingSphere.radius
  };
}
data.data.boundingSphere = {
  center: boundingSphere.center.toArray(),
  radius: boundingSphere.radius
};
data.data.boundingSphere = {
  center: boundingSphere.center.toArray(),
  radius: boundingSphere.radius
}
data.data.boundingSphere
data.data
data
data
boundingSphere
{
  center: boundingSphere.center.toArray(),
  radius: boundingSphere.radius
}
center: boundingSphere.center.toArray()
center
boundingSphere.center.toArray()
boundingSphere.center.toArray
boundingSphere.center
boundingSphere
center
toArray
radius: boundingSphere.radius
radius
boundingSphere.radius
boundingSphere
radius
return data;
data
clone() {
  return new this.constructor().copy(this);
}
clone() {
  return new this.constructor().copy(this);
}
clone
{
  return new this.constructor().copy(this);
}
return new this.constructor().copy(this);
new this.constructor().copy(this)
new this.constructor().copy
new this.constructor()
this.constructor
this
constructor
copy
this
copy(source) {
  // reset

  this.index = null;
  this.attributes = {};
  this.morphAttributes = {};
  this.groups = [];
  this.boundingBox = null;
  this.boundingSphere = null;

  // used for storing cloned, shared data

  const data = {};

  // name

  this.name = source.name;

  // index

  const index = source.index;
  if (index !== null) {
    this.setIndex(index.clone(data));
  }

  // attributes

  const attributes = source.attributes;
  for (const name in attributes) {
    const attribute = attributes[name];
    this.setAttribute(name, attribute.clone(data));
  }

  // morph attributes

  const morphAttributes = source.morphAttributes;
  for (const name in morphAttributes) {
    const array = [];
    const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

    for (let i = 0, l = morphAttribute.length; i < l; i++) {
      array.push(morphAttribute[i].clone(data));
    }
    this.morphAttributes[name] = array;
  }
  this.morphTargetsRelative = source.morphTargetsRelative;

  // groups

  const groups = source.groups;
  for (let i = 0, l = groups.length; i < l; i++) {
    const group = groups[i];
    this.addGroup(group.start, group.count, group.materialIndex);
  }

  // bounding box

  const boundingBox = source.boundingBox;
  if (boundingBox !== null) {
    this.boundingBox = boundingBox.clone();
  }

  // bounding sphere

  const boundingSphere = source.boundingSphere;
  if (boundingSphere !== null) {
    this.boundingSphere = boundingSphere.clone();
  }

  // draw range

  this.drawRange.start = source.drawRange.start;
  this.drawRange.count = source.drawRange.count;

  // user data

  this.userData = source.userData;
  return this;
}
copy(source) {
  // reset

  this.index = null;
  this.attributes = {};
  this.morphAttributes = {};
  this.groups = [];
  this.boundingBox = null;
  this.boundingSphere = null;

  // used for storing cloned, shared data

  const data = {};

  // name

  this.name = source.name;

  // index

  const index = source.index;
  if (index !== null) {
    this.setIndex(index.clone(data));
  }

  // attributes

  const attributes = source.attributes;
  for (const name in attributes) {
    const attribute = attributes[name];
    this.setAttribute(name, attribute.clone(data));
  }

  // morph attributes

  const morphAttributes = source.morphAttributes;
  for (const name in morphAttributes) {
    const array = [];
    const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

    for (let i = 0, l = morphAttribute.length; i < l; i++) {
      array.push(morphAttribute[i].clone(data));
    }
    this.morphAttributes[name] = array;
  }
  this.morphTargetsRelative = source.morphTargetsRelative;

  // groups

  const groups = source.groups;
  for (let i = 0, l = groups.length; i < l; i++) {
    const group = groups[i];
    this.addGroup(group.start, group.count, group.materialIndex);
  }

  // bounding box

  const boundingBox = source.boundingBox;
  if (boundingBox !== null) {
    this.boundingBox = boundingBox.clone();
  }

  // bounding sphere

  const boundingSphere = source.boundingSphere;
  if (boundingSphere !== null) {
    this.boundingSphere = boundingSphere.clone();
  }

  // draw range

  this.drawRange.start = source.drawRange.start;
  this.drawRange.count = source.drawRange.count;

  // user data

  this.userData = source.userData;
  return this;
}
copy
source
{
  // reset

  this.index = null;
  this.attributes = {};
  this.morphAttributes = {};
  this.groups = [];
  this.boundingBox = null;
  this.boundingSphere = null;

  // used for storing cloned, shared data

  const data = {};

  // name

  this.name = source.name;

  // index

  const index = source.index;
  if (index !== null) {
    this.setIndex(index.clone(data));
  }

  // attributes

  const attributes = source.attributes;
  for (const name in attributes) {
    const attribute = attributes[name];
    this.setAttribute(name, attribute.clone(data));
  }

  // morph attributes

  const morphAttributes = source.morphAttributes;
  for (const name in morphAttributes) {
    const array = [];
    const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

    for (let i = 0, l = morphAttribute.length; i < l; i++) {
      array.push(morphAttribute[i].clone(data));
    }
    this.morphAttributes[name] = array;
  }
  this.morphTargetsRelative = source.morphTargetsRelative;

  // groups

  const groups = source.groups;
  for (let i = 0, l = groups.length; i < l; i++) {
    const group = groups[i];
    this.addGroup(group.start, group.count, group.materialIndex);
  }

  // bounding box

  const boundingBox = source.boundingBox;
  if (boundingBox !== null) {
    this.boundingBox = boundingBox.clone();
  }

  // bounding sphere

  const boundingSphere = source.boundingSphere;
  if (boundingSphere !== null) {
    this.boundingSphere = boundingSphere.clone();
  }

  // draw range

  this.drawRange.start = source.drawRange.start;
  this.drawRange.count = source.drawRange.count;

  // user data

  this.userData = source.userData;
  return this;
}
// reset

this.index = null;
this.index = null
this.index
this
index
null
this.attributes = {};
this.attributes = {}
this.attributes
this
attributes
{}
this.morphAttributes = {};
this.morphAttributes = {}
this.morphAttributes
this
morphAttributes
{}
this.groups = [];
this.groups = []
this.groups
this
groups
[]
this.boundingBox = null;
this.boundingBox = null
this.boundingBox
this
boundingBox
null
this.boundingSphere = null;

// used for storing cloned, shared data
this.boundingSphere = null
this.boundingSphere
this
boundingSphere
null
// used for storing cloned, shared data

const data = {};

// name
data = {}
data
{}
// name

this.name = source.name;

// index
this.name = source.name
this.name
this
name
source.name
source
name
// index

const index = source.index;
index = source.index
index
source.index
source
index
if (index !== null) {
  this.setIndex(index.clone(data));
}

// attributes
index !== null
index
null
{
  this.setIndex(index.clone(data));
}
this.setIndex(index.clone(data));
this.setIndex(index.clone(data))
this.setIndex
this
setIndex
index.clone(data)
index.clone
index
clone
data
// attributes

const attributes = source.attributes;
attributes = source.attributes
attributes
source.attributes
source
attributes
for (const name in attributes) {
  const attribute = attributes[name];
  this.setAttribute(name, attribute.clone(data));
}

// morph attributes
const name;
name
name
attributes
{
  const attribute = attributes[name];
  this.setAttribute(name, attribute.clone(data));
}
const attribute = attributes[name];
attribute = attributes[name]
attribute
attributes[name]
attributes
name
this.setAttribute(name, attribute.clone(data));
this.setAttribute(name, attribute.clone(data))
this.setAttribute
this
setAttribute
name
attribute.clone(data)
attribute.clone
attribute
clone
data
// morph attributes

const morphAttributes = source.morphAttributes;
morphAttributes = source.morphAttributes
morphAttributes
source.morphAttributes
source
morphAttributes
for (const name in morphAttributes) {
  const array = [];
  const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

  for (let i = 0, l = morphAttribute.length; i < l; i++) {
    array.push(morphAttribute[i].clone(data));
  }
  this.morphAttributes[name] = array;
}
const name;
name
name
morphAttributes
{
  const array = [];
  const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes

  for (let i = 0, l = morphAttribute.length; i < l; i++) {
    array.push(morphAttribute[i].clone(data));
  }
  this.morphAttributes[name] = array;
}
const array = [];
array = []
array
[]
const morphAttribute = morphAttributes[name]; // morphAttribute: array of Float32BufferAttributes
morphAttribute = morphAttributes[name]
morphAttribute
morphAttributes[name]
morphAttributes
name
// morphAttribute: array of Float32BufferAttributes

for (let i = 0, l = morphAttribute.length; i < l; i++) {
  array.push(morphAttribute[i].clone(data));
}
let i = 0,
  l = morphAttribute.length;
i = 0
i
0
l = morphAttribute.length
l
morphAttribute.length
morphAttribute
length
i < l
i
l
i++
i
{
  array.push(morphAttribute[i].clone(data));
}
array.push(morphAttribute[i].clone(data));
array.push(morphAttribute[i].clone(data))
array.push
array
push
morphAttribute[i].clone(data)
morphAttribute[i].clone
morphAttribute[i]
morphAttribute
i
clone
data
this.morphAttributes[name] = array;
this.morphAttributes[name] = array
this.morphAttributes[name]
this.morphAttributes
this
morphAttributes
name
array
this.morphTargetsRelative = source.morphTargetsRelative;

// groups
this.morphTargetsRelative = source.morphTargetsRelative
this.morphTargetsRelative
this
morphTargetsRelative
source.morphTargetsRelative
source
morphTargetsRelative
// groups

const groups = source.groups;
groups = source.groups
groups
source.groups
source
groups
for (let i = 0, l = groups.length; i < l; i++) {
  const group = groups[i];
  this.addGroup(group.start, group.count, group.materialIndex);
}

// bounding box
let i = 0,
  l = groups.length;
i = 0
i
0
l = groups.length
l
groups.length
groups
length
i < l
i
l
i++
i
{
  const group = groups[i];
  this.addGroup(group.start, group.count, group.materialIndex);
}
const group = groups[i];
group = groups[i]
group
groups[i]
groups
i
this.addGroup(group.start, group.count, group.materialIndex);
this.addGroup(group.start, group.count, group.materialIndex)
this.addGroup
this
addGroup
group.start
group
start
group.count
group
count
group.materialIndex
group
materialIndex
// bounding box

const boundingBox = source.boundingBox;
boundingBox = source.boundingBox
boundingBox
source.boundingBox
source
boundingBox
if (boundingBox !== null) {
  this.boundingBox = boundingBox.clone();
}

// bounding sphere
boundingBox !== null
boundingBox
null
{
  this.boundingBox = boundingBox.clone();
}
this.boundingBox = boundingBox.clone();
this.boundingBox = boundingBox.clone()
this.boundingBox
this
boundingBox
boundingBox.clone()
boundingBox.clone
boundingBox
clone
// bounding sphere

const boundingSphere = source.boundingSphere;
boundingSphere = source.boundingSphere
boundingSphere
source.boundingSphere
source
boundingSphere
if (boundingSphere !== null) {
  this.boundingSphere = boundingSphere.clone();
}

// draw range
boundingSphere !== null
boundingSphere
null
{
  this.boundingSphere = boundingSphere.clone();
}
this.boundingSphere = boundingSphere.clone();
this.boundingSphere = boundingSphere.clone()
this.boundingSphere
this
boundingSphere
boundingSphere.clone()
boundingSphere.clone
boundingSphere
clone
// draw range

this.drawRange.start = source.drawRange.start;
this.drawRange.start = source.drawRange.start
this.drawRange.start
this.drawRange
this
drawRange
start
source.drawRange.start
source.drawRange
source
drawRange
start
this.drawRange.count = source.drawRange.count;

// user data
this.drawRange.count = source.drawRange.count
this.drawRange.count
this.drawRange
this
drawRange
count
source.drawRange.count
source.drawRange
source
drawRange
count
// user data

this.userData = source.userData;
this.userData = source.userData
this.userData
this
userData
source.userData
source
userData
return this;
this
dispose() {
  this.dispatchEvent({
    type: 'dispose'
  });
}
dispose() {
  this.dispatchEvent({
    type: 'dispose'
  });
}
dispose
{
  this.dispatchEvent({
    type: 'dispose'
  });
}
this.dispatchEvent({
  type: 'dispose'
});
this.dispatchEvent({
  type: 'dispose'
})
this.dispatchEvent
this
dispatchEvent
{
  type: 'dispose'
}
type: 'dispose'
type
'dispose'
EventDispatcher
export { BufferGeometry };
BufferGeometry
BufferGeometry
BufferGeometry