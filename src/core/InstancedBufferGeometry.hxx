import three.js.src.core.BufferGeometry;

class InstancedBufferGeometry extends BufferGeometry {

	public function new() {

		super();

		this.isInstancedBufferGeometry = true;

		this.type = 'InstancedBufferGeometry';
		this.instanceCount = Infinity;

	}

	public function copy(source:InstancedBufferGeometry) {

		super.copy(source);

		this.instanceCount = source.instanceCount;

		return this;

	}

	public function toJSON() {

		var data = super.toJSON();

		data.instanceCount = this.instanceCount;

		data.isInstancedBufferGeometry = true;

		return data;

	}

}