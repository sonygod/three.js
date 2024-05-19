package three.core;

class InstancedBufferAttribute extends BufferAttribute {

	var meshPerAttribute:Int;

	public function new(array:Dynamic, itemSize:Int, normalized:Bool, meshPerAttribute:Int = 1) {
		super(array, itemSize, normalized);
		this.meshPerAttribute = meshPerAttribute;
	}

	public function copy(source:InstancedBufferAttribute):InstancedBufferAttribute {
		super.copy(source);
		this.meshPerAttribute = source.meshPerAttribute;
		return this;
	}

	public function toJSON():Dynamic {
		var data = super.toJSON();
		data.meshPerAttribute = this.meshPerAttribute;
		data.isInstancedBufferAttribute = true;
		return data;
	}

}