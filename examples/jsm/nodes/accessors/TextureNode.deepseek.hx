import three.js.examples.jsm.nodes.core.UniformNode;
import three.js.examples.jsm.nodes.accessors.UVNode.uv;
import three.js.examples.jsm.nodes.accessors.TextureSizeNode.textureSize;
import three.js.examples.jsm.display.ColorSpaceNode.colorSpaceToLinear;
import three.js.examples.jsm.code.ExpressionNode.expression;
import three.js.examples.jsm.core.Node.addNodeClass;
import three.js.examples.jsm.utils.MaxMipLevelNode.maxMipLevel;
import three.js.examples.jsm.shadernode.ShaderNode.*;
import three.js.examples.jsm.core.constants.NodeUpdateType;

class TextureNode extends UniformNode {

	public function new(value, uvNode = null, levelNode = null) {
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

	public function set value(value) {
		if (this.referenceNode) {
			this.referenceNode.value = value;
		} else {
			this._value = value;
		}
	}

	public function get value() {
		return this.referenceNode ? this.referenceNode.value : this._value;
	}

	public function getUniformHash(/*builder*/) {
		return this.value.uuid;
	}

	public function getNodeType(/*builder*/) {
		if (this.value.isDepthTexture == true) return 'float';
		return 'vec4';
	}

	public function getInputType(/*builder*/) {
		return 'texture';
	}

	public function getDefaultUV() {
		return uv(this.value.channel);
	}

	public function updateReference(/*state*/) {
		return this.value;
	}

	public function getTransformedUV(uvNode) {
		var texture = this.value;
		return uniform(texture.matrix).mul(vec3(uvNode, 1)).xy;
	}

	public function setUpdateMatrix(value) {
		this.updateMatrix = value;
		this.updateType = value ? NodeUpdateType.FRAME : NodeUpdateType.NONE;
		return this;
	}

	public function setupUV(builder, uvNode) {
		var texture = this.value;
		if (builder.isFlipY() && (texture.isRenderTargetTexture == true || texture.isFramebufferTexture == true || texture.isDepthTexture == true)) {
			uvNode = uvNode.setY(uvNode.y.oneMinus());
		}
		return uvNode;
	}

	public function setup(builder) {
		var properties = builder.getNodeProperties(this);

		var uvNode = this.uvNode;
		if ((uvNode == null || builder.context.forceUVContext == true) && builder.context.getUV) {
			uvNode = builder.context.getUV(this);
		}
		if (uvNode == null) uvNode = this.getDefaultUV();
		if (this.updateMatrix == true) {
			uvNode = this.getTransformedUV(uvNode);
		}
		uvNode = this.setupUV(builder, uvNode);

		var levelNode = this.levelNode;
		if (levelNode == null && builder.context.getTextureLevel) {
			levelNode = builder.context.getTextureLevel(this);
		}

		properties.uvNode = uvNode;
		properties.levelNode = levelNode;
		properties.compareNode = this.compareNode;
		properties.gradNode = this.gradNode;
		properties.depthNode = this.depthNode;
	}

	public function generateUV(builder, uvNode) {
		return uvNode.build(builder, this.sampler == true ? 'vec2' : 'ivec2');
	}

	public function generateSnippet(builder, textureProperty, uvSnippet, levelSnippet, depthSnippet, compareSnippet, gradSnippet) {
		var texture = this.value;
		var snippet;
		if (levelSnippet) {
			snippet = builder.generateTextureLevel(texture, textureProperty, uvSnippet, levelSnippet, depthSnippet);
		} else if (gradSnippet) {
			snippet = builder.generateTextureGrad(texture, textureProperty, uvSnippet, gradSnippet, depthSnippet);
		} else if (compareSnippet) {
			snippet = builder.generateTextureCompare(texture, textureProperty, uvSnippet, compareSnippet, depthSnippet);
		} else if (this.sampler == false) {
			snippet = builder.generateTextureLoad(texture, textureProperty, uvSnippet, depthSnippet);
		} else {
			snippet = builder.generateTexture(texture, textureProperty, uvSnippet, depthSnippet);
		}
		return snippet;
	}

	public function generate(builder, output) {
		var properties = builder.getNodeProperties(this);

		var texture = this.value;
		if (texture == null || texture.isTexture != true) {
			throw 'TextureNode: Need a three.js texture.';
		}

		var textureProperty = super.generate(builder, 'property');

		if (output == 'sampler') {
			return textureProperty + '_sampler';
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
				var levelSnippet = levelNode ? levelNode.build(builder, 'float') : null;
				var depthSnippet = depthNode ? depthNode.build(builder, 'int') : null;
				var compareSnippet = compareNode ? compareNode.build(builder, 'float') : null;
				var gradSnippet = gradNode ? [gradNode[0].build(builder, 'vec2'), gradNode[1].build(builder, 'vec2')] : null;

				var nodeVar = builder.getVarFromNode(this);

				propertyName = builder.getPropertyName(nodeVar);

				var snippet = this.generateSnippet(builder, textureProperty, uvSnippet, levelSnippet, depthSnippet, compareSnippet, gradSnippet);

				builder.addLineFlowCode(propertyName + ' = ' + snippet);

				if (builder.context.tempWrite != false) {
					nodeData.snippet = snippet;
					nodeData.propertyName = propertyName;
				}
			}

			var snippet = propertyName;
			var nodeType = this.getNodeType(builder);

			if (builder.needsColorSpaceToLinear(texture)) {
				snippet = colorSpaceToLinear(expression(snippet, nodeType), texture.colorSpace).setup(builder).build(builder, nodeType);
			}

			return builder.format(snippet, nodeType, output);
		}
	}

