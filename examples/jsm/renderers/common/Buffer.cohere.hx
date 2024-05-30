import js.Browser.Float32Array;

import getFloatLength from './BufferUtils.hx';

class Buffer extends js.Browser.Binding {
    public var isBuffer:Bool = true;
    public var bytesPerElement:Int = Float32Array.BYTES_PER_ELEMENT;
    public var _buffer:Dynamic;

    public function new(name:String, buffer:Dynamic) {
        super(name);
        this._buffer = buffer;
    }

    public function get_byteLength():Int {
        return getFloatLength(this._buffer.byteLength);
    }

    public function get_buffer():Dynamic {
        return this._buffer;
    }

    public function update():Bool {
        return true;
    }
}