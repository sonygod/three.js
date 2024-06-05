import NodeMaterial from "./NodeMaterial";
import NormalNode from "../accessors/NormalNode";
import PositionNode from "../accessors/PositionNode";
import PhysicalLightingModel from "../functions/PhysicalLightingModel";
import MeshPhysicalNodeMaterial from "./MeshPhysicalNodeMaterial";
import ShaderNode from "../shadernode/ShaderNode";

class SSSLightingModel extends PhysicalLightingModel {
	public var useSSS:Bool;

	public function new(useClearcoat:Bool, useSheen:Bool, useIridescence:Bool, useSSS:Bool) {
		super(useClearcoat, useSheen, useIridescence);
		this.useSSS = useSSS;
	}

	public function direct(lightDirection:ShaderNode.Node<ShaderNode.Vec3>, lightColor:ShaderNode.Node<ShaderNode.Vec3>, reflectedLight:ShaderNode.Node<ShaderNode.ReflectedLight>, stack:Array<Dynamic>, builder:NodeMaterial):Void {
		if (this.useSSS) {
			var material = builder.material;
			var scatteringHalf = lightDirection.add(NormalNode.transformedNormalView.mul(material.thicknessDistortionNode)).normalize();
			var scatteringDot = ShaderNode.float(PositionNode.positionViewDirection.dot(scatteringHalf.negate()).saturate().pow(material.thicknessPowerNode).mul(material.thicknessScaleNode));
			var scatteringIllu = ShaderNode.vec3(scatteringDot.add(material.thicknessAmbientNode).mul(material.thicknessColorNode));
			reflectedLight.directDiffuse.addAssign(scatteringIllu.mul(material.thicknessAttenuationNode.mul(lightColor)));
		}
		super.direct(lightDirection, lightColor, reflectedLight, stack, builder);
	}
}

class MeshSSSNodeMaterial extends MeshPhysicalNodeMaterial {
	public var thicknessColorNode:ShaderNode.Node<ShaderNode.Vec3>;
	public var thicknessDistortionNode:ShaderNode.Node<ShaderNode.Float>;
	public var thicknessAmbientNode:ShaderNode.Node<ShaderNode.Float>;
	public var thicknessAttenuationNode:ShaderNode.Node<ShaderNode.Float>;
	public var thicknessPowerNode:ShaderNode.Node<ShaderNode.Float>;
	public var thicknessScaleNode:ShaderNode.Node<ShaderNode.Float>;

	public function new(parameters:Dynamic) {
		super(parameters);
		this.thicknessColorNode = null;
		this.thicknessDistortionNode = ShaderNode.float(0.1);
		this.thicknessAmbientNode = ShaderNode.float(0.0);
		this.thicknessAttenuationNode = ShaderNode.float(0.1);
		this.thicknessPowerNode = ShaderNode.float(2.0);
		this.thicknessScaleNode = ShaderNode.float(10.0);
	}

	public function get useSSS():Bool {
		return this.thicknessColorNode != null;
	}

	public function setupLightingModel(?builder:NodeMaterial):SSSLightingModel {
		return new SSSLightingModel(this.useClearcoat, this.useSheen, this.useIridescence, this.useSSS);
	}

	public function copy(source:MeshSSSNodeMaterial):MeshSSSNodeMaterial {
		this.thicknessColorNode = source.thicknessColorNode;
		this.thicknessDistortionNode = source.thicknessDistortionNode;
		this.thicknessAmbientNode = source.thicknessAmbientNode;
		this.thicknessAttenuationNode = source.thicknessAttenuationNode;
		this.thicknessPowerNode = source.thicknessPowerNode;
		this.thicknessScaleNode = source.thicknessScaleNode;
		return super.copy(source);
	}
}

NodeMaterial.addNodeMaterial("MeshSSSNodeMaterial", MeshSSSNodeMaterial);

export default MeshSSSNodeMaterial;