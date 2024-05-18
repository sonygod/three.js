import three.materials.Material;
import three.nodes.core.NodeUtils;
import three.nodes.core.AttributeNode;
import three.nodes.core.PropertyNode;
import three.nodes.accessors.MaterialNode;
import three.nodes.accessors.ModelViewProjectionNode;
import three.nodes.accessors.NormalNode;
import three.nodes.accessors.InstanceNode;
import three.nodes.accessors.BatchNode;
import three.nodes.accessors.MaterialReferenceNode;
import three.nodes.accessors.PositionNode;
import three.nodes.accessors.SkinningNode;
import three.nodes.accessors.MorphNode;
import three.nodes.accessors.TextureNode;
import three.nodes.accessors.CubeTextureNode;
import three.nodes.lighting.LightsNode;
import three.nodes.math.MathNode;
import three.nodes.shadernode.ShaderNode;
import three.nodes.lighting.AONode;
import three.nodes.lighting.LightingContextNode;
import three.nodes.lighting.EnvironmentNode;
import three.nodes.lighting.IrradianceNode;
import three.nodes.display.ViewportDepthNode;
import three.nodes.accessors.CameraNode;
import three.nodes.accessors.ClippingNode;
import three.nodes.display.FrontFacingNode;

class NodeMaterial extends Material {

	public var isNodeMaterial:Bool;
	public var type:String;
	public var forceSinglePass:Bool;
	public var fog:Bool;
	public var lights:Bool;
	public var normals:Bool;
	public var lightsNode:LightsNode;
	public var envNode:EnvironmentNode;
	public var aoNode:AONode;
	public var colorNode:ShaderNode;
	public var normalNode:ShaderNode;
	public var opacityNode:ShaderNode;
	public var backdropNode:ShaderNode;
	public var backdropAlphaNode:ShaderNode;
	public var alphaTestNode:ShaderNode;
	public var positionNode:ShaderNode;
	public var depthNode:ShaderNode;
	public var shadowNode:ShaderNode;
	public var shadowPositionNode:ShaderNode;
	public var outputNode:ShaderNode;
	public var fragmentNode:ShaderNode;
	public var vertexNode:ShaderNode;

	public function new() {
		super();
		this.isNodeMaterial = true;
		this.type = this.constructor.type;
		this.forceSinglePass = false;
		this.fog = true;
		this.lights = true;
		this.normals = true;
		this.lightsNode = null;
		this.envNode = null;
		this.aoNode = null;
		this.colorNode = null;
		this.normalNode = null;
		this.opacityNode = null;
		this.backdropNode = null;
		this.backdropAlphaNode = null;
		this.alphaTestNode = null;
		this.positionNode = null;
		this.depthNode = null;
		this.shadowNode = null;
		this.shadowPositionNode = null;
		this.outputNode = null;
		this.fragmentNode = null;
		this.vertexNode = null;
	}

	public function customProgramCacheKey():String {
		return this.type + NodeUtils.getCacheKey(this);
	}

	public function build(builder:Dynamic) {
		this.setup(builder);
	}

	public function setup(builder:Dynamic) {
		// < VERTEX STAGE >
		builder.addStack();
		builder.stack.outputNode = this.vertexNode != null ? this.setupPosition(builder) : this.setupPosition(builder);
		builder.addFlow('vertex', builder.removeStack());

		// < FRAGMENT STAGE >
		builder.addStack();
		var resultNode:ShaderNode;
		var clippingNode:ShaderNode = this.setupClipping(builder);
		if (this.depthWrite === true) this.setupDepth(builder);
		if (this.fragmentNode === null) {
			if (this.normals === true) this.setupNormal(builder);
			this.setupDiffuseColor(builder);
			this.setupVariants(builder);
			var outgoingLightNode:ShaderNode = this.setupLighting(builder);
			if (clippingNode != null) builder.stack.add(clippingNode);
			// force unsigned floats - useful for RenderTargets
			var basicOutput:ShaderNode = ShaderNode.vec4(outgoingLightNode, diffuseColor.a).max(0);
			resultNode = this.setupOutput(builder, basicOutput);
			// OUTPUT NODE
			output.assign(resultNode);
			//
			if (this.outputNode != null) resultNode = this.outputNode;
		} else {
			var fragmentNode:ShaderNode = this.fragmentNode;
			if (fragmentNode.isOutputStructNode !== true) {
				fragmentNode = ShaderNode.vec4(fragmentNode);
			}
			resultNode = this.setupOutput(builder, fragmentNode);
		}
		builder.stack.outputNode = resultNode;
		builder.addFlow('fragment', builder.removeStack());
	}

