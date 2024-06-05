import three.Material;
import three.Texture;
import three.CubeTexture;
import three.Object3D;
import three.SkinnedMesh;
import three.BatchedMesh;
import three.InstancedBufferAttribute;
import three.BufferAttribute;
import three.Color;
import three.Vector3;
import three.Vector4;
import three.Matrix4;
import three.Geometry;
import three.Renderer;
import three.ClippingContext;
import three.ShaderNode;
import three.ShaderNodeBuilder;
import three.ShaderNodeUtils;
import three.PropertyNode;
import three.AttributeNode;
import three.InputNode;
import three.OutputNode;
import three.FunctionNode;
import three.StructNode;
import three.VaryingPropertyNode;
import three.MaterialReferenceNode;
import three.ModelViewProjectionNode;
import three.NormalNode;
import three.InstanceNode;
import three.BatchNode;
import three.PositionNode;
import three.SkinningNode;
import three.MorphNode;
import three.TextureNode;
import three.CubeTextureNode;
import three.LightsNode;
import three.MathNode;
import three.LightingContextNode;
import three.EnvironmentNode;
import three.IrradianceNode;
import three.AONode;
import three.ViewportDepthNode;
import three.CameraNode;
import three.ClippingNode;
import three.FrontFacingNode;

class NodeMaterial extends Material {
	public var isNodeMaterial:Bool = true;
	public var type:String = "NodeMaterial";
	public var forceSinglePass:Bool = false;
	public var fog:Bool = true;
	public var lights:Bool = true;
	public var normals:Bool = true;
	public var lightsNode:LightsNode;
	public var envNode:EnvironmentNode;
	public var aoNode:AONode;
	public var colorNode:InputNode;
	public var normalNode:InputNode;
	public var opacityNode:InputNode;
	public var backdropNode:InputNode;
	public var backdropAlphaNode:InputNode;
	public var alphaTestNode:InputNode;
	public var positionNode:InputNode;
	public var depthNode:InputNode;
	public var shadowNode:InputNode;
	public var shadowPositionNode:InputNode;
	public var outputNode:OutputNode;
	public var fragmentNode:InputNode;
	public var vertexNode:InputNode;

	public function new() {
		super();
	}

	public function customProgramCacheKey():String {
		return this.type + ShaderNodeUtils.getCacheKey(this);
	}

	public function build(builder:ShaderNodeBuilder) {
		this.setup(builder);
	}

	public function setup(builder:ShaderNodeBuilder) {
		builder.addStack();
		builder.stack.outputNode = this.vertexNode != null ? this.vertexNode : this.setupPosition(builder);
		builder.addFlow("vertex", builder.removeStack());

		builder.addStack();
		var resultNode:OutputNode;
		var clippingNode:InputNode = this.setupClipping(builder);
		if (this.depthWrite) this.setupDepth(builder);
		if (this.fragmentNode == null) {
			if (this.normals) this.setupNormal(builder);
			this.setupDiffuseColor(builder);
			this.setupVariants(builder);
			var outgoingLightNode:InputNode = this.setupLighting(builder);
			if (clippingNode != null) builder.stack.add(clippingNode);
			var basicOutput:InputNode = ShaderNode.vec4(outgoingLightNode, PropertyNode.diffuseColor.a).max(0);
			resultNode = this.setupOutput(builder, basicOutput);
			PropertyNode.output.assign(resultNode);
			if (this.outputNode != null) resultNode = this.outputNode;
		} else {
			var fragmentNode:InputNode = this.fragmentNode;
			if (!fragmentNode.isOutputStructNode) {
				fragmentNode = ShaderNode.vec4(fragmentNode);
			}
			resultNode = this.setupOutput(builder, fragmentNode);
		}
		builder.stack.outputNode = resultNode;
		builder.addFlow("fragment", builder.removeStack());
	}

	public function setupClipping(builder:ShaderNodeBuilder):InputNode {
		if (builder.clippingContext == null) return null;
		var globalClippingCount:Int = builder.clippingContext.globalClippingCount;
		var localClippingCount:Int = builder.clippingContext.localClippingCount;
		var result:InputNode = null;
		if (globalClippingCount || localClippingCount) {
			if (this.alphaToCoverage) {
				result = ClippingNode.clippingAlpha();
			} else {
				builder.stack.add(ClippingNode.clipping());
			}
		}
		return result;
	}

	public function setupDepth(builder:ShaderNodeBuilder) {
		var renderer:Renderer = builder.renderer;
		var depthNode:InputNode = this.depthNode;
		if (depthNode == null && renderer.logarithmicDepthBuffer) {
			var fragDepth:InputNode = ModelViewProjectionNode.modelViewProjection().w.add(1);
			depthNode = fragDepth.log2().mul(CameraNode.cameraLogDepth).mul(0.5);
		}
		if (depthNode != null) {
			ViewportDepthNode.depthPixel.assign(depthNode).append();
		}
	}

