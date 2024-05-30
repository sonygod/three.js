package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.nodes.TextureNode;

class TextureStoreNode extends TextureNode {

    public var storeNode:Node;

    public function new(value:Dynamic, uvNode:Node, ?storeNode:Node) {
        super(value, uvNode);
        this.storeNode = storeNode;
        this.isStoreTextureNode = true;
    }

    override public function getInputType(builder:Dynamic):String {
        return 'storageTexture';
    }

    override public function setup(builder:Dynamic):Void {
        super.setup(builder);
        var properties = builder.getNodeProperties(this);
        properties.storeNode = this.storeNode;
    }

    override public function generate(builder:Dynamic, output:Dynamic):String {
        var snippet:String;
        if (this.storeNode != null) {
            snippet = generateStore(builder);
        } else {
            snippet = super.generate(builder, output);
        }
        return snippet;
    }

    private function generateStore(builder:Dynamic):String {
        var properties = builder.getNodeProperties(this);
        var uvNode:Node = properties.uvNode;
        var storeNode:Node = properties.storeNode;
        var textureProperty:String = super.generate(builder, 'property');
        var uvSnippet:String = uvNode.build(builder, 'uvec2');
        var storeSnippet:String = storeNode.build(builder, 'vec4');
        var snippet:String = builder.generateTextureStore(builder, textureProperty, uvSnippet, storeSnippet);
        builder.addLineFlowCode(snippet);
        return snippet;
    }
}

// Node proxy wrapper
class TextureStoreNodeProxy {
    public static function create(value:Dynamic, uvNode:Node, ?storeNode:Node):TextureStoreNode {
        var node:TextureStoreNode = new TextureStoreNode(value, uvNode, storeNode);
        if (storeNode != null) node.append();
        return node;
    }
}

// Register node class
Node.addNodeClass('TextureStoreNode', TextureStoreNode);