package three.js.examples.jsm.renderers.common;

import three.BufferAttribute;

class StorageBufferAttribute extends BufferAttribute {
    public var isStorageBufferAttribute: Bool;

    public function new(array: Dynamic, itemSize: Int, ?typeClass: Dynamic = Float32Array) {
        if (!Std.is(array, ArrayBuffer)) {
            array = Type.createInstance(typeClass, [array * itemSize]);
        }
        super(array, itemSize);
        isStorageBufferAttribute = true;
    }
}