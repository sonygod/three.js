import three.jsm.renderers.common.nodes.SampledTexture;

class NodeSampledTexture extends SampledTexture {

    public var textureNode: Dynamic;

    public function new(name: String, textureNode: Dynamic = null) {
        super(name, textureNode != null ? textureNode.value : null);
        this.textureNode = textureNode;
    }

    public var needsBindingsUpdate(default, get): Bool {
        return this.textureNode.value != this.texture || super.needsBindingsUpdate;
    }

    public function update(): Bool {
        if (this.texture != this.textureNode.value) {
            this.texture = this.textureNode.value;
            return true;
        }
        return super.update();
    }
}

class NodeSampledCubeTexture extends NodeSampledTexture {

    public function new(name: String, textureNode: Dynamic) {
        super(name, textureNode);
        this.isSampledCubeTexture = true;
    }
}

// You may need to adjust the import path based on your project structure