import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.accessors.TextureNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class TextureStoreNode extends TextureNode {

	public function new(value:Dynamic, uvNode:Dynamic, storeNode:Dynamic = null) {
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

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {
		var snippet:Dynamic;
		if (this.storeNode !== null) {
			snippet = this.generateStore(builder);
		} else {
			snippet = super.generate(builder, output);
		}
		return snippet;
	}

	public function generateStore(builder:Dynamic):Void {
		var properties = builder.getNodeProperties(this);
		var uvSnippet = properties.uvNode.build(builder, 'uvec2');
		var storeSnippet = properties.storeNode.build(builder, 'vec4');
		var textureProperty = super.generate(builder, 'property');
		var snippet = builder.generateTextureStore(builder, textureProperty, uvSnippet, storeSnippet);
		builder.addLineFlowCode(snippet);
	}

}

static function textureStore(value:Dynamic, uvNode:Dynamic, storeNode:Dynamic):Dynamic {
	var node = textureStoreBase(value, uvNode, storeNode);
	if (storeNode !== null) node.append();
	return node;
}

Node.addNodeClass('TextureStoreNode', TextureStoreNode);