	public function setupClipping(builder:Dynamic):ShaderNode {
		if (builder.clippingContext == null) return null;
		var { globalClippingCount, localClippingCount } = builder.clippingContext;
		var result:ShaderNode = null;
		if (globalClippingCount || localClippingCount) {
			if (this.alphaToCoverage) {
				// to be added to flow when the color/alpha value has been determined
				result = clippingAlpha();
			} else {
				builder.stack.add(clipping());
			}
		}
		return result;
	}

	public function setupDepth(builder:Dynamic) {
		const { renderer } = builder;
		// Depth
		var depthNode:ShaderNode = null;
		if (depthNode === null && renderer.logarithmicDepthBuffer === true) {
			var fragDepth:ShaderNode = modelViewProjection().w.add(1);
			depthNode = fragDepth.log2().mul(cameraLogDepth).mul(0.5);
		}
		if (depthNode !== null) {
			depthPixel.assign(depthNode).append();
		}
	}

	public function setupPosition(builder:Dynamic):ShaderNode {
		var { object, geometry } = builder;
		builder.addStack();
		// Vertex
		if (geometry.morphAttributes.position != null || geometry.morphAttributes.normal != null || geometry.morphAttributes.color != null) {
			morphReference(object).append();
		}
		if (object.isSkinnedMesh === true) {
			skinningReference(object).append();
		}
		if (this.displacementMap != null) {
			var displacementMap:ShaderNode = materialReference('displacementMap', 'texture');
			var displacementScale:ShaderNode = materialReference('displacementScale', 'float');
			var displacementBias:ShaderNode = materialReference('displacementBias', 'float');
			positionLocal.addAssign(normalLocal.normalize().mul((displacementMap.x.mul(displacementScale).add(displacementBias))));
		}
		if (object.isBatchedMesh) {
			batch(object).append();
		}
		if (
			(object.instanceMatrix != null && object.instanceMatrix.isInstancedBufferAttribute === true) &&
			builder.isAvailable('instance') === true
		) {
			instance(object).append();
		}
		if (this.positionNode != null) {
			positionLocal.assign(this.positionNode);
		}
		var mvp:ShaderNode = modelViewProjection();
		builder.context.vertex = builder.removeStack();
		builder.context.mvp = mvp;
		return mvp;
	}

	public function setupDiffuseColor(builder:Dynamic) {
		var { object, geometry } = builder;
		let colorNode:ShaderNode = this.colorNode != null ? ShaderNode.vec4(this.colorNode) : materialColor;
		// VERTEX COLORS
		if (this.vertexColors === true && geometry.hasAttribute('color')) {
			colorNode = ShaderNode.vec4(colorNode.xyz.mul(attribute('color', 'vec3')), colorNode.a);
		}
		// Instanced colors
		if (object.instanceColor) {
			var instanceColor:ShaderNode = varyingProperty('vec3', 'vInstanceColor');
			colorNode = instanceColor.mul(colorNode);
		}
		// COLOR
		diffuseColor.assign(colorNode);
		// OPACITY
		var opacityNode:ShaderNode = this.opacityNode != null ? ShaderNode.float(this.opacityNode) : materialOpacity;
		diffuseColor.a.assign(diffuseColor.a.mul(opacityNode));
		// ALPHA TEST
		if (this.alphaTestNode != null || this.alphaTest > 0) {
			var alphaTestNode:ShaderNode = this.alphaTestNode != null ? ShaderNode.float(this.alphaTestNode) : materialAlphaTest;
			diffuseColor.a.lessThanEqual(alphaTestNode).discard();
		}
	}

