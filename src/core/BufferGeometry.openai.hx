package three.bufferGeometry;

import three.math.Vector2;
import three.math.Vector3;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Sphere;
import three.math.Box3;
import three.core.Object3D;
import three.core.EventDispatcher;
import three.bufferAttribute.BufferAttribute;
import three.bufferAttribute.Float32BufferAttribute;
import three.bufferAttribute.Uint16BufferAttribute;
import three.bufferAttribute.Uint32BufferAttribute;
import three.math.MathUtils;

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
    public var groups:Array<{ start:Int, count:Int, materialIndex:Int }>;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;
    public var drawRange:{ start:Int, count:Int };
    public var userData:Dynamic;

    public function new() {
        super();

        isBufferGeometry = true;

        id = _id++;
        uuid = MathUtils.generateUUID();

        name = '';
        type = 'BufferGeometry';

        index = null;
        attributes = {};
        morphAttributes = {};
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
        return attributes[name];
    }

    public function setAttribute(name:String, attribute:BufferAttribute):BufferGeometry {
        attributes[name] = attribute;
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
        // ...
    }

    public function applyQuaternion(quaternion:Quaternion):BufferGeometry {
        // ...
    }

    public function rotateX(angle:Float):BufferGeometry {
        // ...
    }

    public function rotateY(angle:Float):BufferGeometry {
        // ...
    }

    public function rotateZ(angle:Float):BufferGeometry {
        // ...
    }

    public function translate(x:Float, y:Float, z:Float):BufferGeometry {
        // ...
    }

    public function scale(x:Float, y:Float, z:Float):BufferGeometry {
        // ...
    }

    public function lookAt(vector:Vector3):BufferGeometry {
        // ...
    }

    public function center():BufferGeometry {
        // ...
    }

    public function setFromPoints(points:Array<Vector3>):BufferGeometry {
        // ...
    }

    public function computeBoundingBox():Void {
        // ...
    }

    public function computeBoundingSphere():Void {
        // ...
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
        return new BufferGeometry().copy(this);
    }

    public function copy(source:BufferGeometry):BufferGeometry {
        // ...
    }

    public function dispose():Void {
        dispatchEvent({ type: 'dispose' });
    }
}