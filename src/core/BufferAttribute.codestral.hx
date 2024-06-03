import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.Warn;

class _Vector {
    public static var instance: Vector3 = new Vector3();
}

class _Vector2 {
    public static var instance: Vector2 = new Vector2();
}

class BufferAttribute {

    public var isBufferAttribute:Bool = true;
    public var name:String = '';
    public var array:Array<Float>;
    public var itemSize:Int;
    public var count:Int;
    public var normalized:Bool;
    public var usage:Int = StaticDrawUsage;
    public var _updateRange:Dynamic = {offset: 0, count: -1};
    public var updateRanges:Array<Dynamic> = [];
    public var gpuType:Int = FloatType;
    public var version:Int = 0;
    public var onUploadCallback:Dynamic = function() {};

    public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
        if (Std.is(array, Array<Float>)) {
            throw new Error("THREE.BufferAttribute: array should be a Typed Array.");
        }

        this.array = array;
        this.itemSize = itemSize;
        this.count = (array != null) ? array.length / itemSize : 0;
        this.normalized = normalized;
    }

    public function set needsUpdate(value:Bool) {
        if (value == true) this.version++;
    }

    public function get updateRange():Dynamic {
        Warn.warnOnce("THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.");
        return this._updateRange;
    }

    public function setUsage(value:Int):BufferAttribute {
        this.usage = value;
        return this;
    }

    public function addUpdateRange(start:Int, count:Int):Void {
        this.updateRanges.push({start: start, count: count});
    }

    public function clearUpdateRanges():Void {
        this.updateRanges = [];
    }

    public function copy(source:BufferAttribute):BufferAttribute {
        this.name = source.name;
        this.array = Array.from(source.array);
        this.itemSize = source.itemSize;
        this.count = source.count;
        this.normalized = source.normalized;

        this.usage = source.usage;
        this.gpuType = source.gpuType;

        return this;
    }

    public function copyAt(index1:Int, attribute:BufferAttribute, index2:Int):BufferAttribute {
        index1 *= this.itemSize;
        index2 *= attribute.itemSize;

        for (var i:Int = 0; i < this.itemSize; i++) {
            this.array[index1 + i] = attribute.array[index2 + i];
        }

        return this;
    }

    public function copyArray(array:Array<Float>):BufferAttribute {
        this.array = Array.from(array);
        return this;
    }

    // Continue with the rest of the methods in a similar manner...
}