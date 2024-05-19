package three.src.core;

import haxe.io.UInt16Array;

class Uint16BufferAttribute extends BufferAttribute {
    
    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new UInt16Array(array), itemSize, normalized);
    }
}