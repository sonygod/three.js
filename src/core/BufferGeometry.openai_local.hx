import three.math.Vector3;
import three.math.Vector2;
import three.math.Box3;
import three.core.EventDispatcher;
import three.core.BufferAttribute;
import three.core.Float32BufferAttribute;
import three.core.Uint16BufferAttribute;
import three.core.Uint32BufferAttribute;
import three.math.Sphere;
import three.core.Object3D;
import three.math.Matrix4;
import three.math.Matrix3;
import three.math.MathUtils;
import three.utils.arrayNeedsUint32;

class BufferGeometry extends EventDispatcher {

    static var _id:Int = 0;

    static var _m1:Matrix4 = new Matrix4();
    static var _obj:Object3D = new Object3D();
    static var _offset:Vector3 = new Vector3();
    static var _box:Box3 = new Box3();
    static var _boxMorphTargets:Box3 = new Box3();
    static var _vector:Vector3 = new Vector3();

    public var isBufferGeometry:Bool;
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
        this.isBufferGeometry = true;
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
        this.drawRange = { start: 0, count: Math.POSITIVE_INFINITY };
        this.userData = {};
    }

    public function getIndex():BufferAttribute {
        return this.index;
    }

    public function setIndex(index:Dynamic):BufferGeometry {
        if (Std.is(index, Array)) {
            this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
        } else {
            this.index = index;
        }
        return this;
    }

    public function getAttribute(name:String):BufferAttribute {
        return this.attributes.get(name);
    }

    public function setAttribute(name:String, attribute:BufferAttribute):BufferGeometry {
        this.attributes.set(name, attribute);
        return this;
    }

    public function deleteAttribute(name:String):BufferGeometry {
        this.attributes.remove(name);
        return this;
    }

    public function hasAttribute(name:String):Bool {
        return this.attributes.exists(name);
    }

    public function addGroup(start:Int, count:Int, materialIndex:Int = 0):Void {
        this.groups.push({ start: start, count: count, materialIndex: materialIndex });
    }

    public function clearGroups():Void {
        this.groups = [];
    }

    public function setDrawRange(start:Int, count:Int):Void {
        this.drawRange.start = start;
        this.drawRange.count = count;
    }

    public function applyMatrix4(matrix:Matrix4):BufferGeometry {
        var position = this.attributes.get("position");
        if (position != null) {
            position.applyMatrix4(matrix);
            position.needsUpdate = true;
        }
        var normal = this.attributes.get("normal");
        if (normal != null) {
            var normalMatrix = new Matrix3().getNormalMatrix(matrix);
            normal.applyNormalMatrix(normalMatrix);
            normal.needsUpdate = true;
        }
        var tangent = this.attributes.get("tangent");
        if (tangent != null) {
            tangent.transformDirection(matrix);
            tangent.needsUpdate = true;
        }
        if (this.boundingBox != null) {
            this.computeBoundingBox();
        }
        if (this.boundingSphere != null) {
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
        var position:Array<Float> = [];
        for (i in 0...points.length) {
            var point = points[i];
            position.push(point.x, point.y, point.z != null ? point.z : 0);
        }
        this.setAttribute('position', new Float32BufferAttribute(position, 3));
        return this;
    }

    public function computeBoundingBox():Void {
        if (this.boundingBox == null) {
            this.boundingBox = new Box3();
        }
        var position = this.attributes.get("position");
        var morphAttributesPosition = this.morphAttributes.get("position");
        if (position != null) {
            this.boundingBox.setFromBufferAttribute(position);
            if (morphAttributesPosition != null) {
                for (i in 0...morphAttributesPosition.length) {
                    var morphAttribute = morphAttributesPosition[i];
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
        if (Math.isNaN(this.boundingBox.min.x) || Math.isNaN(this.boundingBox.min.y) || Math.isNaN(this.boundingBox.min.z)) {
            trace('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
        }
    }

    public function computeBoundingSphere():Void {
        if (this.boundingSphere == null) {
            this.boundingSphere = new Sphere();
        }
        var position = this.attributes.get("position");
        var morphAttributesPosition = this.morphAttributes.get("position");
        if (position != null) {
            var center = this.boundingSphere.center;
            _box.setFromBufferAttribute(position);
            if (morphAttributesPosition != null) {
                for (i in 0...morphAttributesPosition.length) {
                    var morphAttribute = morphAttributesPosition[i];
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
            var maxRadiusSq:Float = 0;
            for (i in 0...position.count) {
                _vector.fromBufferAttribute(position, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
            }
            if (morphAttributesPosition != null) {
                for (i in 0...morphAttributesPosition.length) {
                    var morphAttribute = morphAttributesPosition[i];
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
            this.boundingSphere.radius = Math.sqrt(maxRadiusSq);
            if (Math.isNaN(this.boundingSphere.radius)) {
                trace('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
            }
        }
    }

    public function computeVertexNormals():Void {
        var index = this.index;
        var attributes = this.attributes;
        if (attributes.get("position") == null) {
            trace('THREE.BufferGeometry.computeVertexNormals(): Missing "position" attribute.');
            return;
        }
        var positions = attributes.get("position").array;
        if (attributes.get("normal") == null) {
            this.setAttribute('normal', new Float32BufferAttribute(positions.length, 3));
        } else {
            var array = attributes.get("normal").array;
            for (i in 0...array.length) {
                array[i] = 0;
            }
        }
        var normals = attributes.get("normal").array;
        var vA:Int, vB:Int, vC:Int;
        var pA:Vector3 = new Vector3(), pB:Vector3 = new Vector3(), pC:Vector3 = new Vector3();
        var cb:Vector3 = new Vector3(), ab:Vector3 = new Vector3();
        if (index != null) {
            var indices = index.array;
            for (i in 0...index.count step 3) {
                vA = indices[i + 0] * 3;
                vB = indices[i + 1] * 3;
                vC = indices[i + 2] * 3;
                pA.fromArray(positions, vA);
                pB.fromArray(positions, vB);
                pC.fromArray(positions, vC);
                cb.subVectors(pC, pB);
                ab.subVectors(pA, pB);
                cb.cross(ab);
                normals[vA] += cb.x;
                normals[vA + 1] += cb.y;
                normals[vA + 2] += cb.z;
                normals[vB] += cb.x;
                normals[vB + 1] += cb.y;
                normals[vB + 2] += cb.z;
                normals[vC] += cb.x;
                normals[vC + 1] += cb.y;
                normals[vC + 2] += cb.z;
            }
        } else {
            for (i in 0...positions.length step 9) {
                pA.fromArray(positions, i);
                pB.fromArray(positions, i + 3);
                pC.fromArray(positions, i + 6);
                cb.subVectors(pC, pB);
                ab.subVectors(pA, pB);
                cb.cross(ab);
                normals[i] += cb.x;
                normals[i + 1] += cb.y;
                normals[i + 2] += cb.z;
                normals[i + 3] += cb.x;
                normals[i + 4] += cb.y;
                normals[i + 5] += cb.z;
                normals[i + 6] += cb.x;
                normals[i + 7] += cb.y;
                normals[i + 8] += cb.z;
            }
        }
        this.normalizeNormals();
        attributes.get("normal").needsUpdate = true;
    }

    public function normalizeNormals():Void {
        var normals = this.attributes.get("normal").array;
        for (i in 0...normals.length step 3) {
            _vector.set(normals[i], normals[i + 1], normals[i + 2]);
            _vector.normalize();
            normals[i] = _vector.x;
            normals[i + 1] = _vector.y;
            normals[i + 2] = _vector.z;
        }
    }

    public function toNonIndexed():BufferGeometry {
        if (this.index == null) {
            trace('THREE.BufferGeometry.toNonIndexed(): Geometry is already non-indexed.');
            return this;
        }
        var geometry = new BufferGeometry();
        var indices = this.index.array;
        var attributes = this.attributes;
        for (name in attributes.keys()) {
            var attribute = attributes.get(name);
            var array = attribute.array;
            var itemSize = attribute.itemSize;
            var array2 = new Array<Float>();
            for (i in 0...indices.length) {
                var index = indices[i];
                for (j in 0...itemSize) {
                    array2.push(array[index * itemSize + j]);
                }
            }
            geometry.setAttribute(name, new Float32BufferAttribute(array2, itemSize));
        }
        var morphAttributes = this.morphAttributes;
        for (name in morphAttributes.keys()) {
            var morphArray = morphAttributes.get(name);
            var morphArray2 = new Array<BufferAttribute>();
            for (i in 0...morphArray.length) {
                var attribute = morphArray[i];
                var array = attribute.array;
                var itemSize = attribute.itemSize;
                var array2 = new Array<Float>();
                for (j in 0...indices.length) {
                    var index = indices[j];
                    for (k in 0...itemSize) {
                        array2.push(array[index * itemSize + k]);
                    }
                }
                morphArray2.push(new Float32BufferAttribute(array2, itemSize));
            }
            geometry.morphAttributes.set(name, morphArray2);
        }
        geometry.morphTargetsRelative = this.morphTargetsRelative;
        var groups = this.groups;
        for (i in 0...groups.length) {
            var group = groups[i];
            geometry.addGroup(group.start, group.count, group.materialIndex);
        }
        return geometry;
    }

    public function clone():BufferGeometry {
        return new BufferGeometry().copy(this);
    }

    public function copy(source:BufferGeometry):BufferGeometry {
        this.index = null;
        this.attributes = new Map();
        this.morphAttributes = new Map();
        this.groups = [];
        this.boundingBox = null;
        this.boundingSphere = null;
        this.drawRange = { start: 0, count: Math.POSITIVE_INFINITY };
        this.userData = JSON.parse(JSON.stringify(source.userData));
        var index = source.index;
        if (index != null) {
            this.setIndex(index.clone());
        }
        var attributes = source.attributes;
        for (name in attributes.keys()) {
            var attribute = attributes.get(name);
            this.setAttribute(name, attribute.clone());
        }
        var morphAttributes = source.morphAttributes;
        for (name in morphAttributes.keys()) {
            var array = morphAttributes.get(name);
            var array2 = new Array<BufferAttribute>();
            for (i in 0...array.length) {
                array2.push(array[i].clone());
            }
            this.morphAttributes.set(name, array2);
        }
        this.morphTargetsRelative = source.morphTargetsRelative;
        var groups = source.groups;
        for (i in 0...groups.length) {
            var group = groups[i];
            this.addGroup(group.start, group.count, group.materialIndex);
        }
        var boundingBox = source.boundingBox;
        if (boundingBox != null) {
            this.boundingBox = boundingBox.clone();
        }
        var boundingSphere = source.boundingSphere;
        if (boundingSphere != null) {
            this.boundingSphere = boundingSphere.clone();
        }
        this.drawRange = source.drawRange;
        return this;
    }

    public function dispose():Void {
        this.dispatchEvent({ type: 'dispose' });
    }
}