	public function setupVariants(builder:Dynamic) {
		// Interface function.
	}

	public function setupNormal() {
		// NORMAL VIEW
		if (this.flatShading === true) {
			var normalNode:ShaderNode = positionView.dFdx().cross(positionView.dFdy()).normalize();
			transformedNormalView.assign(normalNode.mul(faceDirection));
		} else {
			var normalNode:ShaderNode = this.normalNode != null ? ShaderNode.vec3(this.normalNode) : materialNormal;
			transformedNormalView.assign(normalNode.mul(faceDirection));
		}
	}

	public function getEnvNode(builder:Dynamic):ShaderNode {
		var node:ShaderNode = null;
		if (this.envNode) {
			node = this.envNode;
		} else if (this.envMap) {
			node = this.envMap.isCubeTexture ? cubeTexture(this.envMap) : texture(this.envMap);
		} else if (builder.environmentNode) {
			node = builder.environmentNode;
		}
		return node;
	}

	public function setupLights(builder:Dynamic):LightsNode {
		var envNode:ShaderNode = this.getEnvNode(builder);
		//
		var materialLightsNode:Array<LightsNode> = [];
		if (envNode) {
			materialLightsNode.push(new EnvironmentNode(envNode));
		}
		if (builder.material.lightMap) {
			materialLightsNode.push(new IrradianceNode(materialReference('lightMap', 'texture')));
		}
		if (this.aoNode != null || builder.material.aoMap) {
			var aoNode:ShaderNode = this.aoNode != null ? this.aoNode : texture(builder.material.aoMap);
			materialLightsNode.push(new AONode(aoNode));
		}
		var lightsN:LightsNode = this.lightsNode != null ? this.lightsNode : builder.lightsNode;
		if (materialLightsNode.length > 0) {
			lightsN = lightsNode(materialLightsNode);
		}
		return lightsN;
	}

	public function setupLightingModel(builder:Dynamic) {
		// Interface function.
	}

	public function setupLighting(builder:Dynamic):ShaderNode {
		var { material } = builder;
		var { backdropNode, backdropAlphaNode, emissiveNode } = this;
		// OUTGOING LIGHT
		var lights:Bool = this.lights === true || this.lightsNode != null;
		var lightsNode:LightsNode = lights ? this.setupLights(builder) : null;
		var outgoingLightNode:ShaderNode = diffuseColor.rgb;
		if (lightsNode != null && lightsNode.hasLight !== false) {
			var lightingModel:ShaderNode = this.setupLightingModel(builder);
			outgoingLightNode = lightingContext(lightsNode, lightingModel, backdropNode, backdropAlphaNode);
		} else if (backdropNode != null) {
			outgoingLightNode = ShaderNode.vec3(backdropAlphaNode != null ? ShaderNode.mix(outgoingLightNode, backdropNode, backdropAlphaNode) : backdropNode);
		}
		// EMISSIVE
		if (
			(emissiveNode != null && emissiveNode.isNode === true) ||
			(material.emissive != null && material.emissive.isColor === true)
		) {
			outgoingLightNode = outgoingLightNode.add(ShaderNode.vec3(emissiveNode != null ? emissiveNode : materialEmissive));
		}
		return outgoingLightNode;
	}

	public function setupOutput(builder:Dynamic, outputNode:ShaderNode):ShaderNode {
		// FOG
		var fogNode:ShaderNode = builder.fogNode;
		if (fogNode) outputNode = ShaderNode.vec4(fogNode.mix(outputNode.rgb, fogNode.colorNode), outputNode.a);
		return outputNode;
	}