	public function setupPosition(builder:ShaderNodeBuilder):OutputNode {
		var object:Object3D = builder.object;
		var geometry:Geometry = object.geometry;
		builder.addStack();
		if (geometry.morphAttributes.position != null || geometry.morphAttributes.normal != null || geometry.morphAttributes.color != null) {
			MorphNode.morphReference(object).append();
		}
		if (cast object : SkinnedMesh) {
			SkinningNode.skinningReference(object).append();
		}
		if (this.displacementMap != null) {
			var displacementMap:InputNode = MaterialReferenceNode.materialReference("displacementMap", "texture");
			var displacementScale:InputNode = MaterialReferenceNode.materialReference("displacementScale", "float");
			var displacementBias:InputNode = MaterialReferenceNode.materialReference("displacementBias", "float");
			PositionNode.positionLocal.addAssign(NormalNode.normalLocal.normalize().mul(displacementMap.x.mul(displacementScale).add(displacementBias)));
		}
		if (cast object : BatchedMesh) {
			BatchNode.batch(object).append();
		}
		if ((object.instanceMatrix != null && cast object.instanceMatrix : InstancedBufferAttribute) && builder.isAvailable("instance")) {
			InstanceNode.instance(object).append();
		}
		if (this.positionNode != null) {
			PositionNode.positionLocal.assign(this.positionNode);
		}
		var mvp:OutputNode = ModelViewProjectionNode.modelViewProjection();
		builder.context.vertex = builder.removeStack();
		builder.context.mvp = mvp;
		return mvp;
	}

	public function setupDiffuseColor(builder:ShaderNodeBuilder) {
		var object:Object3D = builder.object;
		var geometry:Geometry = object.geometry;
		var colorNode:InputNode = this.colorNode != null ? ShaderNode.vec4(this.colorNode) : MaterialReferenceNode.materialColor;
		if (this.vertexColors && geometry.hasAttribute("color")) {
			colorNode = ShaderNode.vec4(colorNode.xyz.mul(AttributeNode.attribute("color", "vec3")), colorNode.a);
		}
		if (object.instanceColor != null) {
			var instanceColor:InputNode = VaryingPropertyNode.varyingProperty("vec3", "vInstanceColor");
			colorNode = instanceColor.mul(colorNode);
		}
		PropertyNode.diffuseColor.assign(colorNode);
		var opacityNode:InputNode = this.opacityNode != null ? ShaderNode.float(this.opacityNode) : MaterialReferenceNode.materialOpacity;
		PropertyNode.diffuseColor.a.assign(PropertyNode.diffuseColor.a.mul(opacityNode));
		if (this.alphaTestNode != null || this.alphaTest > 0) {
			var alphaTestNode:InputNode = this.alphaTestNode != null ? ShaderNode.float(this.alphaTestNode) : MaterialReferenceNode.materialAlphaTest;
			PropertyNode.diffuseColor.a.lessThanEqual(alphaTestNode).discard();
		}
	}

	public function setupVariants(builder:ShaderNodeBuilder) {
	}

	public function setupNormal(builder:ShaderNodeBuilder) {
		if (this.flatShading) {
			var normalNode:InputNode = PositionNode.positionView.dFdx().cross(PositionNode.positionView.dFdy()).normalize();
			NormalNode.transformedNormalView.assign(normalNode.mul(FrontFacingNode.faceDirection));
		} else {
			var normalNode:InputNode = this.normalNode != null ? ShaderNode.vec3(this.normalNode) : MaterialReferenceNode.materialNormal;
			NormalNode.transformedNormalView.assign(normalNode.mul(FrontFacingNode.faceDirection));
		}
	}

	public function getEnvNode(builder:ShaderNodeBuilder):EnvironmentNode {
		var node:EnvironmentNode = null;
		if (this.envNode != null) {
			node = this.envNode;
		} else if (this.envMap != null) {
			node = cast this.envMap : CubeTexture ? CubeTextureNode.cubeTexture(this.envMap) : TextureNode.texture(this.envMap);
		} else if (builder.environmentNode != null) {
			node = builder.environmentNode;
		}
		return node;
	}

	public function setupLights(builder:ShaderNodeBuilder):LightsNode {
		var envNode:EnvironmentNode = this.getEnvNode(builder);
		var materialLightsNode:Array<EnvironmentNode> = [];
		if (envNode != null) {
			materialLightsNode.push(new EnvironmentNode(envNode));
		}
		if (builder.material.lightMap != null) {
			materialLightsNode.push(new IrradianceNode(MaterialReferenceNode.materialReference("lightMap", "texture")));
		}
		if (this.aoNode != null || builder.material.aoMap != null) {
			var aoNode:InputNode = this.aoNode != null ? this.aoNode : TextureNode.texture(builder.material.aoMap);
			materialLightsNode.push(new AONode(aoNode));
		}
		var lightsN:LightsNode = this.lightsNode != null ? this.lightsNode : builder.lightsNode;
		if (materialLightsNode.length > 0) {
			lightsN = new LightsNode([for (n in lightsN.lightNodes) n, for (n in materialLightsNode) n]);
		}
		return lightsN;
	}

	public function setupLightingModel(builder:ShaderNodeBuilder) {
	}

