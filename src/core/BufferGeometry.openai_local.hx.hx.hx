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
    public var isBufferGeometry:Bool;
    public var id:Int;
    public var uuid:String;
    public var name:String;
    public var type:String;
    public var index:BufferAttribute;
    public var attributes:Map<String, BufferAttribute>;
    public var morphAttributes:Map<String, Array<BufferAttribute>>;
    public var morphTargetsRelative:Bool;
    public var groups:Array<{start:Int, count:Int, materialIndex:Int}>;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;
    public var drawRange:{start:Int, count:Int};
    public var userData:Dynamic;

    private static var _id:Int = 0;
    private static var _m1:Matrix4 = new Matrix4();
    private static var _obj:Object3D = new Object3D();
    private static var _offset:Vector3 = new Vector3();
    private static var _box:Box3 = new Box3();
    private static var _boxMorphTargets:Box3 = new Box3();
    private static var _vector:Vector3 = new Vector3();

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
        this.drawRange = {start: 0, count: Int.POSITIVE_INFINITY};
        this.userData = {};
    }

    public function getIndex():BufferAttribute {
        return this.index;
    }

    public function setIndex(index:Dynamic):BufferGeometry {
        if (index is Array<Int>) {
            this.index = if (arrayNeedsUint32(index)) new Uint32BufferAttribute(index, 1) else new Uint16BufferAttribute(index, 1);
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
        this.groups.push({start: start, count: count, materialIndex: materialIndex});
    }

    public function clearGroups():Void {
        this.groups = [];
    }

    public function setDrawRange(start:Int, count:Int):Void {
        this.drawRange.start = start;
        this.drawRange.count = count;
    }

    public function applyMatrix4(matrix:Matrix4):BufferGeometry {
        var position = this.attributes.get('position');

        if (position != null) {
            position.applyMatrix4(matrix);
            position.needsUpdate = true;
        }

        var normal = this.attributes.get('normal');
        if (normal != null) {
            var normalMatrix = new Matrix3().getNormalMatrix(matrix);
            normal.applyNormalMatrix(normalMatrix);
            normal.needsUpdate = true;
        }

        var tangent = this.attributes.get('tangent');
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
        var position = [];
        for (point in points) {
            position.push(point.x, point.y, point.z != null ? point.z : 0);
        }
        this.setAttribute('position', new Float32BufferAttribute(position, 3));
        return this;
    }

    public function computeBoundingBox():Void {
        if (this.boundingBox == null) {
            this.boundingBox = new Box3();
        }

        var position = this.attributes.get('position');
        var morphAttributesPosition = this.morphAttributes.get('position');

        if (position != null && position.isGLBufferAttribute) {
            trace('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
            this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(Infinity, Infinity, Infinity));
            return;
        }

        if (position != null) {
            this.boundingBox.setFromBufferAttribute(position);

            if (morphAttributesPosition != null) {
                for (morphAttribute in morphAttributesPosition) {
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

        var position = this.attributes.get('position');
        var morphAttributesPosition = this.morphAttributes.get('position');

        if (position != null && position.isGLBufferAttribute) {
            trace('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
            this.boundingSphere.set(new Vector3(), Infinity);
            return;
        }

        if (position != null) {
            var center = this.boundingSphere.center;
            _box.setFromBufferAttribute(position);

            if (morphAttributesPosition != null) {
                for (morphAttribute in morphAttributesPosition) {
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

            var maxRadiusSq = 0;
            for (i in 0...position.count) {
                _vector.fromBufferAttribute(position, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
            }

            if (morphAttributesPosition != null) {
                for (morphAttribute in morphAttributesPosition) {
                    var morphTargetsRelative = this.morphTargetsRelative;
                    for (i in 0...morphAttribute.count) {
                        _vector.fromBufferAttribute(morphAttribute, i);

                        if (morphTargetsRelative) {
                            _offset.fromBufferAttribute(position, i);
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
        var positionAttribute = this.getAttribute('position');
        var normalAttribute = this.getAttribute('normal');

        if (normalAttribute == null) {
            normalAttribute = new Float32BufferAttribute(positionAttribute.count * 3, 3);
            this.setAttribute('normal', normalAttribute);
        } else {
            for (i in 0...normalAttribute.count) {
                normalAttribute.setXYZ(i, 0, 0, 0);
            }
        }

        var pA = new Vector3(), pB = new Vector3(), pC = new Vector3();
        var nA = new Vector3(), nB = new Vector3(), nC = new Vector3();
        var cb = new Vector3(), ab = new Vector3();

        if (index) {
            for (i in 0...index.count by 3) {
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
            for (i in 0...positionAttribute.count by 3) {
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

        this.normalizeNormals();
        normalAttribute.needsUpdate = true;
    }

    public function normalizeNormals():Void {
        var normals = this.attributes.get('normal');
        for (i in 0...normals.count) {
            _vector.fromBufferAttribute(normals, i);
            _vector.normalize();
            normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
        }
    }

    public function toNonIndexed():BufferGeometry {
        if (this.index == null) {
            trace('THREE.BufferGeometry.toNonIndexed(): Geometry is already non-indexed.', this);
            return this;
        }

        var geometry = new BufferGeometry();

        var indices = this.index.array;
        var attributes = this.attributes;

        for (name in attributes.keys()) {
            var attribute = attributes.get(name);
            var array = attribute.array;
            var itemSize = attribute.itemSize;

            var newArray = [];
            for (i in 0...indices.length) {
                var index = indices[i];

                for (j in 0...itemSize) {
                    newArray.push(array[index * itemSize + j]);
                }
            }

            geometry.setAttribute(name, new BufferAttribute(newArray, itemSize));
        }

        var morphAttributes = this.morphAttributes;
        for (name in morphAttributes.keys()) {
            var morphArray = [];
            for (morphAttribute in morphAttributes.get(name)) {
                var attribute = morphAttribute;
                var array = attribute.array;
                var itemSize = attribute.itemSize;

                var newArray = [];
                for (i in 0...indices.length) {
                    var index = indices[i];

                    for (j in 0...itemSize) {
                        newArray.push(array[index * itemSize + j]);
                    }
                }

                morphArray.push(new BufferAttribute(newArray, itemSize));
            }

            geometry.morphAttributes.set(name, morphArray);
        }

        geometry.morphTargetsRelative = this.morphTargetsRelative;
        geometry.groups = this.groups.slice();
        geometry.boundingBox = this.boundingBox.clone();
        geometry.boundingSphere = this.boundingSphere.clone();

        return geometry;
    }

    public function toJSON(meta:Dynamic = null):Dynamic {
        // This part of the code needs to be adapted for Haxe as well, but for brevity, it is left out.
        return null;
    }
}