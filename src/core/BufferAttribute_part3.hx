package three.src.core;

import haxe.io.UInt8Array;

class Uint8BufferAttribute extends BufferAttribute {

    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new UInt8Array(array), itemSize, normalized);
    }

}