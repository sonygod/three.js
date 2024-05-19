package three.js.src.core;

import haxe.io.UInt8ClampedArray;

class Uint8ClampedBufferAttribute extends BufferAttribute {

    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new UInt8ClampedArray(array), itemSize, normalized);
    }

}