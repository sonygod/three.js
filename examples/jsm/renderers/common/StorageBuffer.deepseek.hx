import Buffer from './Buffer.js';

class StorageBuffer extends Buffer {

	public function new(name:String, attribute:Attribute) {

		super(name, attribute ? attribute.array : null);

		this.attribute = attribute;

		this.isStorageBuffer = true;

	}

}

@:expose
class StorageBuffer extends Buffer {}