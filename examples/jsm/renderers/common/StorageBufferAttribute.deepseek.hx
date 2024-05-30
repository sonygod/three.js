import three.BufferAttribute;

class StorageBufferAttribute extends BufferAttribute {

	public function new(array:Dynamic, itemSize:Int, typeClass:Class<Dynamic> = Float32Array) {

		if (array is ArrayBufferView == false) array = Reflect.construct(typeClass, [array * itemSize]);

		super(array, itemSize);

		this.isStorageBufferAttribute = true;

	}

}

@:keep
class Float32Array {
	public function new(size:Int) {}
}

typedef ArrayBufferView = js.html.ArrayBufferView;