import three.js.BufferAttribute;

class StorageBufferAttribute extends BufferAttribute {
    public var isStorageBufferAttribute:Bool = true;

    public function new(array:Dynamic, itemSize:Int, ?typeClass:Class<Dynamic> = Float32Array) {
        if (!Std.isOfType(array, ArrayBuffer)) {
            array = Type.createInstance(typeClass, [array * itemSize]);
        }
        super(array, itemSize);
    }
}