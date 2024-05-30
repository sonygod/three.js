import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.accessors.TextureNode;
import three.js.examples.jsm.shadernode.ShaderNode;

class TextureStoreNode extends TextureNode {

    public var storeNode:ShaderNode;

    public var isStoreTextureNode:Bool = true;

    public function new(value:Dynamic, uvNode:ShaderNode, storeNode:ShaderNode = null) {
        super(value, uvNode);
        this.storeNode = storeNode;
    }

    public function getInputType():String {
        return 'storageTexture';
    }

    public function setup(builder:Node) {
        super.setup(builder);
        var properties = builder.getNodeProperties(this);
        properties.storeNode = this.storeNode;
    }

    public function generate(builder:Node, output:String):String {
        var snippet:String;
        if (this.storeNode != null) {
            snippet = this.generateStore(builder);
        } else {
            snippet = super.generate(builder, output);
        }
        return snippet;
    }

    public function generateStore(builder:Node):String {
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

Node.addNodeClass('TextureStoreNode', TextureStoreNode);

class TextureStore {
    public static function textureStore(value:Dynamic, uvNode:ShaderNode, storeNode:ShaderNode):TextureStoreNode {
        var node = new TextureStoreNode(value, uvNode, storeNode);
        if (storeNode != null) node.append();
        return node;
    }
}