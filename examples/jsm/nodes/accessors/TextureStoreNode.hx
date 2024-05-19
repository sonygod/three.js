package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.nodes.TextureNode;
import three.js.shadernode.ShaderNode;

class TextureStoreNode extends TextureNode {
    public var storeNode:Node;
    public var isStoreTextureNode:Bool;

    public function new(value:Dynamic, uvNode:Node, storeNode:Node = null) {
        super(value, uvNode);
        this.storeNode = storeNode;
        this.isStoreTextureNode = true;
    }

    public function getInputType(builder:Dynamic):String {
        return 'storageTexture';
    }

    public function setup(builder:Dynamic):Void {
        super.setup(builder);
        var properties = builder.getNodeProperties(this);
        properties.storeNode = this.storeNode;
    }

    public function generate(builder:Dynamic, output:Dynamic):String {
        var snippet:String;
        if (this.storeNode != null) {
            snippet = this.generateStore(builder);
        } else {
            snippet = super.generate(builder, output);
        }
        return snippet;
    }

    public function generateStore(builder:Dynamic):String {
        var properties = builder.getNodeProperties(this);
        var uvNode = properties.uvNode;
        var storeNode = properties.storeNode;
        var textureProperty = super.generate(builder, 'property');
        var uvSnippet = uvNode.build(builder, 'uvec2');
        var storeSnippet = storeNode.build(builder, 'vec4');
        var snippet = builder.generateTextureStore(builder, textureProperty, uvSnippet, storeSnippet);
        builder.addLineFlowCode(snippet);
        return snippet;
    }
}

@:native("textureStore")
extern class TextureStore {
    public static function textureStore(value:Dynamic, uvNode:Node, storeNode:Node = null):Node {
        var node = textureStoreBase(value, uvNode, storeNode);
        if (storeNode != null) node.append();
        return node;
    }
}

@:native("textureStoreBase")
extern class TextureStoreBase {
    public function new(value:Dynamic, uvNode:Node, storeNode:Node = null) {
        return new TextureStoreNode(value, uvNode, storeNode);
    }
}

Node.addNodeClass('TextureStoreNode', TextureStoreNode);