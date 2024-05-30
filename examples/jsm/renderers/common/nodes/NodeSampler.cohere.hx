class NodeSampler extends Sampler {
    public function new(name:String, textureNode:Dynamic) {
        super(name, textureNode != null ? textureNode.value : null);
        this.textureNode = textureNode;
    }

    public function update():Void {
        this.texture = this.textureNode.value;
    }
}