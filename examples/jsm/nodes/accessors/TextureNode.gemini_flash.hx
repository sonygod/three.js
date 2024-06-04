import UniformNode from "../core/UniformNode";
import UVNode from "./UVNode";
import TextureSizeNode from "./TextureSizeNode";
import ColorSpaceNode from "../display/ColorSpaceNode";
import ExpressionNode from "../code/ExpressionNode";
import Node from "../core/Node";
import MaxMipLevelNode from "../utils/MaxMipLevelNode";
import ShaderNode from "../shadernode/ShaderNode";
import {NodeUpdateType} from "../core/constants";

class TextureNode extends UniformNode {
	public var isTextureNode:Bool;
	public var uvNode:UVNode;
	public var levelNode:Node;
	public var compareNode:Node;
	public var depthNode:Node;
	public var gradNode:Array<Node>;
	public var sampler:Bool;
	public var updateMatrix:Bool;
	public var updateType:NodeUpdateType;
	public var referenceNode:Node;
	public var _value:Dynamic;

	public function new(value:Dynamic, uvNode:UVNode = null, levelNode:Node = null) {
		super(value);
		this.isTextureNode = true;
		this.uvNode = uvNode;
		this.levelNode = levelNode;
		this.compareNode = null;
		this.depthNode = null;
		this.gradNode = null;
		this.sampler = true;
		this.updateMatrix = false;
		this.updateType = NodeUpdateType.NONE;
		this.referenceNode = null;
		this._value = value;
		this.setUpdateMatrix(uvNode == null);
	}

	public function set(value:Dynamic) {
		if (this.referenceNode != null) {
			this.referenceNode.set(value);
		} else {
			this._value = value;
		}
	}

	public function get(value:Dynamic):Dynamic {
		return this.referenceNode != null ? this.referenceNode.get(value) : this._value;
	}

	public function getUniformHash(builder:Dynamic):Dynamic {
		return this.value.uuid;
	}

	public function getNodeType(builder:Dynamic):String {
		if (this.value.isDepthTexture == true) {
			return "float";
		}

		return "vec4";
	}

	public function getInputType(builder:Dynamic):String {
		return "texture";
	}

	public function getDefaultUV():UVNode {
		return UVNode.uv(this.value.channel);
	}

	public function updateReference(state:Dynamic):Dynamic {
		return this.value;
	}

	public function getTransformedUV(uvNode:UVNode):ShaderNode.ShaderNode {
		var texture = this.value;
		return UniformNode.uniform(texture.matrix).mul(ShaderNode.vec3(uvNode, 1)).xy;
	}

	public function setUpdateMatrix(value:Bool):TextureNode {
		this.updateMatrix = value;
		this.updateType = value ? NodeUpdateType.FRAME : NodeUpdateType.NONE;
		return this;
	}

	public function setupUV(builder:Dynamic, uvNode:UVNode):UVNode {
		var texture = this.value;
		if (builder.isFlipY() && (texture.isRenderTargetTexture == true || texture.isFramebufferTexture == true || texture.isDepthTexture == true)) {
			uvNode = uvNode.setY(uvNode.y.oneMinus());
		}

		return uvNode;
	}

	public function setup(builder:Dynamic) {
		var properties = builder.getNodeProperties(this);
		var uvNode = this.uvNode;
		if ((uvNode == null || builder.context.forceUVContext == true) && builder.context.getUV != null) {
			uvNode = builder.context.getUV(this);
		}

		if (uvNode == null) {
			uvNode = this.getDefaultUV();
		}

		if (this.updateMatrix == true) {
			uvNode = this.getTransformedUV(uvNode);
		}

		uvNode = this.setupUV(builder, uvNode);
		var levelNode = this.levelNode;
		if (levelNode == null && builder.context.getTextureLevel != null) {
			levelNode = builder.context.getTextureLevel(this);
		}

		properties.uvNode = uvNode;
		properties.levelNode = levelNode;
		properties.compareNode = this.compareNode;
		properties.gradNode = this.gradNode;
		properties.depthNode = this.depthNode;
	}

	public function generateUV(builder:Dynamic, uvNode:UVNode):String {
		return uvNode.build(builder, this.sampler == true ? "vec2" : "ivec2");
	}

	public function generateSnippet(builder:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, compareSnippet:String, gradSnippet:Array<String>):String {
		var texture = this.value;
		var snippet:String;
		if (levelSnippet != null) {
			snippet = builder.generateTextureLevel(texture, textureProperty, uvSnippet, levelSnippet, depthSnippet);
		} else if (gradSnippet != null) {
			snippet = builder.generateTextureGrad(texture, textureProperty, uvSnippet, gradSnippet, depthSnippet);
		} else if (compareSnippet != null) {
			snippet = builder.generateTextureCompare(texture, textureProperty, uvSnippet, compareSnippet, depthSnippet);
		} else if (this.sampler == false) {
			snippet = builder.generateTextureLoad(texture, textureProperty, uvSnippet, depthSnippet);
		} else {
			snippet = builder.generateTexture(texture, textureProperty, uvSnippet, depthSnippet);
		}

		return snippet;
	}

