package three.js.src.core;

import haxe.io.UInt32Array;

class Uint32BufferAttribute extends BufferAttribute {

	public function new(array:Array<UInt>, itemSize:Int, normalized:Bool) {
		super(new UInt32Array(array), itemSize, normalized);
	}

}