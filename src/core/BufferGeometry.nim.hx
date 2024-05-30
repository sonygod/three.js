import Vector3.Vector3;
import Vector2.Vector2;
import Box3.Box3;
import EventDispatcher.EventDispatcher;
import BufferAttribute.BufferAttribute;
import BufferAttribute.Float32BufferAttribute;
import BufferAttribute.Uint16BufferAttribute;
import BufferAttribute.Uint32BufferAttribute;
import Sphere.Sphere;
import Object3D.Object3D;
import Matrix4.Matrix4;
import Matrix3.Matrix3;
import MathUtils.MathUtils;
import utils.arrayNeedsUint32;

class BufferGeometry extends EventDispatcher {

    public var isBufferGeometry:Bool = true;
    public var id:Int;
    public var uuid:String;
    public var name:String;
    public var type:String;
    public var index:BufferAttribute;
    public var attributes:Map<String, BufferAttribute>;
    public var morphAttributes:Map<String, Array<BufferAttribute>>;
    public var morphTargetsRelative:Bool;
    public var groups:Array<Dynamic>;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;
    public var drawRange:Dynamic;
    public var userData:Dynamic;

    public function new() {
        super();

        this.id = _id++;
        this.uuid = MathUtils.generateUUID();
        this.name = '';
        this.type = 'BufferGeometry';
        this.index = null;
        this.attributes = new Map();
        this.morphAttributes = new Map();
        this.morphTargetsRelative = false;
        this.groups = [];
        this.boundingBox = null;
        this.boundingSphere = null;
        this.drawRange = { start: 0, count: Infinity };
        this.userData = new Map();
    }

    public function getIndex():BufferAttribute {
        return this.index;
    }

    public function setIndex(index:BufferAttribute):BufferGeometry {
        if (Type.getClass(index) == Array<Int>) {
            this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
        } else {
            this.index = index;
        }
        return this;
    }

    public function getAttribute(name:String):BufferAttribute {
        return this.attributes[name];
    }

    public function setAttribute(name:String, attribute:BufferAttribute):BufferGeometry {
        this.attributes[name] = attribute;
        return this;
    }

    public function deleteAttribute(name:String):BufferGeometry {
        delete this.attributes[name];
        return this;
    }

    public function hasAttribute(name:String):Bool {
        return this.attributes[name] !== null;
    }

    public function addGroup(start:Int, count:Int, materialIndex:Int = 0):Void {
        this.groups.push({
            start: start,
            count: count,
            materialIndex: materialIndex
        });
    }

    public function clearGroups():Void {
        this.groups = [];
    }

    public function setDrawRange(start:Int, count:Int):Void {
        this.drawRange.start = start;
        this.drawRange.count = count;
    }

