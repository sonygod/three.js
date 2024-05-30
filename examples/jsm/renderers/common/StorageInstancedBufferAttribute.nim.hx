import three.renderers.InstancedBufferAttribute;

class StorageInstancedBufferAttribute extends InstancedBufferAttribute {

    public function new(array:Array<Dynamic>, itemSize:Int, typeClass:Class<Float32Array> = Float32Array) {

        if (!Std.is(array, ArrayBufferView)) {
            array = Type.createInstance(typeClass, [array * itemSize]);
        }

        super(array, itemSize);

        this.isStorageInstancedBufferAttribute = true;

    }

}