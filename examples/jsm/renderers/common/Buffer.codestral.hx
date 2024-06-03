import Binding from './Binding';
import BufferUtils from './BufferUtils';

class Buffer extends Binding {

    public var isBuffer:Bool;
    public var bytesPerElement:Int;
    private var _buffer:haxe.io.Bytes;

    public function new(name:String, ?buffer:haxe.io.Bytes) {
        super(name);
        this.isBuffer = true;
        this.bytesPerElement = 4;  // Float32Array.BYTES_PER_ELEMENT is 4
        this._buffer = buffer != null ? buffer : new haxe.io.Bytes(0);
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