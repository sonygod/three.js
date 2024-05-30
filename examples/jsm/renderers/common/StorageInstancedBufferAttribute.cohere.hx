import js.three.InstancedBufferAttribute;

class StorageInstancedBufferAttribute extends InstancedBufferAttribute {
	public var isStorageInstancedBufferAttribute:Bool;
	public function new(array:Dynamic, itemSize:Int, ?typeClass:Dynamic) {
		if (!js.ArrayBuffer.isView(array)) {
			array = new typeClass(array * itemSize);
		}
		super(array, itemSize);
		isStorageInstancedBufferAttribute = true;
	}
}

class Export {
	public static inline var __default__:StorageInstancedBufferAttribute = StorageInstancedBufferAttribute;
}