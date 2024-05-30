import three.InstancedBufferAttribute;

class StorageInstancedBufferAttribute extends InstancedBufferAttribute {

	public function new(array:Dynamic, itemSize:Int, typeClass:Class<Dynamic> = Float32Array) {

		if (array is ArrayBufferView == false) array = Type.createInstance(typeClass, array * itemSize);

		super(array, itemSize);

		this.isStorageInstancedBufferAttribute = true;

	}

}

typedef StorageInstancedBufferAttribute_threejs = three.InstancedBufferAttribute;

@:jsRequire('three.js/examples/jsm/renderers/common/StorageInstancedBufferAttribute.js')
@:native('StorageInstancedBufferAttribute') extern class StorageInstancedBufferAttribute extends StorageInstancedBufferAttribute_threejs {}