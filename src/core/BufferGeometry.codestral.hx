import js.html.Math;
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
import three.utils.ArrayUtils;

class BufferGeometry extends EventDispatcher {
    public var isBufferGeometry:Bool = true;
    public var id:Int;
    public var uuid:String;
    public var name:String;
    public var type:String;
    public var index:BufferAttribute;
    public var attributes:haxe.ds.StringMap<BufferAttribute>;
    public var morphAttributes:haxe.ds.StringMap<Array<BufferAttribute>>;
    public var morphTargetsRelative:Bool;
    public var groups:Array<Dynamic>;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;
    public var drawRange:Dynamic;
    public var userData:Dynamic;

    static private var _id:Int = 0;
    static private var _m1:Matrix4 = new Matrix4();
    static private var _obj:Object3D = new Object3D();
    static private var _offset:Vector3 = new Vector3();
    static private var _box:Box3 = new Box3();
    static private var _boxMorphTargets:Box3 = new Box3();
    static private var _vector:Vector3 = new Vector3();

    public function new() {
        super();

        this.id = _id++;
        this.uuid = MathUtils.generateUUID();
        this.name = '';
        this.type = 'BufferGeometry';
        this.index = null;
        this.attributes = new haxe.ds.StringMap<BufferAttribute>();
        this.morphAttributes = new haxe.ds.StringMap<Array<BufferAttribute>>();
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

    public function setIndex(index:Array<Int>):BufferGeometry {
        if (index is Array) {
            this.index = new (ArrayUtils.arrayNeedsUint32(index) ? Uint32BufferAttribute : Uint16BufferAttribute)(index, 1);
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

    // Implement the rest of the methods in the same way.
    // Note that you will need to import the necessary classes and functions from the three.js library.
}