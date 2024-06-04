import Binding from "./Binding";
import BufferUtils from "./BufferUtils";

class Buffer extends Binding {

	public var isBuffer:Bool = true;
	public var bytesPerElement:Int = 4; // Float32Array.BYTES_PER_ELEMENT in Haxe
	public var _buffer:haxe.io.Bytes;

	public function new(name:String, buffer:haxe.io.Bytes = null) {
		super(name);
		this._buffer = buffer;
	}

	public function get byteLength():Int {
		return BufferUtils.getFloatLength(this._buffer.length);
	}

	public function get buffer():haxe.io.Bytes {
		return this._buffer;
	}

	public function update():Bool {
		return true;
	}

}

export default Buffer;