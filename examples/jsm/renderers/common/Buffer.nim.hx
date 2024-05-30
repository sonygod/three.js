import Binding from './Binding.js';
import { getFloatLength } from './BufferUtils.js';

class Buffer extends Binding {

	public var isBuffer:Bool = true;
	public var bytesPerElement:Int = Float32Array.BYTES_PER_ELEMENT;
	private var _buffer:Dynamic;

	public function new(name:String, buffer:Dynamic = null) {
		super(name);
		this._buffer = buffer;
	}

	public function get_byteLength():Int {
		return getFloatLength(Std.int(_buffer.byteLength));
	}

	public function get_buffer():Dynamic {
		return this._buffer;
	}

	public function update():Bool {
		return true;
	}

}

export default Buffer;