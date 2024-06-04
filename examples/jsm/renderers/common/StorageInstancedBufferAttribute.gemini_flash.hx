import three.extras.core.InstancedBufferAttribute;
import three.math.Vector3;

class StorageInstancedBufferAttribute extends InstancedBufferAttribute {

	public function new(array:Array<Float>, itemSize:Int, typeClass:Dynamic = Float32Array) {
		if ( !ArrayBuffer.isView(array) ) array = new typeClass(array * itemSize);
		super(array, itemSize);
		this.isStorageInstancedBufferAttribute = true;
	}

	public var isStorageInstancedBufferAttribute:Bool;

}

class ArrayBuffer {

	public static function isView(array:Dynamic):Bool {
		return js.Boot.instanceOf(array, js.html.Float32Array);
	}
}