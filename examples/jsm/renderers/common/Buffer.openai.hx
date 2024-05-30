package three.js.examples.jsm.renderers.common;

import three.js.examples.jsm.renderers.common.Binding;
import three.js.examples.jsm.renderers.common.BufferUtils;

class Buffer extends Binding {

    public var isBuffer:Bool = true;

    public var bytesPerElement:Int = 4; // equivalent to Float32Array.BYTES_PER_ELEMENT

    private var _buffer:Dynamic;

    public function new(name:String, ?buffer:Dynamic) {
        super(name);
        this._buffer = buffer;
    }

    public function get_byteLength():Int {
        return BufferUtils.getFloatLength(_buffer.byteLength);
    }

    public function get_buffer():Dynamic {
        return _buffer;
    }

    public function update():Bool {
        return true;
    }

}