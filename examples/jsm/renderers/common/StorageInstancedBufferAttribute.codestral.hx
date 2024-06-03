import three.InstancedBufferAttribute;

class StorageInstancedBufferAttribute extends InstancedBufferAttribute {

    public function new(array:Dynamic, itemSize:Int, ?typeClass:Class<Float>) {
        if (Std.is(array, js.html.ArrayBuffer) == false) {
            var size:Int = array * itemSize;
            if (typeClass == null) typeClass = Float;
            array = Array.from(0, size, 0.0).map(typeClass.create);
        }

        super(array, itemSize);

        this.isStorageInstancedBufferAttribute = true;
    }

}