	public function setSampler(value) {
		this.sampler = value;
		return this;
	}

	public function getSampler() {
		return this.sampler;
	}

	public function uv(uvNode) {
		var textureNode = this.clone();
		textureNode.uvNode = uvNode;
		textureNode.referenceNode = this;
		return nodeObject(textureNode);
	}

	public function blur(levelNode) {
		var textureNode = this.clone();
		textureNode.levelNode = levelNode.mul(maxMipLevel(textureNode));
		textureNode.referenceNode = this;
		return nodeObject(textureNode);
	}

	public function level(levelNode) {
		var textureNode = this.clone();
		textureNode.levelNode = levelNode;
		textureNode.referenceNode = this;
		return textureNode;
	}

	public function size(levelNode) {
		return textureSize(this, levelNode);
	}

	public function compare(compareNode) {
		var textureNode = this.clone();
		textureNode.compareNode = nodeObject(compareNode);
		textureNode.referenceNode = this;
		return nodeObject(textureNode);
	}

	public function grad(gradNodeX, gradNodeY) {
		var textureNode = this.clone();
		textureNode.gradNode = [nodeObject(gradNodeX), nodeObject(gradNodeY)];
		textureNode.referenceNode = this;
		return nodeObject(textureNode);
	}

	public function depth(depthNode) {
		var textureNode = this.clone();
		textureNode.depthNode = nodeObject(depthNode);
		textureNode.referenceNode = this;
		return nodeObject(textureNode);
	}

	public function serialize(data) {
		super.serialize(data);
		data.value = this.value.toJSON(data.meta).uuid;
	}

	public function deserialize(data) {
		super.deserialize(data);
		this.value = data.meta.textures[data.value];
	}

	public function update() {
		var texture = this.value;
		if (texture.matrixAutoUpdate == true) {
			texture.updateMatrix();
		}
	}

	public function clone() {
		var newNode = new TextureNode(this.value, this.uvNode, this.levelNode);
		newNode.sampler = this.sampler;
		return newNode;
	}
}

@:native('texture') static function texture(value, uvNode = null, levelNode = null) {
	return new TextureNode(value, uvNode, levelNode);
}

@:native('textureLoad') static function textureLoad(...params) {
	return texture(...params).setSampler(false);
}

@:native('sampler') static function sampler(aTexture) {
	return (aTexture.isNode == true ? aTexture : texture(aTexture)).convert('sampler');
}

addNodeElement('texture', texture);
addNodeClass('TextureNode', TextureNode);