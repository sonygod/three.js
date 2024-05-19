import three.js.src.core.InterleavedBuffer;

class InstancedInterleavedBuffer extends InterleavedBuffer {

	public var isInstancedInterleavedBuffer:Bool;
	public var meshPerAttribute(default, null):Int;

	public function new(array:Array<Int>, stride:Int, meshPerAttribute:Int = 1) {
		super(array, stride);
		this.isInstancedInterleavedBuffer = true;
		this.meshPerAttribute = meshPerAttribute;
	}

	public function copy(source:InstancedInterleavedBuffer):InstancedInterleavedBuffer {
		super.copy(source);
		this.meshPerAttribute = source.meshPerAttribute;
		return this;
	}

	public function clone(data:Array<Int>):InstancedInterleavedBuffer {
		var ib = super.clone(data);
		ib.meshPerAttribute = this.meshPerAttribute;
		return ib;
	}

	public function toJSON(data:Array<Int>):Dynamic {
		var json = super.toJSON(data);
		json.isInstancedInterleavedBuffer = true;
		json.meshPerAttribute = this.meshPerAttribute;
		return json;
	}

}