import three.core.BufferGeometry;

class InstancedBufferGeometry extends BufferGeometry {

	public var isInstancedBufferGeometry:Bool = true;

	public var instanceCount:Int = Int.MAX_VALUE;

	public function new() {
		super();
		this.type = "InstancedBufferGeometry";
	}

	public function copy(source:InstancedBufferGeometry):InstancedBufferGeometry {
		super.copy(source);
		this.instanceCount = source.instanceCount;
		return this;
	}

	public function toJSON():Dynamic {
		var data = super.toJSON();
		data.instanceCount = this.instanceCount;
		data.isInstancedBufferGeometry = true;
		return data;
	}

}