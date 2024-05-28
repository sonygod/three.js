import MathUtils from '../math/MathUtils';
import Vector3 from '../math/Vector3';
import Vector2 from '../math/Vector2';
import Box3 from '../math/Box3';
import Sphere from '../math/Sphere';
import Matrix4 from '../math/Matrix4';
import Matrix3 from '../math/Matrix3';
import EventDispatcher from './EventDispatcher';
import BufferAttribute from './BufferAttribute';
import Float32BufferAttribute from './Float32BufferAttribute';
import Uint16BufferAttribute from './Uint16BufferAttribute';
import Uint32BufferAttribute from './Uint32BufferAttribute';
import Object3D from './Object3D';

let _id = 0;

const _m1 = new Matrix4();
const _obj = new Object3D();
const _offset = new Vector3();
const _box = new Box3();
const _boxMorphTargets = new Box3();
const _vector = new Vector3();

class BufferGeometry extends EventDispatcher {
  public isBufferGeometry: Bool;
  public id: Int;
  public uuid: String;
  public name: String;
  public type: String;
  public index: Null<BufferAttribute>;
  public attributes: Map<String, BufferAttribute>;
  public morphAttributes: Map<String, Array<BufferAttribute>>;
  public morphTargetsRelative: Bool;
  public groups: Array<{ start: Int, count: Int, materialIndex: Int }>;
  public boundingBox: Null<Box3>;
  public boundingSphere: Null<Sphere>;
  public drawRange: { start: Int, count: Int };
  public userData: Map<String, Any>;

  public function new() {
    super();

    isBufferGeometry = true;
    id = _id++;
    uuid = MathUtils.generateUUID();
    name = '';
    type = 'BufferGeometry';
    index = null;
    attributes = new Map();
    morphAttributes = new Map();
    morphTargetsRelative = false;
    groups = [];
    boundingBox = null;
    boundingSphere = null;
    drawRange = { start: 0, count: Int.POSITIVE_INFINITY };
    userData = new Map();
  }

  public function getIndex(): Null<BufferAttribute> {
    return index;
  }

  public function setIndex(index: Array<Int> | BufferAttribute): BufferGeometry {
    if (Type.enumEq(index, Array<Int>)) {
      this.index = (if (arrayNeedsUint32(index)) new Uint32BufferAttribute(index, 1) else new Uint16BufferAttribute(index, 1));
    } else {
      this.index = cast(index, BufferAttribute);
    }
    return this;
  }

  public function getAttribute(name: String): Null<BufferAttribute> {
    return attributes.get(name);
  }

  public function setAttribute(name: String, attribute: BufferAttribute): BufferGeometry {
    attributes.set(name, attribute);
    return this;
  }

  public function deleteAttribute(name: String): BufferGeometry {
    attributes.remove(name);
    return this;
  }

  public function hasAttribute(name: String): Bool {
    return attributes.exists(name);
  }

  public function addGroup(start: Int, count: Int, materialIndex: Int = 0): Void {
    groups.push({ start, count, materialIndex });
  }

  public function clearGroups(): Void {
    groups = [];
  }

  public function setDrawRange(start: Int, count: Int): Void {
    drawRange.start = start;
    drawRange.count = count;
  }

  public function applyMatrix4(matrix: Matrix4): BufferGeometry {
    var position = attributes.get('position');
    if (position != null) {
      position.applyMatrix4(matrix);
      position.needsUpdate = true;
    }

    var normal = attributes.get('normal');
    if (normal != null) {
      var normalMatrix = new Matrix3().getNormalMatrix(matrix);
      normal.applyNormalMatrix(normalMatrix);
      normal.needsUpdate = true;
    }

    var tangent = attributes.get('tangent');
    if (tangent != null) {
      tangent.transformDirection(matrix);
      tangent.needsUpdate = true;
    }

    if (boundingBox != null) {
      computeBoundingBox();
    }

    if (boundingSphere != null) {
      computeBoundingSphere();
    }

    return this;
  }

  public function applyQuaternion(q: Quaternion): BufferGeometry {
    _m1.makeRotationFromQuaternion(q);
    applyMatrix4(_m1);
    return this;
  }

  public function rotateX(angle: Float): BufferGeometry {
    _m1.makeRotationX(angle);
    applyMatrix4(_m1);
    return this;
  }

  public function rotateY(angle: Float): BufferGeometry {
    _m1.makeRotationY(angle);
    applyMatrix4(_m1);
    return this;
  }

  public function rotateZ(angle: Float): BufferGeometry {
    _m1.makeRotationZ(angle);
    applyMatrix4(_m1);
    return this;
  }

