import js.three.BufferAttribute;

class StorageBufferAttribute extends BufferAttribute {
	public var isStorageBufferAttribute:Bool = true;

	public function new(array:Dynamic, itemSize:Int, ?typeClass:Class<Dynamic> = null) {
		if (typeClass == null) typeClass = Float32Array;
		if (!js.ArrayBuffer.isView(array)) array = new typeClass(array * itemSize);
		super(array, itemSize);
	}
}