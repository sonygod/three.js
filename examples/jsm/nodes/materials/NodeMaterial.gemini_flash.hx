import three.Material;
import three.core.NodeUtils;
import three.core.AttributeNode;
import three.core.PropertyNode;
import three.accessors.MaterialNode;
import three.accessors.ModelViewProjectionNode;
import three.accessors.NormalNode;
import three.accessors.InstanceNode;
import three.accessors.BatchNode;
import three.accessors.MaterialReferenceNode;
import three.accessors.PositionNode;
import three.accessors.SkinningNode;
import three.accessors.MorphNode;
import three.accessors.TextureNode;
import three.accessors.CubeTextureNode;
import three.lighting.LightsNode;
import three.math.MathNode;
import three.shadernode.ShaderNode;
import three.lighting.AONode;
import three.lighting.LightingContextNode;
import three.lighting.EnvironmentNode;
import three.lighting.IrradianceNode;
import three.display.ViewportDepthNode;
import three.accessors.CameraNode;
import three.accessors.ClippingNode;
import three.display.FrontFacingNode;

class NodeMaterial extends Material {

	public var isNodeMaterial:Bool = true;

	public var type:String;

	public var forceSinglePass:Bool = false;

	public var fog:Bool = true;
	public var lights:Bool = true;
	public var normals:Bool = true;

	public var lightsNode:LightsNode = null;
	public var envNode:EnvironmentNode = null;
	public var aoNode:AONode = null;

	public var colorNode:ShaderNode = null;
	public var normalNode:ShaderNode = null;
	public var opacityNode:ShaderNode = null;
	public var backdropNode:ShaderNode = null;
	public var backdropAlphaNode:ShaderNode = null;
	public var alphaTestNode:ShaderNode = null;

	public var positionNode:ShaderNode = null;

	public var depthNode:ShaderNode = null;
	public var shadowNode:ShaderNode = null;
	public var shadowPositionNode:ShaderNode = null;

	public var outputNode:ShaderNode = null;

	public var fragmentNode:ShaderNode = null;
	public var vertexNode:ShaderNode = null;

	public function new() {
		super();
		this.type = this.constructor.type;
	}

	public function customProgramCacheKey():String {
		return this.type + NodeUtils.getCacheKey(this);
	}

	public function build(builder:Dynamic):Void {
		this.setup(builder);
	}

	public function setup(builder:Dynamic):Void {
		// < VERTEX STAGE >

		builder.addStack();
		builder.stack.outputNode = this.vertexNode || this.setupPosition(builder);

		builder.addFlow('vertex', builder.removeStack());

		// < FRAGMENT STAGE >

		builder.addStack();

		var resultNode:ShaderNode;

		var clippingNode:ShaderNode = this.setupClipping(builder);

		if (this.depthWrite) this.setupDepth(builder);

		if (this.fragmentNode == null) {

			if (this.normals) this.setupNormal(builder);

			this.setupDiffuseColor(builder);
			this.setupVariants(builder);

			var outgoingLightNode:ShaderNode = this.setupLighting(builder);

			if (clippingNode != null) builder.stack.add(clippingNode);

			// force unsigned floats - useful for RenderTargets

			var basicOutput:ShaderNode = ShaderNode.vec4(outgoingLightNode, PropertyNode.diffuseColor.a).max(0);

			resultNode = this.setupOutput(builder, basicOutput);

			// OUTPUT NODE

			PropertyNode.output.assign(resultNode);

			//

			if (this.outputNode != null) resultNode = this.outputNode;

		} else {

			var fragmentNode:ShaderNode = this.fragmentNode;

			if (!fragmentNode.isOutputStructNode) {

				fragmentNode = ShaderNode.vec4(fragmentNode);

			}

			resultNode = this.setupOutput(builder, fragmentNode);

		}

		builder.stack.outputNode = resultNode;

		builder.addFlow('fragment', builder.removeStack());
	}

	public function setupClipping(builder:Dynamic):ShaderNode {
		if (builder.clippingContext == null) return null;

		var {globalClippingCount, localClippingCount} = builder.clippingContext;

		var result:ShaderNode = null;

		if (globalClippingCount || localClippingCount) {

			if (this.alphaToCoverage) {

				// to be added to flow when the color/alpha value has been determined
				result = ClippingNode.clippingAlpha();

			} else {

				builder.stack.add(ClippingNode.clipping());

			}

		}

		return result;
	}

	public function setupDepth(builder:Dynamic):Void {
		var {renderer} = builder;

		// Depth

		var depthNode:ShaderNode = this.depthNode;

		if (depthNode == null && renderer.logarithmicDepthBuffer) {

			var fragDepth:ShaderNode = ModelViewProjectionNode.modelViewProjection().w.add(1);

			depthNode = fragDepth.log2().mul(CameraNode.cameraLogDepth).mul(0.5);

		}

		if (depthNode != null) {

			ViewportDepthNode.depthPixel.assign(depthNode).append();

		}
	}

