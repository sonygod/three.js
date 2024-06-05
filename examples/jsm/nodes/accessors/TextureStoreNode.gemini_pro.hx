import core.Node;
import shadernode.ShaderNode;
import shadernode.ShaderNodeProxy;
import TextureNode from "./TextureNode";

class TextureStoreNode extends TextureNode {

	public var storeNode:ShaderNode;

	public var isStoreTextureNode:Bool = true;

	public function new(value:Dynamic, uvNode:ShaderNode, storeNode:ShaderNode = null) {
		super(value, uvNode);
		this.storeNode = storeNode;
	}

	override public function getInputType(builder:Dynamic):String {
		return "storageTexture";
	}

	override public function setup(builder:Dynamic):Void {
		super.setup(builder);
		builder.getNodeProperties(this).storeNode = this.storeNode;
	}

	override public function generate(builder:Dynamic, output:String):String {
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
		var { uvNode, storeNode } = properties;

		var textureProperty = super.generate(builder, "property");
		var uvSnippet = uvNode.build(builder, "uvec2");
		var storeSnippet = storeNode.build(builder, "vec4");

		var snippet = builder.generateTextureStore(builder, textureProperty, uvSnippet, storeSnippet);
		builder.addLineFlowCode(snippet);

		return snippet;
	}
}

var textureStoreBase = ShaderNodeProxy.proxy(TextureStoreNode);

var textureStore = function(value:Dynamic, uvNode:ShaderNode, storeNode:ShaderNode):ShaderNode {
	var node = textureStoreBase(value, uvNode, storeNode);
	if (storeNode != null) node.append();
	return node;
};

Node.addNodeClass("TextureStoreNode", TextureStoreNode);