    public function applyMatrix4(matrix:Matrix4):BufferGeometry {
        const position = this.attributes.position;
        if (position !== null) {
            position.applyMatrix4(matrix);
            position.needsUpdate = true;
        }
        const normal = this.attributes.normal;
        if (normal !== null) {
            const normalMatrix = new Matrix3().getNormalMatrix(matrix);
            normal.applyNormalMatrix(normalMatrix);
            normal.needsUpdate = true;
        }
        const tangent = this.attributes.tangent;
        if (tangent !== null) {
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

    public function applyQuaternion(q:Quaternion):BufferGeometry {
        _m1.makeRotationFromQuaternion(q);
        this.applyMatrix4(_m1);
        return this;
    }

    public function rotateX(angle:Float):BufferGeometry {
        _m1.makeRotationX(angle);
        this.applyMatrix4(_m1);
        return this;
    }

    public function rotateY(angle:Float):BufferGeometry {
        _m1.makeRotationY(angle);
        this.applyMatrix4(_m1);
        return this;
    }

    public function rotateZ(angle:Float):BufferGeometry {
        _m1.makeRotationZ(angle);
        this.applyMatrix4(_m1);
        return this;
    }

    public function translate(x:Float, y:Float, z:Float):BufferGeometry {
        _m1.makeTranslation(x, y, z);
        this.applyMatrix4(_m1);
        return this;
    }

    public function scale(x:Float, y:Float, z:Float):BufferGeometry {
        _m1.makeScale(x, y, z);
        this.applyMatrix4(_m1);
        return this;
    }

    public function lookAt(vector:Vector3):BufferGeometry {
        _obj.lookAt(vector);
        _obj.updateMatrix();
        this.applyMatrix4(_obj.matrix);
        return this;
    }

    public function center():BufferGeometry {
        this.computeBoundingBox();
        this.boundingBox.getCenter(_offset).negate();
        this.translate(_offset.x, _offset.y, _offset.z);
        return this;
    }

    public function setFromPoints(points:Array<Vector3>):BufferGeometry {
        const position = [];
        for (i in 0...points.length) {
            const point = points[i];
            position.push(point.x, point.y, point.z || 0);
        }
        this.setAttribute('position', new Float32BufferAttribute(position, 3));
        return this;
    }

    public function computeBoundingBox():Void {
        if (this.boundingBox === null) {
            this.boundingBox = new Box3();
        }
        const position = this.attributes.position;
        const morphAttributesPosition = this.morphAttributes.position;
        if (position && position.isGLBufferAttribute) {
            console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
            this.boundingBox.set(
                new Vector3(- Infinity, - Infinity, - Infinity),
                new Vector3(+ Infinity, + Infinity, + Infinity)
            );
            return;
        }
        if (position !== null) {
            this.boundingBox.setFromBufferAttribute(position);
            if (morphAttributesPosition) {
                for (i in 0...morphAttributesPosition.length) {
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

    public function computeBoundingSphere():Void {
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
            const center = this.boundingSphere.center;
            _box.setFromBufferAttribute(position);
            if (morphAttributesPosition) {
                for (i in 0...morphAttributesPosition.length) {
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
            let maxRadiusSq = 0;
            for (i in 0...position.count) {
                _vector.fromBufferAttribute(position, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
            }
            if (morphAttributesPosition) {
                for (i in 0...morphAttributesPosition.length) {
                    const morphAttribute = morphAttributesPosition[i];
                    const morphTargetsRelative = this.morphTargetsRelative;
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
            this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
            if (isNaN(this.boundingSphere.radius)) {
                console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
            }
        }
    }

    public function computeTangents():Void {
        const index = this.index;
        const attributes = this.attributes;
        if (index === null ||
            attributes.position === null ||
            attributes.normal === null ||
            attributes.uv === null) {
            console.error('THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)');
            return;
        }
        const positionAttribute = attributes.position;
        const normalAttribute = attributes.normal;
        const uvAttribute = attributes.uv;
        if (this.hasAttribute('tangent') === false) {
            this.setAttribute('tangent', new BufferAttribute(new Float32Array(positionAttribute.count * 4), 4));
        }
        const tangentAttribute = this.getAttribute('tangent');
        const tan1 = [], tan2 = [];
        for (i in 0...positionAttribute.count) {
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
        function handleTriangle(a:Int, b:Int, c:Int) {
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
            sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, - uvB.y).multiplyScalar(r);
            tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, - uvC.x).multiplyScalar(r);
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
        for (i in 0...groups.length) {
            const group = groups[i];
            const start = group.start;
            const count = group.count;
            for (j in start...start + count) {
                handleTriangle(
                    index.getX(j + 0),
                    index.getX(j + 1),
                    index.getX(j + 2)
                );
            }
        }
        const tmp = new Vector3(), tmp2 = new Vector3();
        const n = new Vector3(), n2 = new Vector3();
        function handleVertex(v:Int) {
            n.fromBufferAttribute(normalAttribute, v);
            n2.copy(n);
            const t = tan1[v];
            tmp.copy(t);
            tmp.sub(n.multiplyScalar(n.dot(t))).normalize();
            tmp2.crossVectors(n2, t);
            const test = tmp2.dot(tan2[v]);
            const w = (test < 0.0) ? - 1.0 : 1.0;
            tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
        }
        for (i in 0...groups.length) {
            const group = groups[i];
            const start = group.start;
            const count = group.count;
            for (j in start...start + count) {
                handleVertex(index.getX(j + 0));
                handleVertex(index.getX(j + 1));
                handleVertex(index.getX(j + 2));
            }
        }
    }

    public function computeVertexNormals():Void {
        const index = this.index;
        const positionAttribute = this.getAttribute('position');
        if (positionAttribute !== null) {
            let normalAttribute = this.getAttribute('normal');
            if (normalAttribute === null) {
                normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
                this.setAttribute('normal', normalAttribute);
            } else {
                for (i in 0...normalAttribute.count) {
                    normalAttribute.setXYZ(i, 0, 0, 0);
                }
            }
            const pA = new Vector3(), pB = new Vector3(), pC = new Vector3();
            const nA = new Vector3(), nB = new Vector3(), nC = new Vector3();
            const cb = new Vector3(), ab = new Vector3();
            if (index !== null) {
                for (i in 0...index.count) {
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
                for (i in 0...positionAttribute.count) {
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

    public function normalizeNormals():Void {
        const normals = this.attributes.normal;
        for (i in 0...normals.count) {
            _vector.fromBufferAttribute(normals, i);
            _vector.normalize();
            normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
    }

    public function toNonIndexed():BufferGeometry {
        function convertBufferAttribute(attribute:BufferAttribute, indices:Array<Int>):BufferAttribute {
            const array = attribute.array;
            const itemSize = attribute.itemSize;
            const normalized = attribute.normalized;
            const array2 = new array.constructor(indices.length * itemSize);
            let index = 0, index2 = 0;
            for (i in 0...indices.length) {
                if (attribute.isInterleavedBufferAttribute) {
                    index = indices[i] * attribute.data.stride + attribute.offset;
                } else {
                    index = indices[i] * itemSize;
                }
                for (j in 0...itemSize) {
                    array2[index2++] = array[index++];
                }
            }
            return new BufferAttribute(array2, itemSize, normalized);
        }
        if (this.index === null) {
            console.warn('THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.');
            return this;
        }
        const geometry2 = new BufferGeometry();
        const indices = this.index.array;
        const attributes = this.attributes;
        for (name in attributes) {
            const attribute = attributes[name];
            const newAttribute = convertBufferAttribute(attribute, indices);
            geometry2.setAttribute(name, newAttribute);
        }
        const morphAttributes = this.morphAttributes;
        for (name in morphAttributes) {
            const morphArray = [];
            const morphAttribute = morphAttributes[name];
            for (i in 0...morphAttribute.length) {
                const attribute = morphAttribute[i];
                const newAttribute = convertBufferAttribute(attribute, indices);
                morphArray.push(newAttribute);
            }
            geometry2.morphAttributes[name] = morphArray;
        }
        geometry2.morphTargetsRelative = this.morphTargetsRelative;
        const groups = this.groups;
        for (i in 0...groups.length) {
            const group = groups[i];
            geometry2.addGroup(group.start, group.count, group.materialIndex);
        }
        return geometry2;
    }

    public function toJSON():Dynamic {
        const data = {
            metadata: {
                version: 4.6,
                type: 'BufferGeometry',
                generator: 'BufferGeometry.toJSON'
            }
        };
        data.uuid = this.uuid;
        data.type = this.type;
        if (this.name !== '') data.name = this.name;
        if (Object.keys(this.userData).length > 0) data.userData = this.userData;
        if (this.parameters !== null) {
            const parameters = this.parameters;
            for (key in parameters) {
                if (parameters[key] !== null) data[key] = parameters[key];
            }
            return data;
        }
        data.data = { attributes: {} };
        const index = this.index;
        if (index !== null) {
            data.data.index = {
                type: index.array.constructor.name,
                array: Array.prototype.slice.call(index.array)
            };
        }
        const attributes = this.attributes;
        for (name in attributes) {
            const attribute = attributes[name];
            data.data.attributes[name] = attribute.toJSON(data.data);
        }
        const morphAttributes = {};
        let hasMorphAttributes = false;
        for (name in this.morphAttributes) {
            const attributeArray = this.morphAttributes[name];
            const array = [];
            for (i in 0...attributeArray.length) {
                const attribute = attributeArray[i];
                array.push(attribute.toJSON(data.data));
            }
            if (array.length > 0) {
                morphAttributes[name] = array;
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

    public function clone():BufferGeometry {
        return new this.constructor().copy(this);
    }

    public function copy(source:BufferGeometry):BufferGeometry {
        this.index = null;
        this.attributes = new Map();
        this.morphAttributes = new Map();
        this.groups = [];
        this.boundingBox = null;
        this.boundingSphere = null;
        this.drawRange = { start: 0, count: Infinity };
        this.userData = new Map();
        this.name = source.name;
        const index = source.index;
        if (index !== null) {
            this.setIndex(index.clone(data));
        }
        const attributes = source.attributes;
        for (name in attributes) {
            const attribute = attributes[name];
            this.setAttribute(name, attribute.clone(data));
        }
        const morphAttributes = source.morphAttributes;
        for (name in morphAttributes) {
            const array = [];
            const morphAttribute = morphAttributes[name];
            for (i in 0...morphAttribute.length) {
                array.push(morphAttribute[i].clone(data));
            }
            this.morphAttributes[name] = array;
        }
        this.morphTargetsRelative = source.morphTargetsRelative;
        const groups = source.groups;
        for (i in 0...groups.length) {
            const group = groups[i];
            this.addGroup(group.start, group.count, group.materialIndex);
        }
        const boundingBox = source.boundingBox;
        if (boundingBox !== null) {
            this.boundingBox = boundingBox.clone();
        }
        const boundingSphere = source.boundingSphere;
        if (boundingSphere !== null) {
            this.boundingSphere = boundingSphere.clone();
        }
        this.drawRange.start = source.drawRange.start;
        this.drawRange.count = source.drawRange.count;
        this.userData = source.userData;
        return this;
    }

    public function dispose():Void {
        this.dispatchEvent({ type: 'dispose' });
    }

}