	public function setupPosition(builder:Dynamic):ShaderNode {
		var {object} = builder;
		var geometry = object.geometry;

		builder.addStack();

		// Vertex

		if (geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color) {

			MorphNode.morphReference(object).append();

		}

		if (object.isSkinnedMesh) {

			SkinningNode.skinningReference(object).append();

		}

		if (this.displacementMap) {

			var displacementMap:ShaderNode = MaterialReferenceNode.materialReference('displacementMap', 'texture');
			var displacementScale:ShaderNode = MaterialReferenceNode.materialReference('displacementScale', 'float');
			var displacementBias:ShaderNode = MaterialReferenceNode.materialReference('displacementBias', 'float');

			PositionNode.positionLocal.addAssign(NormalNode.normalLocal.normalize().mul((displacementMap.x.mul(displacementScale).add(displacementBias))));

		}

		if (object.isBatchedMesh) {

			BatchNode.batch(object).append();

		}

		if ((object.instanceMatrix && object.instanceMatrix.isInstancedBufferAttribute) && builder.isAvailable('instance')) {

			InstanceNode.instance(object).append();

		}

		if (this.positionNode != null) {

			PositionNode.positionLocal.assign(this.positionNode);

		}

		var mvp:ShaderNode = ModelViewProjectionNode.modelViewProjection();

		builder.context.vertex = builder.removeStack();
		builder.context.mvp = mvp;

		return mvp;
	}

	public function setupDiffuseColor(builder:Dynamic):Void {
		var {object, geometry} = builder;

		var colorNode:ShaderNode = this.colorNode != null ? ShaderNode.vec4(this.colorNode) : MaterialNode.materialColor;

		// VERTEX COLORS

		if (this.vertexColors && geometry.hasAttribute('color')) {

			colorNode = ShaderNode.vec4(colorNode.xyz.mul(AttributeNode.attribute('color', 'vec3')), colorNode.a);

		}

		// Instanced colors

		if (object.instanceColor) {

			var instanceColor:ShaderNode = PropertyNode.varyingProperty('vec3', 'vInstanceColor');

			colorNode = instanceColor.mul(colorNode);

		}

		// COLOR

		PropertyNode.diffuseColor.assign(colorNode);

		// OPACITY

		var opacityNode:ShaderNode = this.opacityNode != null ? ShaderNode.float(this.opacityNode) : MaterialNode.materialOpacity;
		PropertyNode.diffuseColor.a.assign(PropertyNode.diffuseColor.a.mul(opacityNode));

		// ALPHA TEST

		if (this.alphaTestNode != null || this.alphaTest > 0) {

			var alphaTestNode:ShaderNode = this.alphaTestNode != null ? ShaderNode.float(this.alphaTestNode) : MaterialNode.materialAlphaTest;

			PropertyNode.diffuseColor.a.lessThanEqual(alphaTestNode).discard();

		}
	}

	public function setupVariants(builder:Dynamic):Void {
		// Interface function.
	}

	public function setupNormal(builder:Dynamic):Void {
		// NORMAL VIEW

		if (this.flatShading) {

			var normalNode:ShaderNode = PositionNode.positionView.dFdx().cross(PositionNode.positionView.dFdy()).normalize();

			NormalNode.transformedNormalView.assign(normalNode.mul(FrontFacingNode.faceDirection));

		} else {

			var normalNode:ShaderNode = this.normalNode != null ? ShaderNode.vec3(this.normalNode) : MaterialNode.materialNormal;

			NormalNode.transformedNormalView.assign(normalNode.mul(FrontFacingNode.faceDirection));

		}
	}

	public function getEnvNode(builder:Dynamic):EnvironmentNode {
		var node:EnvironmentNode = null;

		if (this.envNode != null) {

			node = this.envNode;

		} else if (this.envMap != null) {

			node = this.envMap.isCubeTexture ? CubeTextureNode.cubeTexture(this.envMap) : TextureNode.texture(this.envMap);

		} else if (builder.environmentNode != null) {

			node = builder.environmentNode;

		}

		return node;
	}

	public function setupLights(builder:Dynamic):LightsNode {
		var envNode:EnvironmentNode = this.getEnvNode(builder);

		//

		var materialLightsNode:Array<EnvironmentNode> = [];

		if (envNode != null) {

			materialLightsNode.push(new EnvironmentNode(envNode));

		}

		if (builder.material.lightMap != null) {

			materialLightsNode.push(new IrradianceNode(MaterialReferenceNode.materialReference('lightMap', 'texture')));

		}

		if (this.aoNode != null || builder.material.aoMap != null) {

			var aoNode:ShaderNode = this.aoNode != null ? this.aoNode : TextureNode.texture(builder.material.aoMap);

			materialLightsNode.push(new AONode(aoNode));

		}

		var lightsN:LightsNode = this.lightsNode != null ? this.lightsNode : builder.lightsNode;

		if (materialLightsNode.length > 0) {

			lightsN = new LightsNode([for (light in lightsN.lightNodes) light, ...materialLightsNode]);

		}

		return lightsN;
	}

