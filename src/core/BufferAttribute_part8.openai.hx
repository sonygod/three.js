import js.html.Uint32Array;

class Uint32BufferAttribute extends BufferAttribute {

	public function new(array : Array<Int>, itemSize : Int, normalized : Bool) {
		super(new Uint32Array(array), itemSize, normalized);
	}

}