class GLBufferAttribute {

	var isGLBufferAttribute:Bool;
	var name:String;
	var buffer:Dynamic;
	var type:Dynamic;
	var itemSize:Int;
	var elementSize:Int;
	var count:Int;
	var version:Int;

	public function new(buffer:Dynamic, type:Dynamic, itemSize:Int, elementSize:Int, count:Int) {
		this.isGLBufferAttribute = true;
		this.name = '';
		this.buffer = buffer;
		this.type = type;
		this.itemSize = itemSize;
		this.elementSize = elementSize;
		this.count = count;
		this.version = 0;
	}

	public function set needsUpdate(value:Bool) {
		if (value == true) this.version++;
	}

	public function setBuffer(buffer:Dynamic):GLBufferAttribute {
		this.buffer = buffer;
		return this;
	}

	public function setType(type:Dynamic, elementSize:Int):GLBufferAttribute {
		this.type = type;
		this.elementSize = elementSize;
		return this;
	}

	public function setItemSize(itemSize:Int):GLBufferAttribute {
		this.itemSize = itemSize;
		return this;
	}

	public function setCount(count:Int):GLBufferAttribute {
		this.count = count;
		return this;
	}

}