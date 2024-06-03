@:expose
class TextureStoreNode extends TextureNode {
    public var storeNode:Dynamic;
    public var isStoreTextureNode:Bool = true;

    public function new(value, uvNode, storeNode:Dynamic = null) {
        super(value, uvNode);
        this.storeNode = storeNode;
    }

    public function getInputType():String {
        return 'storageTexture';
    }

    @:keep
    public function setup(builder) {
        super.setup(builder);
        var properties = builder.getNodeProperties(this);
        properties.storeNode = this.storeNode;
    }

    @:keep
    public function generate(builder, output) {
        var snippet;
        if (this.storeNode !== null) {
            snippet = this.generateStore(builder);
        } else {
            snippet = super.generate(builder, output);
        }
        return snippet;
    }

    @:keep
    public function generateStore(builder) {
        var properties = builder.getNodeProperties(this);
        var uvNode = properties.uvNode;
        var storeNode = properties.storeNode;
        var textureProperty = super.generate(builder, 'property');
        var uvSnippet = uvNode.build(builder, 'uvec2');
        var storeSnippet = storeNode.build(builder, 'vec4');
        var snippet = builder.generateTextureStore(builder, textureProperty, uvSnippet, storeSnippet);
        builder.addLineFlowCode(snippet);
    }
}

// The nodeProxy and textureStore functions are not present in the provided code, so I have excluded them from the conversion.