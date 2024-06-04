import Buffer from "./Buffer";

class StorageBuffer extends Buffer {

	public var attribute:Dynamic;
	public var isStorageBuffer:Bool;

	public function new(name:String, attribute:Dynamic) {
		super(name, attribute != null ? attribute.array : null);
		this.attribute = attribute;
		this.isStorageBuffer = true;
	}
}

export default StorageBuffer;