	public function setDefaultValues(material:Material) {
		// This approach is to reuse the native refreshUniforms*
		// and turn available the use of features like transmission and environment in core
		for (var property in material) {
			var value = material[property];
			if (this[property] === undefined) {
				this[property] = value;
				if (value != null && value.clone != null) this[property] = value.clone();
			}
		}
		var descriptors = Reflect.getOwnPropertyDescriptors(material.constructor.prototype);
		for (var key in descriptors) {
			if (
				Reflect.getOwnPropertyDescriptor(this.constructor.prototype, key) === undefined &&
				descriptors[key].get != null
			) {
				Reflect.defineProperty(this.constructor.prototype, key, descriptors[key]);
			}
		}
	}

	public function toJSON(meta:Dynamic) {
		var isRoot = (meta === undefined || typeof meta === 'string');
		if (isRoot) {
			meta = {
				textures: [],
				images: [],
				nodes: []
			};
		}
		var data = Material.prototype.toJSON.call(this, meta);
		var nodeChildren = NodeUtils.getNodeChildren(this);
		data.inputNodes = {};
		for (var { property, childNode } of nodeChildren) {
			data.inputNodes[property] = childNode.toJSON(meta).uuid;
		}
		// TODO: Copied from Object3D.toJSON
		function extractFromCache(cache) {
			var values = [];
			for (var key in cache) {
				var data = cache[key];
				delete data.metadata;
				values.push(data);
			}
			return values;
		}
		if (isRoot) {
			var textures = extractFromCache(meta.textures);
			var images = extractFromCache(meta.images);
			var nodes = extractFromCache(meta.nodes);
			if (textures.length > 0) data.textures = textures;
			if (images.length > 0) data.images = images;
			if (nodes.length > 0) data.nodes = nodes;
		}
		return data;
	}

	public function copy(source:Dynamic) {
		this.lightsNode = source.lightsNode;
		this.envNode = source.envNode;
		this.colorNode = source.colorNode;
		this.normalNode = source.normalNode;
		this.opacityNode = source.opacityNode;
		this.backdropNode = source.backdropNode;
		this.backdropAlphaNode = source.backdropAlphaNode;
		this.alphaTestNode = source.alphaTestNode;
		this.positionNode = source.positionNode;
		this.depthNode = source.depthNode;
		this.shadowNode = source.shadowNode;
		this.shadowPositionNode = source.shadowPositionNode;
		this.outputNode = source.outputNode;
		this.fragmentNode = source.fragmentNode;
		this.vertexNode = source.vertexNode;
		return super.copy(source);
	}

	public static function fromMaterial(material:Material):NodeMaterial {
		if (material.isNodeMaterial === true) { // is already a node material
			return material;
		}
		var type = material.type.replace('Material', 'NodeMaterial');
		var nodeMaterial = createNodeMaterialFromType(type);
		if (nodeMaterial === undefined) {
			throw new Error(`NodeMaterial: Material "${material.type}" is not compatible.`);
		}
		for (var key in material) {
			nodeMaterial[key] = material[key];
		}
		return nodeMaterial;
	}

}

function addNodeMaterial(type:String, nodeMaterial:Class<Dynamic>) {
	if (typeof nodeMaterial !== 'function' || !type) throw new Error(`Node material ${type} is not a class`);
	if (NodeMaterials.has(type)) {
		trace(`Redefinition of node material ${type}`);
		return;
	}
	NodeMaterials.set(type, nodeMaterial);
	nodeMaterial.type = type;
}

function createNodeMaterialFromType(type:String):Class<Dynamic> {
	const Material = NodeMaterials.get(type);
	if (Material != null) {
		return Type.getClass(Material);
	}
}

addNodeMaterial('NodeMaterial', NodeMaterial);