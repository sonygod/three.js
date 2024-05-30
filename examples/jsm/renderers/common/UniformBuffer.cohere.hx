class UniformBuffer extends Buffer {
	public var isUniformBuffer:Bool = true;

	public function new(name:String, buffer:Bytes = null) {
		super(name, buffer);
	}
}