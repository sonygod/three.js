import js.Browser.Float32Array;
import js.Browser.ArrayBuffer;
import js.Browser.BufferUtils;

class Buffer extends Binding {

    public var isBuffer:Bool;
    public var bytesPerElement:Int;
    private var _buffer:ArrayBuffer<Float32Array>;

    public function new(name:String, buffer:ArrayBuffer<Float32Array> = null) {
        super(name);
        this.isBuffer = true;
        this.bytesPerElement = Float32Array.BYTES_PER_ELEMENT;
        this._buffer = buffer;
    }

    public function get_byteLength():Int {
        return BufferUtils.getFloatLength(this._buffer.byteLength);
    }

    public function get_buffer():ArrayBuffer<Float32Array> {
        return this._buffer;
    }

    public function update():Bool {
        return true;
    }

}