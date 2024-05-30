package three.js.examples.jsm.renderers.common;

import three.js.examples.jsm.renderers.common.Buffer;

class StorageBuffer extends Buffer {

	public var attribute:Dynamic;

	public function new(name:String, attribute:Dynamic) {
		super(name, attribute != null ? attribute.array : null);
		this.attribute = attribute;
		this.isStorageBuffer = true;
	}

}