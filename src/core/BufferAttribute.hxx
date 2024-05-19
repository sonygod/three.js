package three.src.core;

import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.warnOnce;

class BufferAttribute {
    static var _vector:Vector3 = new Vector3();
    static var _vector2:Vector2 = new Vector2();

    public var isBufferAttribute:Bool;
    public var name:String;
    public var array:Array<Float>;
    public var itemSize:Int;
    public var count:Int;
    public var normalized:Bool;
    public var usage:Int;
    public var _updateRange:{offset:Int, count:Int};
    public var updateRanges:Array<{start:Int, count:Int}>;
    public var gpuType:Int;
    public var version:Int;

    public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
        if (array is Array) {
            throw new TypeError('THREE.BufferAttribute: array should be a Typed Array.');
        }

        this.isBufferAttribute = true;
        this.name = '';
        this.array = array;
        this.itemSize = itemSize;
        this.count = array !== undefined ? array.length / itemSize : 0;
        this.normalized = normalized;
        this.usage = StaticDrawUsage;
        this._updateRange = {offset: 0, count: -1};
        this.updateRanges = [];
        this.gpuType = FloatType;
        this.version = 0;
    }

    // ... 其他方法的转换 ...
}

// ... 其他类的转换 ...