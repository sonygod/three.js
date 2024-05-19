package three.js.src.core;

import haxe.io.Float32Array;

class Float32BufferAttribute extends BufferAttribute {

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
		super(new Float32Array(array), itemSize, normalized);
	}

}