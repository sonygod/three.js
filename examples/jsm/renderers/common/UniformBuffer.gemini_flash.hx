import Buffer from "./Buffer.hx";

class UniformBuffer extends Buffer {

	public var isUniformBuffer:Bool;

	public function new(name:String, buffer:haxe.io.Bytes = null) {
		super(name, buffer);
		this.isUniformBuffer = true;
	}

}

class UniformBuffer {
	static public var __name__ = "UniformBuffer";
}