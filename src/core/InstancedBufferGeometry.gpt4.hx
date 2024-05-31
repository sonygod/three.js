import threejs.core.BufferGeometry;

class InstancedBufferGeometry extends BufferGeometry {

	public var isInstancedBufferGeometry:Bool;
	public var type:String;
	public var instanceCount:Float;

	public function new() {
		super();

		this.isInstancedBufferGeometry = true;
		this.type = 'InstancedBufferGeometry';
		this.instanceCount = Math.POSITIVE_INFINITY;
	}

	public function copy(source:InstancedBufferGeometry):InstancedBufferGeometry {
		super.copy(source);

		this.instanceCount = source.instanceCount;

		return this;
	}

	public function toJSON():Dynamic {
		var data:Dynamic = super.toJSON();

		data.instanceCount = this.instanceCount;
		data.isInstancedBufferGeometry = true;

		return data;
	}

}