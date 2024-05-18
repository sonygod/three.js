package three.js.examples.jsm.renderers.common;

import three.InstancedBufferAttribute;

class StorageInstancedBufferAttribute extends InstancedBufferAttribute {
    
    public var isStorageInstancedBufferAttribute:Bool;

    public function new(array:Dynamic, itemSize:Int, ?typeClass:Class<Dynamic> = Float32Array) {
        if (!Std.isOfType(array, ArrayBuffer)) {
            array = Type.createInstance(typeClass, [array * itemSize]);
        }
        super(array, itemSize);
        isStorageInstancedBufferAttribute = true;
    }
}