	public function setupLighting(builder:ShaderNodeBuilder):InputNode {
		var material:Material = builder.material;
		var backdropNode:InputNode = this.backdropNode;
		var backdropAlphaNode:InputNode = this.backdropAlphaNode;
		var emissiveNode:InputNode = this.emissiveNode;
		var lights:Bool = this.lights || this.lightsNode != null;
		var lightsNode:LightsNode = lights ? this.setupLights(builder) : null;
		var outgoingLightNode:InputNode = PropertyNode.diffuseColor.rgb;
		if (lightsNode != null && !lightsNode.hasLight) {
			var lightingModel:InputNode = this.setupLightingModel(builder);
			outgoingLightNode = LightingContextNode.lightingContext(lightsNode, lightingModel, backdropNode, backdropAlphaNode);
		} else if (backdropNode != null) {
			outgoingLightNode = ShaderNode.vec3(backdropAlphaNode != null ? MathNode.mix(outgoingLightNode, backdropNode, backdropAlphaNode) : backdropNode);
		}
		if ((emissiveNode != null && emissiveNode.isNode) || (material.emissive != null && cast material.emissive : Color)) {
			outgoingLightNode = outgoingLightNode.add(ShaderNode.vec3(emissiveNode != null ? emissiveNode : MaterialReferenceNode.materialEmissive));
		}
		return outgoingLightNode;
	}

	public function setupOutput(builder:ShaderNodeBuilder, outputNode:InputNode):OutputNode {
		var fogNode:InputNode = builder.fogNode;
		if (fogNode != null) outputNode = ShaderNode.vec4(fogNode.mix(outputNode.rgb, fogNode.colorNode), outputNode.a);
		return outputNode;
	}

	public function setDefaultValues(material:Material) {
		for (property in material) {
			var value = material[property];
			if (this[property] == null) {
				this[property] = value;
				if (value != null && value.clone != null) this[property] = value.clone();
			}
		}
		var descriptors:Map<String, {get:Dynamic, set:Dynamic}> = Reflect.getPropertyDescriptors(material.getType().prototype);
		for (key in descriptors) {
			if (Reflect.getPropertyDescriptor(this.getType().prototype, key) == null && descriptors[key].get != null) {
				Reflect.setProperty(this.getType().prototype, key, descriptors[key]);
			}
		}
	}

	public function toJSON(meta:Dynamic = null):Dynamic {
		var isRoot:Bool = meta == null || Type.typeof(meta) == TString;
		if (isRoot) {
			meta = {
				textures: {},
				images: {},
				nodes: {}
			};
		}
		var data:Dynamic = Material.prototype.toJSON.call(this, meta);
		var nodeChildren:Array<{property:String, childNode:InputNode}> = ShaderNodeUtils.getNodeChildren(this);
		data.inputNodes = {};
		for (child in nodeChildren) {
			data.inputNodes[child.property] = child.childNode.toJSON(meta).uuid;
		}
		function extractFromCache(cache:Map<String, Dynamic>):Array<Dynamic> {
			var values:Array<Dynamic> = [];
			for (key in cache) {
				var data:Dynamic = cache[key];
				Reflect.deleteProperty(data, "metadata");
				values.push(data);
			}
			return values;
		}
		if (isRoot) {
			var textures:Array<Dynamic> = extractFromCache(meta.textures);
			var images:Array<Dynamic> = extractFromCache(meta.images);
			var nodes:Array<Dynamic> = extractFromCache(meta.nodes);
			if (textures.length > 0) data.textures = textures;
			if (images.length > 0) data.images = images;
			if (nodes.length > 0) data.nodes = nodes;
		}
		return data;
	}

	public function copy(source:NodeMaterial):NodeMaterial {
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
		super.copy(source);
		return this;
	}

	public static function fromMaterial(material:Material):NodeMaterial {
		if (material.isNodeMaterial) {
			return material;
		}
		var type:String = material.type.replace("Material", "NodeMaterial");
		var nodeMaterial:NodeMaterial = createNodeMaterialFromType(type);
		if (nodeMaterial == null) {
			throw new Error("NodeMaterial: Material \"" + material.type + "\" is not compatible.");
		}
		for (key in material) {
			nodeMaterial[key] = material[key];
		}
		return nodeMaterial;
	}
}

var NodeMaterials:Map<String, Class<NodeMaterial>> = new Map();

function addNodeMaterial(type:String, nodeMaterial:Class<NodeMaterial>) {
	if (Type.typeof(nodeMaterial) != TClass || type == null) throw new Error("Node material " + type + " is not a class");
	if (NodeMaterials.exists(type)) {
		Sys.println("Redefinition of node material " + type);
		return;
	}
	NodeMaterials.set(type, nodeMaterial);
	nodeMaterial.prototype.type = type;
}

function createNodeMaterialFromType(type:String):NodeMaterial {
	var Material:Class<NodeMaterial> = NodeMaterials.get(type);
	if (Material != null) {
		return new Material();
	}
	return null;
}

addNodeMaterial("NodeMaterial", NodeMaterial);