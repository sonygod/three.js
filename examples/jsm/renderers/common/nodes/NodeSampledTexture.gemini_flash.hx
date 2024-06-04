import SampledTexture from "../SampledTexture";

class NodeSampledTexture extends SampledTexture {

	public var textureNode:Dynamic;

	public function new(name:String, textureNode:Dynamic) {
		super(name, textureNode != null ? textureNode.value : null);
		this.textureNode = textureNode;
	}

	override public function get needsBindingsUpdate():Bool {
		return this.textureNode.value != this.texture || super.needsBindingsUpdate;
	}

	override public function update():Bool {
		if (this.texture != this.textureNode.value) {
			this.texture = this.textureNode.value;
			return true;
		}
		return super.update();
	}
}

class NodeSampledCubeTexture extends NodeSampledTexture {

	public function new(name:String, textureNode:Dynamic) {
		super(name, textureNode);
		this.isSampledCubeTexture = true;
	}
}

class NodeSampledTexture {

	public static var NodeSampledTexture:Class<NodeSampledTexture> = NodeSampledTexture;
	public static var NodeSampledCubeTexture:Class<NodeSampledCubeTexture> = NodeSampledCubeTexture;
}