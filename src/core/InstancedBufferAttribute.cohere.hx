class InstancedBufferAttribute extends BufferAttribute {
	public var meshPerAttribute:Int;
	public var isInstancedBufferAttribute:Bool;

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool, meshPerAttribute:Int) {
		super(array, itemSize, normalized);
		this.isInstancedBufferAttribute = true;
		this.meshPerAttribute = meshPerAttribute;
	}

	public function copy(source:InstancedBufferAttribute):InstancedBufferAttribute {
		super.copy(source);
		this.meshPerAttribute = source.meshPerAttribute;
		return this;
	}

	public function toJSON():HashMap<String, Dynamic> {
		var data = super.toJSON();
		data.set("meshPerAttribute", this.meshPerAttribute);
		data.set("isInstancedBufferAttribute", true);
		return data;
	}
}