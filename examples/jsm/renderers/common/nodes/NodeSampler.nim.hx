import Sampler.Sampler;

class NodeSampler extends Sampler {

    public var textureNode:Dynamic;

    public function new(name:String, textureNode:Dynamic) {
        super(name, textureNode != null ? cast textureNode.value : null);
        this.textureNode = textureNode;
    }

    public function update() {
        this.texture = cast this.textureNode.value;
    }

}