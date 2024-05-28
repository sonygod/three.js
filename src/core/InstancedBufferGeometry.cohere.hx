class InstancedBufferGeometry extends BufferGeometry {
	public var isInstancedBufferGeometry:Bool = true;
	public var type:String = 'InstancedBufferGeometry';
	public var instanceCount:Int = Int.MaxValue;

	public function new() {
		super();
	}

	public function copy(source:InstancedBufferGeometry):InstancedBufferGeometry {
		super.copy(source);
		instanceCount = source.instanceCount;
		return this;
	}

	public function toJSON():HashMap {
		var data = super.toJSON();
		data.set('instanceCount', instanceCount);
		data.set('isInstancedBufferGeometry', isInstancedBufferGeometry);
		return data;
	}

}