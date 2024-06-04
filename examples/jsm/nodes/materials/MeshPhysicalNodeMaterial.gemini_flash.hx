import node.NodeMaterial;
import node.accessors.NormalNode;
import node.core.PropertyNode;
import node.accessors.MaterialNode;
import node.ShaderNode;
import node.accessors.AccessorsUtils;
import node.functions.PhysicalLightingModel;
import node.materials.MeshStandardNodeMaterial;
import node.math.MathNode;
import three.materials.MeshPhysicalMaterial;

class MeshPhysicalNodeMaterial extends MeshStandardNodeMaterial {

	public var clearcoatNode:ShaderNode;
	public var clearcoatRoughnessNode:ShaderNode;
	public var clearcoatNormalNode:ShaderNode;
	public var sheenNode:ShaderNode;
	public var sheenRoughnessNode:ShaderNode;
	public var iridescenceNode:ShaderNode;
	public var iridescenceIORNode:ShaderNode;
	public var iridescenceThicknessNode:ShaderNode;
	public var specularIntensityNode:ShaderNode;
	public var specularColorNode:ShaderNode;
	public var iorNode:ShaderNode;
	public var transmissionNode:ShaderNode;
	public var thicknessNode:ShaderNode;
	public var attenuationDistanceNode:ShaderNode;
	public var attenuationColorNode:ShaderNode;
	public var anisotropyNode:ShaderNode;

	public function new(parameters:Dynamic = null) {
		super();
		this.isMeshPhysicalNodeMaterial = true;
		this.setDefaultValues(new MeshPhysicalMaterial());
		this.setValues(parameters);
	}

	public var useClearcoat(get, never):Bool;
	private function get_useClearcoat():Bool {
		return this.clearcoat > 0 || this.clearcoatNode != null;
	}

	public var useIridescence(get, never):Bool;
	private function get_useIridescence():Bool {
		return this.iridescence > 0 || this.iridescenceNode != null;
	}

	public var useSheen(get, never):Bool;
	private function get_useSheen():Bool {
		return this.sheen > 0 || this.sheenNode != null;
	}

	public var useAnisotropy(get, never):Bool;
	private function get_useAnisotropy():Bool {
		return this.anisotropy > 0 || this.anisotropyNode != null;
	}

	public var useTransmission(get, never):Bool;
	private function get_useTransmission():Bool {
		return this.transmission > 0 || this.transmissionNode != null;
	}

	public function setupSpecular() {
		var iorNode = this.iorNode != null ? ShaderNode.float(this.iorNode) : MaterialNode.materialIOR;
		PropertyNode.ior.assign(iorNode);
		PropertyNode.specularColor.assign(ShaderNode.mix(ShaderNode.min(ShaderNode.pow2(ior.sub(1.0).div(ior.add(1.0))).mul(MaterialNode.materialSpecularColor), ShaderNode.vec3(1.0)).mul(MaterialNode.materialSpecularIntensity), PropertyNode.diffuseColor.rgb, PropertyNode.metalness));
		PropertyNode.specularF90.assign(ShaderNode.mix(MaterialNode.materialSpecularIntensity, 1.0, PropertyNode.metalness));
	}

	public function setupLightingModel(builder:Dynamic):PhysicalLightingModel {
		return new PhysicalLightingModel(this.useClearcoat, this.useSheen, this.useIridescence, this.useAnisotropy, this.useTransmission);
	}

