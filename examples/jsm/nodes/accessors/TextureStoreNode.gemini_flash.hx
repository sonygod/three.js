import core.Node;
import shadernode.ShaderNode;
import shadernode.TextureNode;

class TextureStoreNode extends TextureNode {

	public var storeNode: ShaderNode;

	public var isStoreTextureNode: Bool = true;

	public function new(value: Dynamic, uvNode: ShaderNode, storeNode: ShaderNode = null) {
		super(value, uvNode);
		this.storeNode = storeNode;
	}

	override public function getInputType(builder: Dynamic): String {
		return "storageTexture";
	}

	override public function setup(builder: Dynamic): Void {
		super.setup(builder);
		builder.getNodeProperties(this).storeNode = this.storeNode;
	}

	override public function generate(builder: Dynamic, output: String): String {
		var snippet: String;
		if (this.storeNode != null) {
			snippet = generateStore(builder);
		} else {
			snippet = super.generate(builder, output);
		}
		return snippet;
	}

	public function generateStore(builder: Dynamic): String {
		var properties = builder.getNodeProperties(this);
		var uvNode = properties.uvNode;
		var storeNode = properties.storeNode;
		var textureProperty = super.generate(builder, "property");
		var uvSnippet = uvNode.build(builder, "uvec2");
		var storeSnippet = storeNode.build(builder, "vec4");
		var snippet = builder.generateTextureStore(builder, textureProperty, uvSnippet, storeSnippet);
		builder.addLineFlowCode(snippet);
		return snippet;
	}

}

class TextureStoreNodeProxy extends ShaderNode.Proxy {
	public function new() {
		super(TextureStoreNode);
	}
}

var textureStoreBase = new TextureStoreNodeProxy();

public function textureStore(value: Dynamic, uvNode: ShaderNode, storeNode: ShaderNode): TextureStoreNode {
	var node = textureStoreBase.create(value, uvNode, storeNode);
	if (storeNode != null) {
		node.append();
	}
	return node;
}

Node.addNodeClass("TextureStoreNode", TextureStoreNode);