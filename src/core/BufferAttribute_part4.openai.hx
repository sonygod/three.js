class Uint8ClampedBufferAttribute extends BufferAttribute {

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
		super(new Uint8ClampedArray(array), itemSize, normalized);
	}

}