	public function setupVariants(builder:Dynamic) {
		super.setupVariants(builder);
		if (this.useClearcoat) {
			var clearcoatNode = this.clearcoatNode != null ? ShaderNode.float(this.clearcoatNode) : MaterialNode.materialClearcoat;
			var clearcoatRoughnessNode = this.clearcoatRoughnessNode != null ? ShaderNode.float(this.clearcoatRoughnessNode) : MaterialNode.materialClearcoatRoughness;
			PropertyNode.clearcoat.assign(clearcoatNode);
			PropertyNode.clearcoatRoughness.assign(clearcoatRoughnessNode);
		}
		if (this.useSheen) {
			var sheenNode = this.sheenNode != null ? ShaderNode.vec3(this.sheenNode) : MaterialNode.materialSheen;
			var sheenRoughnessNode = this.sheenRoughnessNode != null ? ShaderNode.float(this.sheenRoughnessNode) : MaterialNode.materialSheenRoughness;
			PropertyNode.sheen.assign(sheenNode);
			PropertyNode.sheenRoughness.assign(sheenRoughnessNode);
		}
		if (this.useIridescence) {
			var iridescenceNode = this.iridescenceNode != null ? ShaderNode.float(this.iridescenceNode) : MaterialNode.materialIridescence;
			var iridescenceIORNode = this.iridescenceIORNode != null ? ShaderNode.float(this.iridescenceIORNode) : MaterialNode.materialIridescenceIOR;
			var iridescenceThicknessNode = this.iridescenceThicknessNode != null ? ShaderNode.float(this.iridescenceThicknessNode) : MaterialNode.materialIridescenceThickness;
			PropertyNode.iridescence.assign(iridescenceNode);
			PropertyNode.iridescenceIOR.assign(iridescenceIORNode);
			PropertyNode.iridescenceThickness.assign(iridescenceThicknessNode);
		}
		if (this.useAnisotropy) {
			var anisotropyV = (this.anisotropyNode != null ? ShaderNode.vec2(this.anisotropyNode) : MaterialNode.materialAnisotropy).toVar();
			PropertyNode.anisotropy.assign(anisotropyV.length());
			ShaderNode.If(PropertyNode.anisotropy.equal(0.0), function() {
				anisotropyV.assign(ShaderNode.vec2(1.0, 0.0));
			}, function() {
				anisotropyV.divAssign(PropertyNode.anisotropy);
				PropertyNode.anisotropy.assign(PropertyNode.anisotropy.saturate());
			});
			PropertyNode.alphaT.assign(PropertyNode.anisotropy.pow2().mix(PropertyNode.roughness.pow2(), 1.0));
			PropertyNode.anisotropyT.assign(AccessorsUtils.TBNViewMatrix[0].mul(anisotropyV.x).add(AccessorsUtils.TBNViewMatrix[1].mul(anisotropyV.y)));
			PropertyNode.anisotropyB.assign(AccessorsUtils.TBNViewMatrix[1].mul(anisotropyV.x).sub(AccessorsUtils.TBNViewMatrix[0].mul(anisotropyV.y)));
		}
		if (this.useTransmission) {
			var transmissionNode = this.transmissionNode != null ? ShaderNode.float(this.transmissionNode) : MaterialNode.materialTransmission;
			var thicknessNode = this.thicknessNode != null ? ShaderNode.float(this.thicknessNode) : MaterialNode.materialThickness;
			var attenuationDistanceNode = this.attenuationDistanceNode != null ? ShaderNode.float(this.attenuationDistanceNode) : MaterialNode.materialAttenuationDistance;
			var attenuationColorNode = this.attenuationColorNode != null ? ShaderNode.vec3(this.attenuationColorNode) : MaterialNode.materialAttenuationColor;
			PropertyNode.transmission.assign(transmissionNode);
			PropertyNode.thickness.assign(thicknessNode);
			PropertyNode.attenuationDistance.assign(attenuationDistanceNode);
			PropertyNode.attenuationColor.assign(attenuationColorNode);
		}
	}

	public function setupNormal(builder:Dynamic) {
		super.setupNormal(builder);
		var clearcoatNormalNode = this.clearcoatNormalNode != null ? ShaderNode.vec3(this.clearcoatNormalNode) : MaterialNode.materialClearcoatNormal;
		NormalNode.transformedClearcoatNormalView.assign(clearcoatNormalNode);
	}

	public function copy(source:MeshPhysicalNodeMaterial):MeshPhysicalNodeMaterial {
		this.clearcoatNode = source.clearcoatNode;
		this.clearcoatRoughnessNode = source.clearcoatRoughnessNode;
		this.clearcoatNormalNode = source.clearcoatNormalNode;
		this.sheenNode = source.sheenNode;
		this.sheenRoughnessNode = source.sheenRoughnessNode;
		this.iridescenceNode = source.iridescenceNode;
		this.iridescenceIORNode = source.iridescenceIORNode;
		this.iridescenceThicknessNode = source.iridescenceThicknessNode;
		this.specularIntensityNode = source.specularIntensityNode;
		this.specularColorNode = source.specularColorNode;
		this.transmissionNode = source.transmissionNode;
		this.thicknessNode = source.thicknessNode;
		this.attenuationDistanceNode = source.attenuationDistanceNode;
		this.attenuationColorNode = source.attenuationColorNode;
		this.anisotropyNode = source.anisotropyNode;
		return super.copy(source);
	}

}

NodeMaterial.addNodeMaterial('MeshPhysicalNodeMaterial', MeshPhysicalNodeMaterial);