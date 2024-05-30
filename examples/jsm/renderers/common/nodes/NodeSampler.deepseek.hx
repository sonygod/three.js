import Sampler from '../Sampler.js';

class NodeSampler extends Sampler {

	public function new(name:String, textureNode:TextureNode) {

		super(name, textureNode ? textureNode.value : null);

		this.textureNode = textureNode;

	}

	public function update() {

		this.texture = this.textureNode.value;

	}

}

@:native("default")
class NodeSamplerDefault extends NodeSampler {}