  public function translate(x: Float, y: Float, z: Float): BufferGeometry {
    _m1.makeTranslation(x, y, z);
    applyMatrix4(_m1);
    return this;
  }

  public function scale(x: Float, y: Float, z: Float): BufferGeometry {
    _m1.makeScale(x, y, z);
    applyMatrix4(_m1);
    return this;
  }

  public function lookAt(vector: Vector3): BufferGeometry {
    _obj.lookAt(vector);
    _obj.updateMatrix();
    applyMatrix4(_obj.matrix);
    return this;
  }

  public function center(): BufferGeometry {
    computeBoundingBox();
    boundingBox.getCenter(_offset).negate();
    translate(_offset.x, _offset.y, _offset.z);
    return this;
  }

  public function setFromPoints(points: Array<Vector3>): BufferGeometry {
    var position = [];
    for (point in points) {
      var p = cast(point, Vector3);
      position.push(p.x, p.y, p.z);
    }
    setAttribute('position', new Float32BufferAttribute(position, 3));
    return this;
  }

  public function computeBoundingBox(): Void {
    if (boundingBox == null) {
      boundingBox = new Box3();
    }

    var position = attributes.get('position');
    var morphAttributesPosition = morphAttributes.get('position');

    if (position != null && position.isGLBufferAttribute) {
      trace('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
      boundingBox.set(new Vector3(-Float.POSITIVE_INFINITY, -Float.POSITIVE_INFINITY, -Float.POSITIVE_INFINITY), new Vector3(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY));
      return;
    }

    if (position != null) {
      boundingBox.setFromBufferAttribute(position);

      // process morph attributes if present
      if (morphAttributesPosition != null) {
        for (morphAttribute in morphAttributesPosition) {
          _box.setFromBufferAttribute(cast(morphAttribute, BufferAttribute));

          if (morphTargetsRelative) {
            _vector.addVectors(boundingBox.min, _box.min);
            boundingBox.expandByPoint(_vector);

            _vector.addVectors(boundingBox.max, _box.max);
            boundingBox.expandByPoint(_vector);
          } else {
            boundingBox.expandByPoint(_box.min);
            boundingBox.expandByPoint(_box.max);
          }
        }
      }
    } else {
      boundingBox.makeEmpty();
    }

    if (isNaN(boundingBox.min.x) || isNaN(boundingBox.min.y) || isNaN(boundingBox.min.z)) {
      trace('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
    }
  }

  public function computeBoundingSphere(): Void {
    if (boundingSphere == null) {
      boundingSphere = new Sphere();
    }

    var position = attributes.get('position');
    var morphAttributesPosition = morphAttributes.get('position');

    if (position != null && position.isGLBufferAttribute) {
      trace('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
      boundingSphere.set(new Vector3(), Float.POSITIVE_INFINITY);
      return;
    }

    if (position != null) {
      // first, find the center of the bounding sphere

      var center = boundingSphere.center;

      _box.setFromBufferAttribute(position);

      // process morph attributes if present
      if (morphAttributesPosition != null) {
        for (morphAttribute in morphAttributesPosition) {
          _boxMorphTargets.setFromBufferAttribute(cast(morphAttribute, BufferAttribute));

          if (morphTargetsRelative) {
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

      var maxRadiusSq = 0.0;

      for (i in 0...position.count) {
        _vector.fromBufferAttribute(position, i);
        maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
      }

      // process morph attributes if present
      if (morphAttributesPosition != null) {
        for (morphAttribute in morphAttributesPosition) {
          var morphTargetsRelative = this.morphTargetsRelative;

          for (j in 0...morphAttribute.count) {
            _vector.fromBufferAttribute(morphAttribute, j);

            if (morphTargetsRelative) {
              _offset.fromBufferAttribute(position, j);
              _vector.add(_offset);
            }

            maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
          }
        }
      }

      boundingSphere.radius = Math.sqrt(maxRadiusSq);

      if (isNaN(boundingSphere.radius)) {
        trace('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
      }
    }
  }

  public function computeTangents(): Void {
    var index = this.index;
    var attributes = this.attributes;

    // based on http://www.terathon.com/code/tangent.html
    // (per vertex tangents)

    if (index == null || attributes.get('position') == null || attributes.get('normal') == null || attributes.get('uv') == null) {
      trace('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
      return;
    }

    var positionAttribute = attributes.get('position');
    var normalAttribute = attributes.get('normal');
    var uvAttribute = attributes.get('uv');

    if (!attributes.exists('tangent')) {
      setAttribute('tangent', new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
    }

    var tangentAttribute = getAttribute('tangent');

    var tan1 = [], tan2 = [];

    for (i in 0...positionAttribute.count) {
      tan1[i] = new Vector3();
      tan2[i] = new Vector3();
    }

    var vA = new Vector3(),
      vB = new Vector3(),
      vC = new Vector3(),

      uvA = new Vector2(),
      uvB = new Vector2(),
      uvC = new Vector2(),

      sdir = new Vector3(),
      tdir = new Vector3();

    function handleTriangle(a: Int, b: Int, c: Int): Void {
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

      var r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

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

    var groups = this.groups;

    if (groups.length == 0) {
      groups = [{
        start: 0,
        count: index.count
      }];
    }

    for (i in 0...groups.length) {
      var group = groups[i];

      var start = group.start;
      var count = group.count;

      for (j in start...(start + count).idiv(3)) {
        handleTriangle(
          index.getX(j),
          index.getX(j + 1),
          index.getX(j + 2)
        );
      }
    }

    var tmp = new Vector3(), tmp2 = new Vector3();
    var n = new Vector3(), n2 = new Vector3();

    function handleVertex(v: Int): Void {
      n.fromBufferAttribute(normalAttribute, v);
      n2.copy(n);

      var t = tan1[v];

      // Gram-Schmidt orthogonalize

      tmp.copy(t);
      tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

      // Calculate handedness

      tmp2.crossVectors(n2, t);
      var test = tmp2.dot(tan2[v]);
      var w = (test < 0.0) ? -1.0 : 1.0;

      tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
    }

    for (i in 0...groups.length) {
      var group = groups[i];

      var start = group.start;
      var count = group.count;

      for (j in start...(start + count).idiv(3)) {
        handleVertex(index.getX(j));
        handleVertex(index.getX(j + 1));
        handleVertex(index.getX(j + 2));
      }
    }
  }

  public function computeVertexNormals(): Void {
    var index = this.index;
    var positionAttribute = getAttribute('position');

    if (positionAttribute != null) {
      var normalAttribute = getAttribute('normal');

      if (normalAttribute == null) {
        normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
        setAttribute('normal', normalAttribute);
      } else {
        // reset existing normals to zero
        for (i in 0...normalAttribute.count) {
          normalAttribute.setXYZ(i, 0.0, 0.0, 0.0);
        }
      }

      var pA = new Vector3(), pB = new Vector3(), pC = new Vector3();
      var nA = new Vector3(), nB = new Vector3(), nC = new Vector3();
      var cb = new Vector3(), ab = new Vector3();

      // indexed elements
      if (index != null) {
        for (i in 0...index.count) {
          var vA = index.getX(i);
          var vB = index.getX(i + 1);
          var vC = index.getX(i + 2);

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
        for (i in 0...positionAttribute.count) {
          pA.fromBufferAttribute(positionAttribute, i);
          pB.fromBufferAttribute(positionAttribute, i + 1);
          pC.fromBufferAttribute(positionAttribute, i + 2);
          cb.subVectors(pC, pB);
          ab.subVectors(pA, pB);
          cb.cross(ab);

          normalAttribute.setXYZ(i, cb.x, cb.y, cb.z);
          normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
          normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
        }
      }

      normalizeNormals();

      normalAttribute.needsUpdate = true;
    }
  }

  public function normalizeNormals(): Void {
    var normals = getAttribute('normal');

    for (i in 0...normals.count) {
      _vector.fromBufferAttribute(normals, i);
      _vector.normalize();
      normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
    }
  }

  public function toNonIndexed(): BufferGeometry {
    function convertBufferAttribute(attribute: BufferAttribute, indices: Array<Int>): BufferAttribute {
      var array = attribute.array;
      var itemSize = attribute.itemSize;
      var normalized = attribute.normalized;

      var array2 = new Array<Dynamic>(indices.length * itemSize);

      var index = 0, index2 = 0;

      for (i in 0...indices.length) {
        var idx = indices[i];

        if (attribute.isInterleavedBufferAttribute) {
          index = idx * attribute.data.stride + attribute.offset;
        } else {
          index = idx * itemSize;
        }

        for (j in 0...itemSize) {
          array2[index2++] = array[index++];
        }
      }

      return new BufferAttribute(array2, itemSize, normalized);
    }

    //

    if (index == null) {
      trace('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
      return this;
    }

    var geometry2 = new BufferGeometry();

    var indices = index.array;
    var attributes = this.attributes;

    // attributes

    for (name in attributes) {
      var attribute = attributes.get(name);
      var newAttribute = convertBufferAttribute(attribute, indices);
      geometry2.setAttribute(name, newAttribute);
    }

    // morph attributes

    var morphAttributes = this.morphAttributes;

    for (name in morphAttributes) {
      var morphArray = [];
      var morphAttribute = morphAttributes.get(name); // morphAttribute: array of Float32BufferAttributes

      for (i in 0...morphAttribute.length) {
        var attribute = morphAttribute[i];
        var newAttribute = convertBufferAttribute(attribute, indices);
        morphArray.push(newAttribute);
      }

      geometry2.morphAttributes.set(name, morphArray);
    }

    geometry2.morphTargetsRelative = this.morphTargetsRelative;

    // groups

    var groups = this.groups;

    for (i in 0...groups.length) {
      var group = groups[i];
      geometry2.addGroup(group.start, group.count, group.materialIndex);
    }

    return geometry2;
  }

  public function toJSON(): Map<String, Any> {
    var data = {
      metadata: {
        version: 4.6,
        type: 'BufferGeometry',
        generator: 'BufferGeometry.toJSON'
      }
    };

    // standard BufferGeometry serialization

    data.uuid = uuid;
    data.type = type;
    if (name != '') data.name = name;
    if (userData.keys().length > 0) data.userData = userData;

    if (parameters != null) {
      for (key in parameters) {
        if (parameters.get(key) != null) data[key] = parameters.get(key);
      }

      return data;
    }

    // for simplicity the code assumes attributes are not shared across geometries, see #15811

    data.data = { attributes: new Map<String, Any>() };

    var index = this.index;

    if (index != null) {
      data.data.index = {
        type: Type.enumName(index.array),
        array: index.array.slice()
      };
    }

    var attributes = this.attributes;

    for (name in attributes) {
      var attribute = attributes.get(name);
      data.data.attributes.set(name, attribute.toJSON(data.data));
    }

    var morphAttributes = new Map<String, Array<Map<String, Any>>>();
    var hasMorphAttributes = false;

    for (name in morphAttributes) {
      var attributeArray = [];
      var morphAttribute = morphAttributes.get(name); // morphAttribute: array of Float32BufferAttributes

      for (i in 0...morphAttribute.length) {
        var attribute = morphAttribute[i];
        attributeArray.push(attribute.toJSON(data.data));
      }

      if (attributeArray.length > 0) {
        morphAttributes.set(name, attributeArray);
        hasMorphAttributes = true;
      }
    }

    if (hasMorphAttributes) {
      data.data.morphAttributes = morphAttributes;
      data.data.morphTargetsRelative = morphTargetsRelative;
    }

    var groups = this.groups;

    if (groups.length > 0) {
      data.data.groups = groups;
    }

    var boundingSphere = this.boundingSphere;

    if (boundingSphere != null) {
      data.data.boundingSphere = {
        center: boundingSphere.center.toArray(),
        radius: boundingSphere.radius
      };
    }

    return data;
  }

  public function clone(): BufferGeometry {
    return new BufferGeometry().copy(this);
  }

  public function copy(source: BufferGeometry): BufferGeometry {
    // reset

    index = null;
    attributes = new Map();
    morphAttributes = new Map();
    groups = [];
    boundingBox = null;
    boundingSphere = null;

    // used for storing cloned, shared data

    var data = new Map();

    // name

    name = source.name;

    // index

    var index = source.index;

    if (index != null) {
      setIndex(index.clone(data));
    }

    // attributes

    var attributes = source.attributes;

    for (name in attributes) {
      var attribute = attributes.get(name);
      setAttribute(name, attribute.clone(data));
    }

    // morph attributes

    var morphAttributes = source.morphAttributes;

    for (name in morphAttributes) {
      var array = [];
      var morphAttribute = morphAttributes.get(name); // morphAttribute: array of Float32BufferAttributes

      for (i in 0...morphAttribute.length) {
        array.push(morphAttribute[i].clone(data));
      }

      morphAttributes.set(name, array);
    }

    morphTargetsRelative = source.morphTargetsRelative;

    // groups

    var groups = source.groups;

    for (i in 0...groups.length) {
      var group = groups[i];
      addGroup(group.start, group.count, group.materialIndex);
    }

    // bounding box

    var boundingBox = source.boundingBox;

    if (boundingBox != null) {
      this.boundingBox = boundingBox.clone();
    }

    // bounding sphere

    var boundingSphere = source.boundingSphere;

    if (boundingSphere != null) {
      this.boundingSphere = boundingSphere.clone();
    }

    // draw range

    drawRange.start = source.drawRange.start;
    drawRange.count = source.drawRange.count;

    // user data

    userData = source.userData;

    return this;
  }

  public function dispose(): Void {
    dispatchEvent({ type: 'dispose' });
  }
}