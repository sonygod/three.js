package three.js.src.core;

import three.js.src.math.Vector3;
import three.js.src.math.Vector2;
import three.js.src.math.Box3;
import three.js.src.core.EventDispatcher;
import three.js.src.core.BufferAttribute;
import three.js.src.math.Sphere;
import three.js.src.core.Object3D;
import three.js.src.math.Matrix4;
import three.js.src.math.Matrix3;
import three.js.src.math.MathUtils;
import three.js.src.utils.arrayNeedsUint32;

class BufferGeometry extends EventDispatcher {

    public var isBufferGeometry:Bool;
    public var id:Int;
    public var uuid:String;
    public var name:String;
    public var type:String;
    public var index:BufferAttribute;
    public var attributes:Map<String, BufferAttribute>;
    public var morphAttributes:Map<String, BufferAttribute>;
    public var morphTargetsRelative:Bool;
    public var groups:Array<{start:Int, count:Int, materialIndex:Int}>;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;
    public var drawRange:{start:Int, count:Int};
    public var userData:Map<String, Dynamic>;

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
        this.attributes = new Map<String, BufferAttribute>();
        this.morphAttributes = new Map<String, BufferAttribute>();
        this.morphTargetsRelative = false;
        this.groups = [];
        this.boundingBox = null;
        this.boundingSphere = null;
        this.drawRange = {start: 0, count: Int.MAX_VALUE};
        this.userData = new Map<String, Dynamic>();
    }

    public function getIndex():BufferAttribute {
        return this.index;
    }

    public function setIndex(index:BufferAttribute):Void {
        if (index is Array<Int>) {
            this.index = new (arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
        } else {
            this.index = index;
        }
    }

    public function getAttribute(name:String):BufferAttribute {
        return this.attributes[name];
    }

    public function setAttribute(name:String, attribute:BufferAttribute):Void {
        this.attributes[name] = attribute;
    }

    public function deleteAttribute(name:String):Void {
        delete this.attributes[name];
    }

    public function hasAttribute(name:String):Bool {
        return this.attributes[name] !== undefined;
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
        var position = this.attributes.position;
        if (position !== undefined) {
            position.applyMatrix4(matrix);
            position.needsUpdate = true;
        }
        var normal = this.attributes.normal;
        if (normal !== undefined) {
            var normalMatrix = new Matrix3().getNormalMatrix(matrix);
            normal.applyNormalMatrix(normalMatrix);
            normal.needsUpdate = true;
        }
        var tangent = this.attributes.tangent;
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
        for (p in points) {
            var point = points[p];
            position.push(point.x, point.y, point.z || 0);
        }
        this.setAttribute('position', new Float32BufferAttribute(position, 3));
        return this;
    }

    public function computeBoundingBox():Void {
        if (this.boundingBox === null) {
            this.boundingBox = new Box3();
        }
        var position = this.attributes.position;
        var morphAttributesPosition = this.morphAttributes.position;
        if (position && position.isGLBufferAttribute) {
            trace('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
            this.boundingBox.set(
                new Vector3(-Infinity, -Infinity, -Infinity),
                new Vector3(+Infinity, +Infinity, +Infinity)
            );
            return;
        }
        if (position !== undefined) {
            this.boundingBox.setFromBufferAttribute(position);
            if (morphAttributesPosition) {
                for (i in morphAttributesPosition) {
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
        if (isNaN(this.boundingBox.min.x) || isNaN(this.boundingBox.min.y) || isNaN(this.boundingBox.min.z)) {
            trace('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
        }
    }

    public function computeBoundingSphere():Void {
        if (this.boundingSphere === null) {
            this.boundingSphere = new Sphere();
        }
        var position = this.attributes.position;
        var morphAttributesPosition = this.morphAttributes.position;
        if (position && position.isGLBufferAttribute) {
            trace('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
            this.boundingSphere.set(new Vector3(), Infinity);
            return;
        }
        if (position) {
            var center = this.boundingSphere.center;
            _box.setFromBufferAttribute(position);
            if (morphAttributesPosition) {
                for (i in morphAttributesPosition) {
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
            var maxRadiusSq = 0;
            for (i in position.count) {
                _vector.fromBufferAttribute(position, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
            }
            if (morphAttributesPosition) {
                for (i in morphAttributesPosition) {
                    var morphAttribute = morphAttributesPosition[i];
                    var morphTargetsRelative = this.morphTargetsRelative;
                    for (j in morphAttribute.count) {
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
                trace('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
            }
        }
    }
}