	public function generate(builder:Dynamic, output:String):String {
		var properties = builder.getNodeProperties(this);
		var texture = this.value;
		if (texture == null || texture.isTexture != true) {
			throw new Error("TextureNode: Need a three.js texture.");
		}

		var textureProperty = super.generate(builder, "property");
		if (output == "sampler") {
			return textureProperty + "_sampler";
		} else if (builder.isReference(output)) {
			return textureProperty;
		} else {
			var nodeData = builder.getDataFromNode(this);
			var propertyName = nodeData.propertyName;
			if (propertyName == null) {
				var uvNode = properties.uvNode;
				var levelNode = properties.levelNode;
				var compareNode = properties.compareNode;
				var depthNode = properties.depthNode;
				var gradNode = properties.gradNode;
				var uvSnippet = this.generateUV(builder, uvNode);
				var levelSnippet = levelNode != null ? levelNode.build(builder, "float") : null;
				var depthSnippet = depthNode != null ? depthNode.build(builder, "int") : null;
				var compareSnippet = compareNode != null ? compareNode.build(builder, "float") : null;
				var gradSnippet = gradNode != null ? [gradNode[0].build(builder, "vec2"), gradNode[1].build(builder, "vec2")] : null;
				var nodeVar = builder.getVarFromNode(this);
				propertyName = builder.getPropertyName(nodeVar);
				var snippet = this.generateSnippet(builder, textureProperty, uvSnippet, levelSnippet, depthSnippet, compareSnippet, gradSnippet);
				builder.addLineFlowCode(propertyName + " = " + snippet);
				if (builder.context.tempWrite != false) {
					nodeData.snippet = snippet;
					nodeData.propertyName = propertyName;
				}
			}

			var snippet = propertyName;
			var nodeType = this.getNodeType(builder);
			if (builder.needsColorSpaceToLinear(texture)) {
				snippet = ColorSpaceNode.colorSpaceToLinear(ExpressionNode.expression(snippet, nodeType), texture.colorSpace).setup(builder).build(builder, nodeType);
			}

			return builder.format(snippet, nodeType, output);
		}
	}

	public function setSampler(value:Bool):TextureNode {
		this.sampler = value;
		return this;
	}

	public function getSampler():Bool {
		return this.sampler;
	}

	public function uv(uvNode:UVNode):ShaderNode.ShaderNode {
		var textureNode = this.clone();
		textureNode.uvNode = uvNode;
		textureNode.referenceNode = this;
		return ShaderNode.nodeObject(textureNode);
	}

	public function blur(levelNode:Node):ShaderNode.ShaderNode {
		var textureNode = this.clone();
		textureNode.levelNode = levelNode.mul(MaxMipLevelNode.maxMipLevel(textureNode));
		textureNode.referenceNode = this;
		return ShaderNode.nodeObject(textureNode);
	}

	public function level(levelNode:Node):TextureNode {
		var textureNode = this.clone();
		textureNode.levelNode = levelNode;
		textureNode.referenceNode = this;
		return textureNode;
	}

	public function size(levelNode:Node):TextureSizeNode {
		return TextureSizeNode.textureSize(this, levelNode);
	}

	public function compare(compareNode:Node):ShaderNode.ShaderNode {
		var textureNode = this.clone();
		textureNode.compareNode = ShaderNode.nodeObject(compareNode);
		textureNode.referenceNode = this;
		return ShaderNode.nodeObject(textureNode);
	}

	public function grad(gradNodeX:Node, gradNodeY:Node):ShaderNode.ShaderNode {
		var textureNode = this.clone();
		textureNode.gradNode = [ShaderNode.nodeObject(gradNodeX), ShaderNode.nodeObject(gradNodeY)];
		textureNode.referenceNode = this;
		return ShaderNode.nodeObject(textureNode);
	}

	public function depth(depthNode:Node):ShaderNode.ShaderNode {
		var textureNode = this.clone();
		textureNode.depthNode = ShaderNode.nodeObject(depthNode);
		textureNode.referenceNode = this;
		return ShaderNode.nodeObject(textureNode);
	}

	public function serialize(data:Dynamic) {
		super.serialize(data);
		data.value = this.value.toJSON(data.meta).uuid;
	}

	public function deserialize(data:Dynamic) {
		super.deserialize(data);
		this.value = data.meta.textures[data.value];
	}

	public function update() {
		var texture = this.value;
		if (texture.matrixAutoUpdate == true) {
			texture.updateMatrix();
		}
	}

	public function clone():TextureNode {
		var newNode = new TextureNode(this.value, this.uvNode, this.levelNode);
		newNode.sampler = this.sampler;
		return newNode;
	}
}

export default TextureNode;

export var texture = ShaderNode.nodeProxy(TextureNode);

export function textureLoad(params:Array<Dynamic>):ShaderNode.ShaderNode {
	return texture(params[0]).setSampler(false);
}

export function sampler(aTexture:Dynamic):ShaderNode.ShaderNode {
	return (aTexture.isNode == true ? aTexture : texture(aTexture)).convert("sampler");
}

ShaderNode.addNodeElement("texture", texture);
ShaderNode.addNodeClass("TextureNode", TextureNode);