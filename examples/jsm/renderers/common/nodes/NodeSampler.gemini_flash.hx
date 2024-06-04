import sampler.Sampler;

class NodeSampler extends Sampler {

	public var textureNode:Dynamic;

	public function new(name:String, textureNode:Dynamic) {
		super(name, textureNode != null ? textureNode.value : null);
		this.textureNode = textureNode;
	}

	public function update() {
		this.texture = this.textureNode.value;
	}

}