import three.BufferAttribute;

class StorageBufferAttribute extends BufferAttribute {

    public function new(array:Dynamic, itemSize:Int, typeClass:Class<Float> = Float) {
        if (!Std.is(array, js.html.ArrayBuffer)) {
            var length = js.Boot.dynamicField(array, 'length');
            if (length != null) {
                var arraySize = length * itemSize;
                var ArrayType = Type.resolveClass(Type.getClassName(typeClass));
                array = Type.createEmptyInstance(ArrayType, [arraySize]);
            }
        }

        super(array, itemSize);

        this.isStorageBufferAttribute = true;
    }
}