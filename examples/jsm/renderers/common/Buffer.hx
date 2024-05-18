package three.js.examples.jm.renderers.common;

import haxe.io.Bytes;

class Buffer extends Binding {
    public var isBuffer:Bool;
    public var bytesPerElement:Int;
    public var _buffer:Bytes;

    public function new(name:String, ?buffer:Bytes) {
        super(name);
        this.isBuffer = true;
        this.bytesPerElement = 4; // Float32Array.BYTES_PER_ELEMENT
        this._buffer = buffer;
    }

    public var byteLength(get, never):Int;
    private function get_byteLength():Int {
        return getFloatLength(_buffer.length);
    }

    public var buffer(get, never):Bytes;
    private function get_buffer():Bytes {
        return _buffer;
    }

    public function update():Bool {
        return true;
    }
}