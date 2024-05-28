package ;

class InstancedInterleavedBuffer extends InterleavedBuffer {
	public var meshPerAttribute:Int;
	public var isInstancedInterleavedBuffer:Bool;

	public function new(array:Array<Dynamic>, stride:Int, meshPerAttribute:Int = 1) {
		super(array, stride);
		this.isInstancedInterleavedBuffer = true;
		this.meshPerAttribute = meshPerAttribute;
	}

	public function copy(source:InstancedInterleavedBuffer):InstancedInterleavedBuffer {
		super.copy(source);
		this.meshPerAttribute = source.meshPerAttribute;
		return this;
	}

	public function clone():InstancedInterleavedBuffer {
		var ib:InstancedInterleavedBuffer = super.clone() as InstancedInterleavedBuffer;
		ib.meshPerAttribute = this.meshPerAttribute;
		return ib;
	}

	public function toJSON():Object {
		var json:Object = super.toJSON();
		json.isInstancedInterleavedBuffer = true;
		json.meshPerAttribute = this.meshPerAttribute;
		return json;
	}
}