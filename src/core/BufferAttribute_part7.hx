package three.js.src.core;

import js.html.Int32Array;

class Int32BufferAttribute extends BufferAttribute {

    public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
        super(new Int32Array(array), itemSize, normalized);
    }

}