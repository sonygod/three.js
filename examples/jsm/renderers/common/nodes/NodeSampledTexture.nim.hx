import SampledTexture.SampledTexture;

class NodeSampledTexture extends SampledTexture {
    public var textureNode:Dynamic;

    public function new(name:String, textureNode:Dynamic) {
        super(name, textureNode ? textureNode.value : null);
        this.textureNode = textureNode;
    }

    public function get needsBindingsUpdate():Bool {
        return this.textureNode.value != this.texture || super.needsBindingsUpdate;
    }

    public function update():Bool {
        var textureNode = this.textureNode;
        if (this.texture != textureNode.value) {
            this.texture = textureNode.value;
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

@:expose
@:keep
@:include('NodeSampledTexture')
@:include('NodeSampledCubeTexture')