	public function setupLightingModel(builder:Dynamic):ShaderNode {
		// Interface function.
		return null;
	}

	public function setupLighting(builder:Dynamic):ShaderNode {
		var {material} = builder;
		var {backdropNode, backdropAlphaNode, emissiveNode} = this;

		// OUTGOING LIGHT

		var lights:Bool = this.lights || this.lightsNode != null;

		var lightsNode:LightsNode = lights ? this.setupLights(builder) : null;

		var outgoingLightNode:ShaderNode = PropertyNode.diffuseColor.rgb;

		if (lightsNode != null && lightsNode.hasLight) {

			var lightingModel:ShaderNode = this.setupLightingModel(builder);

			outgoingLightNode = LightingContextNode.lightingContext(lightsNode, lightingModel, backdropNode, backdropAlphaNode);

		} else if (backdropNode != null) {

			outgoingLightNode = ShaderNode.vec3(backdropAlphaNode != null ? MathNode.mix(outgoingLightNode, backdropNode, backdropAlphaNode) : backdropNode);

		}

		// EMISSIVE

		if ((emissiveNode != null && emissiveNode.isNode) || (material.emissive != null && material.emissive.isColor)) {

			outgoingLightNode = outgoingLightNode.add(ShaderNode.vec3(emissiveNode != null ? emissiveNode : MaterialNode.materialEmissive));

		}

		return outgoingLightNode;
	}

	public function setupOutput(builder:Dynamic, outputNode:ShaderNode):ShaderNode {
		// FOG

		var fogNode:Dynamic = builder.fogNode;

		if (fogNode != null) outputNode = ShaderNode.vec4(fogNode.mix(outputNode.rgb, fogNode.colorNode), outputNode.a);

		return outputNode;
	}

	public function setDefaultValues(material:Material):Void {
		// This approach is to reuse the native refreshUniforms*
		// and turn available the use of features like transmission and environment in core

		for (field in material) {
			if (this[field] == null) {
				this[field] = material[field];
				if (material[field] != null && Reflect.hasField(material[field], 'clone')) {
					this[field] = Reflect.callMethod(material[field], 'clone', []);
				}
			}
		}

		var descriptors = Reflect.getProperty(material.constructor, 'prototype');
		for (key in descriptors) {
			if (Reflect.getProperty(this.constructor, 'prototype')[key] == null &&
			    Reflect.hasField(descriptors[key], 'get')) {
				Reflect.setProperty(this.constructor, 'prototype', key, descriptors[key]);
			}
		}
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRoot:Bool = (meta == null || typeof meta == 'String');

		if (isRoot) {

			meta = {
				textures: {},
				images: {},
				nodes: {}
			};

		}

		var data:Dynamic = Reflect.callMethod(this, 'toJSON', [meta]);
		var nodeChildren:Array<{property:String, childNode:ShaderNode}> = NodeUtils.getNodeChildren(this);

		data.inputNodes = {};

		for (node in nodeChildren) {

			data.inputNodes[node.property] = node.childNode.toJSON(meta).uuid;

		}

		// TODO: Copied from Object3D.toJSON

		function extractFromCache(cache:Dynamic):Array<Dynamic> {

			var values:Array<Dynamic> = [];

			for (key in cache) {

				var data:Dynamic = cache[key];
				Reflect.deleteField(data, 'metadata');
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

		return cast(super.copy(source), NodeMaterial);
	}

	public static function fromMaterial(material:Material):NodeMaterial {
		if (material.isNodeMaterial) { // is already a node material

			return cast(material, NodeMaterial);

		}

		var type:String = material.type.replace('Material', 'NodeMaterial');

		var nodeMaterial:NodeMaterial = createNodeMaterialFromType(type);

		if (nodeMaterial == null) {

			throw new Error('NodeMaterial: Material "' + material.type + '" is not compatible.');

		}

		for (key in material) {

			nodeMaterial[key] = material[key];

		}

		return nodeMaterial;
	}

}

var NodeMaterials:Map<String, Class<NodeMaterial>> = new Map();

function addNodeMaterial(type:String, nodeMaterial:Class<NodeMaterial>):Void {
	if (typeof nodeMaterial != 'function' || type == null) throw new Error('Node material ' + type + ' is not a class');
	if (NodeMaterials.exists(type)) {
		Sys.warning('Redefinition of node material ' + type);
		return;
	}
	NodeMaterials.set(type, nodeMaterial);
	nodeMaterial.type = type;
}

function createNodeMaterialFromType(type:String):NodeMaterial {
	var Material:Class<NodeMaterial> = NodeMaterials.get(type);
	if (Material != null) {
		return new Material();
	}
	return null;
}

addNodeMaterial('NodeMaterial', NodeMaterial);