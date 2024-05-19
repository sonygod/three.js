package three.js.src.core;

import js.html.Int16Array;

class Int16BufferAttribute extends BufferAttribute {

	public function new(array:Array<Int>, itemSize:Int, normalized:Bool) {
		super(new Int16Array(array), itemSize, normalized);
	}

}