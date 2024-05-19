import three.math.Vector3;
import three.math.Vector2;
import three.math.Box3;
import three.core.EventDispatcher;
import three.core.BufferAttribute;
import three.math.Sphere;
import three.core.Object3D;
import three.math.Matrix4;
import three.math.Matrix3;
import three.math.MathUtils;
import three.utils.arrayNeedsUint32;

@:keep
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
        this.id = BufferGeometry._id++;
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
        this.drawRange = {start: 0, count: Int.MAX_VALUE};
        this.userData = new Map();
    }

    public function getIndex():BufferAttribute {
        return this.index;
    }

    public function setIndex(index:Dynamic):BufferGeometry {
        if (Std.is(index, Array)) {
            this.index = arrayNeedsUint32(index) ? new Uint32BufferAttribute(index, 1) : new Uint16BufferAttribute(index, 1);
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

    public function deleteAttribute(name:String):Bool {
        return this.attributes.remove(name);
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
        BufferGeometry._m1.makeRotationFromQuaternion(q);
        this.applyMatrix4(BufferGeometry._m1);
        return this;
    }

    public function rotateX(angle:Float):BufferGeometry {
        BufferGeometry._m1.makeRotationX(angle);
        this.applyMatrix4(BufferGeometry._m1);
        return this;
    }

    public function rotateY(angle:Float):BufferGeometry {
        BufferGeometry._m1.makeRotationY(angle);
        this.applyMatrix4(BufferGeometry._m1);
        return this;
    }

    public function rotateZ(angle:Float):BufferGeometry {
        BufferGeometry._m1.makeRotationZ(angle);
        this.applyMatrix4(BufferGeometry._m1);
        return this;
    }

    public function translate(x:Float, y:Float, z:Float):BufferGeometry {
        BufferGeometry._m1.makeTranslation(x, y, z);
        this.applyMatrix4(BufferGeometry._m1);
        return this;
    }

    public function scale(x:Float, y:Float, z:Float):BufferGeometry {
        BufferGeometry._m1.makeScale(x, y, z);
        this.applyMatrix4(BufferGeometry._m1);
        return this;
    }

    public function lookAt(vector:Vector3):BufferGeometry {
        BufferGeometry._obj.lookAt(vector);
        BufferGeometry._obj.updateMatrix();
        this.applyMatrix4(BufferGeometry._obj.matrix);
        return this;
    }

    public function center():BufferGeometry {
        this.computeBoundingBox();
        this.boundingBox.getCenter(BufferGeometry._offset).negate();
        this.translate(BufferGeometry._offset.x, BufferGeometry._offset.y, BufferGeometry._offset.z);
        return this;
    }

    public function setFromPoints(points:Array<{x:Float, y:Float, z:Float}>):BufferGeometry {
        var position = [];
        for (p in points) {
            var point = points[p];
            position.push(point.x, point.y, point.z || 0);
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
            this.boundingBox.set(new Vector3(-Infinity, -Infinity, -Infinity), new Vector3(+Infinity, +Infinity, +Infinity));
            return;
        }
        if (position != null) {
            this.boundingBox.setFromBufferAttribute(position);
            if (morphAttributesPosition != null) {
                for (m in morphAttributesPosition) {
                    var morphAttribute = morphAttributesPosition[m];
                    BufferGeometry._box.setFromBufferAttribute(morphAttribute);
                    if (this.morphTargetsRelative) {
                        BufferGeometry._vector.addVectors(this.boundingBox.min, BufferGeometry._box.min);
                        this.boundingBox.expandByPoint(BufferGeometry._vector);
                        BufferGeometry._vector.addVectors(this.boundingBox.max, BufferGeometry._box.max);
                        this.boundingBox.expandByPoint(BufferGeometry._vector);
                    } else {
                        this.boundingBox.expandByPoint(BufferGeometry._box.min);
                        this.boundingBox.expandByPoint(BufferGeometry._box.max);
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
            this.boundingSphere.setFromBufferAttribute(position);
            if (morphAttributesPosition != null) {
                for (m in morphAttributesPosition) {
                    var morphAttribute = morphAttributesPosition[m];
                    for (i in morphAttribute) {
                        var morphTargetsRelative = this.morphTargetsRelative;
                        BufferGeometry._offset.fromBufferAttribute(position, i);
                        BufferGeometry._vector.fromBufferAttribute(morphAttribute, i);
                        if (morphTargetsRelative) {
                            BufferGeometry._vector.add(BufferGeometry._offset);
                        }
                        this.boundingSphere.expandByPoint(BufferGeometry._vector);
                    }
                }
            }
        }
    }

    public function computeTangents():Void {
        // ...
    }

    public function computeVertexNormals():Void {
        // ...
    }

    public function normalizeNormals():Void {
        // ...
    }

    public function toNonIndexed():BufferGeometry {
        // ...
    }

    public function toJSON():Dynamic {
        // ...
    }

    public function clone():BufferGeometry {
        // ...
    }

    public function copy(source:BufferGeometry):BufferGeometry {
        // ...
    }

    public function dispose():Void {
        // ...
    }
}