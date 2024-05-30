import js.Buffer from './Buffer.js';

class StorageBuffer extends js.Buffer {
	public function new(name: String, attribute: { array: Array<Float> }) {
		super(name, attribute.array);
		this.attribute = attribute;
		this.isStorageBuffer = true;
	}
}

@:jsRequire("./StorageBuffer.js")
@:jsName("default")
export class StorageBufferJS(StorageBuffer) {}