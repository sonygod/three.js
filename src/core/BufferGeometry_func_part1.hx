package three.core;

import three.math.Vector3;
import three.math.Vector2;
import three.math.Box3;
import three.events.EventDispatcher;
import three.bufferAttribute.BufferAttribute;
import three.bufferAttribute.Float32BufferAttribute;
import three.bufferAttribute.Uint16BufferAttribute;
import three.bufferAttribute.Uint32BufferAttribute;
import three.math.Sphere;
import three.object3D.Object3D;
import three.math.Matrix4;
import three.math.Matrix3;
import three.math.MathUtils;
import three.utils.Utils;

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
    public var groups:Array<{ start:Int, count:Int, materialIndex:Int }>;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;
    public var drawRange:{ start:Int, count:Int };
    public var userData:Dynamic;

    public function new() {
        super();
        id = _id++;
        uuid = MathUtils.generateUUID();
        name = '';
        type = 'BufferGeometry';
        index = null;
        attributes = new Map<String, BufferAttribute>();
        morphAttributes = new Map<String, Array<BufferAttribute>>();
        morphTargetsRelative = false;
        groups = [];
        boundingBox = null;
        boundingSphere = null;
        drawRange = { start: 0, count: Math.POSITIVE_INFINITY };
        userData = {};
    }

    public function getIndex():BufferAttribute {
        return index;
    }

    public function setIndex(index:BufferAttribute):BufferGeometry {
        this.index = index;
        return this;
    }

    public function getAttribute(name:String):BufferAttribute {
        return attributes.get(name);
    }

    public function setAttribute(name:String, attribute:BufferAttribute):BufferGeometry {
        attributes.set(name, attribute);
        return this;
    }

    public function deleteAttribute(name:String):BufferGeometry {
        attributes.remove(name);
        return this;
    }

    public function hasAttribute(name:String):Bool {
        return attributes.exists(name);
    }

    public function addGroup(start:Int, count:Int, materialIndex:Int = 0):Void {
        groups.push({ start: start, count: count, materialIndex: materialIndex });
    }

    public function clearGroups():Void {
        groups = [];
    }

    public function setDrawRange(start:Int, count:Int):Void {
        drawRange.start = start;
        drawRange.count = count;
    }

    public function applyMatrix4(matrix:Matrix4):BufferGeometry {
        var position:BufferAttribute = attributes.get('position');
        if (position != null) {
            position.applyMatrix4(matrix);
            position.needsUpdate = true;
        }
        var normal:BufferAttribute = attributes.get('normal');
        if (normal != null) {
            var normalMatrix:Matrix3 = new Matrix3().getNormalMatrix(matrix);
            normal.applyNormalMatrix(normalMatrix);
            normal.needsUpdate = true;
        }
        var tangent:BufferAttribute = attributes.get('tangent');
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

    public function applyQuaternion(q:Quaternion):BufferGeometry {
        var matrix:Matrix4 = new Matrix4().makeRotationFromQuaternion(q);
        applyMatrix4(matrix);
        return this;
    }

    public function rotateX(angle:Float):BufferGeometry {
        var matrix:Matrix4 = new Matrix4().makeRotationX(angle);
        applyMatrix4(matrix);
        return this;
    }

    public function rotateY(angle:Float):BufferGeometry {
        var matrix:Matrix4 = new Matrix4().makeRotationY(angle);
        applyMatrix4(matrix);
        return this;
    }

    public function rotateZ(angle:Float):BufferGeometry {
        var matrix:Matrix4 = new Matrix4().makeRotationZ(angle);
        applyMatrix4(matrix);
        return this;
    }

    public function translate(x:Float, y:Float, z:Float):BufferGeometry {
        var matrix:Matrix4 = new Matrix4().makeTranslation(x, y, z);
        applyMatrix4(matrix);
        return this;
    }

    public function scale(x:Float, y:Float, z:Float):BufferGeometry {
        var matrix:Matrix4 = new Matrix4().makeScale(x, y, z);
        applyMatrix4(matrix);
        return this;
    }

    public function lookAt(vector:Vector3):BufferGeometry {
        var obj:Object3D = new Object3D();
        obj.lookAt(vector);
        obj.updateMatrix();
        applyMatrix4(obj.matrix);
        return this;
    }

    public function center():BufferGeometry {
        computeBoundingBox();
        boundingBox.getCenter(_offset).negate();
        translate(_offset.x, _offset.y, _offset.z);
        return this;
    }

    public function setFromPoints(points:Array<Vector3>):BufferGeometry {
        var position:Array<Float> = [];
        for (i in 0...points.length) {
            var point:Vector3 = points[i];
            position.push(point.x, point.y, point.z);
        }
        setAttribute('position', new Float32BufferAttribute(position, 3));
        return this;
    }

    public function computeBoundingBox():Void {
        if (boundingBox == null) {
            boundingBox = new Box3();
        }
        var position:BufferAttribute = attributes.get('position');
        var morphAttributesPosition:Array<BufferAttribute> = morphAttributes.get('position');
        if (position != null && position.isGLBufferAttribute) {
            console.error('THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.', this);
            boundingBox.set(new Vector3(-Math.POSITIVE_INFINITY, -Math.POSITIVE_INFINITY, -Math.POSITIVE_INFINITY), new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY));
            return;
        }
        if (position != null) {
            boundingBox.setFromBufferAttribute(position);
            if (morphAttributesPosition != null) {
                for (i in 0...morphAttributesPosition.length) {
                    var morphAttribute:BufferAttribute = morphAttributesPosition[i];
                    _box.setFromBufferAttribute(morphAttribute);
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
        if (Math.isNaN(boundingBox.min.x) || Math.isNaN(boundingBox.min.y) || Math.isNaN(boundingBox.min.z)) {
            console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.', this);
        }
    }

    public function computeBoundingSphere():Void {
        if (boundingSphere == null) {
            boundingSphere = new Sphere();
        }
        var position:BufferAttribute = attributes.get('position');
        var morphAttributesPosition:Array<BufferAttribute> = morphAttributes.get('position');
        if (position != null && position.isGLBufferAttribute) {
            console.error('THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.', this);
            boundingSphere.set(new Vector3(), Math.POSITIVE_INFINITY);
            return;
        }
        if (position != null) {
            var center:Vector3 = boundingSphere.center;
            _box.setFromBufferAttribute(position);
            if (morphAttributesPosition != null) {
                for (i in 0...morphAttributesPosition.length) {
                    var morphAttribute:BufferAttribute = morphAttributesPosition[i];
                    _boxMorphTargets.setFromBufferAttribute(morphAttribute);
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
            var maxRadiusSq:Float = 0;
            for (i in 0...position.count) {
                _vector.fromBufferAttribute(position, i);
                maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
            }
            if (morphAttributesPosition != null) {
                for (i in 0...morphAttributesPosition.length) {
                    var morphAttribute:BufferAttribute = morphAttributesPosition[i];
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
            if (Math.isNaN(boundingSphere.radius)) {
                console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.', this);
            }
        }
    }
}

var _id:Int = 0;
var _m1:Matrix4 = new Matrix4();
var _obj:Object3D = new Object3D();
var _offset:Vector3 = new Vector3();
var _box:Box3 = new Box3();
var _boxMorphTargets:Box3 = new Box3();
var _vector:Vector3 = new Vector3();