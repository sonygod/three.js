import three.core.BufferAttribute;

class StorageBufferAttribute extends BufferAttribute {

	public function new(array:Dynamic, itemSize:Int, typeClass:Dynamic = Float32Array) {
		if (ArrayBuffer.isView(array) == false) {
			array = Type.createInstance(typeClass, [array * itemSize]);
		}
		super(array, itemSize);
		this.isStorageBufferAttribute = true;
	}

	public var isStorageBufferAttribute:Bool;

}