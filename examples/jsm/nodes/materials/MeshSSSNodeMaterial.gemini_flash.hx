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

	public function direct(light: { lightDirection:ShaderNode.Node, lightColor:ShaderNode.Node, reflectedLight:{directDiffuse:ShaderNode.Node}}, stack:Array<ShaderNode.Node>, builder:NodeMaterial):Void {
		if (this.useSSS) {
			var material = builder.material;
			var scatteringHalf = light.lightDirection.add(NormalNode.transformedNormalView.mul(material.thicknessDistortionNode)).normalize();
			var scatteringDot = ShaderNode.float(PositionNode.positionViewDirection.dot(scatteringHalf.negate()).saturate().pow(material.thicknessPowerNode).mul(material.thicknessScaleNode));
			var scatteringIllu = ShaderNode.vec3(scatteringDot.add(material.thicknessAmbientNode).mul(material.thicknessColorNode));
			light.reflectedLight.directDiffuse.addAssign(scatteringIllu.mul(material.thicknessAttenuationNode.mul(light.lightColor)));
		}
		super.direct(light, stack, builder);
	}

}

class MeshSSSNodeMaterial extends MeshPhysicalNodeMaterial {

	public var thicknessColorNode:ShaderNode.Node = null;
	public var thicknessDistortionNode:ShaderNode.Node = ShaderNode.float(0.1);
	public var thicknessAmbientNode:ShaderNode.Node = ShaderNode.float(0.0);
	public var thicknessAttenuationNode:ShaderNode.Node = ShaderNode.float(0.1);
	public var thicknessPowerNode:ShaderNode.Node = ShaderNode.float(2.0);
	public var thicknessScaleNode:ShaderNode.Node = ShaderNode.float(10.0);

	public function new(parameters:Dynamic) {
		super(parameters);
	}

	public function get useSSS():Bool {
		return this.thicknessColorNode != null;
	}

	public function setupLightingModel(builder:NodeMaterial):PhysicalLightingModel {
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

class SSSLightingModel {

	public var useSSS:Bool;

	public function new(useClearcoat:Bool, useSheen:Bool, useIridescence:Bool, useSSS:Bool) {
		super(useClearcoat, useSheen, useIridescence);
		this.useSSS = useSSS;
	}

	public function direct(light: { lightDirection:ShaderNode.Node, lightColor:ShaderNode.Node, reflectedLight:{directDiffuse:ShaderNode.Node}}, stack:Array<ShaderNode.Node>, builder:NodeMaterial):Void {
		if (this.useSSS) {
			var material = builder.material;
			var scatteringHalf = light.lightDirection.add(NormalNode.transformedNormalView.mul(material.thicknessDistortionNode)).normalize();
			var scatteringDot = ShaderNode.float(PositionNode.positionViewDirection.dot(scatteringHalf.negate()).saturate().pow(material.thicknessPowerNode).mul(material.thicknessScaleNode));
			var scatteringIllu = ShaderNode.vec3(scatteringDot.add(material.thicknessAmbientNode).mul(material.thicknessColorNode));
			light.reflectedLight.directDiffuse.addAssign(scatteringIllu.mul(material.thicknessAttenuationNode.mul(light.lightColor)));
		}
		super.direct(light, stack, builder);
	}

}

class MeshSSSNodeMaterial extends MeshPhysicalNodeMaterial {

	public var thicknessColorNode:ShaderNode.Node = null;
	public var thicknessDistortionNode:ShaderNode.Node = ShaderNode.float(0.1);
	public var thicknessAmbientNode:ShaderNode.Node = ShaderNode.float(0.0);
	public var thicknessAttenuationNode:ShaderNode.Node = ShaderNode.float(0.1);
	public var thicknessPowerNode:ShaderNode.Node = ShaderNode.float(2.0);
	public var thicknessScaleNode:ShaderNode.Node = ShaderNode.float(10.0);

	public function new(parameters:Dynamic) {
		super(parameters);
	}

	public function get useSSS():Bool {
		return this.thicknessColorNode != null;
	}

	public function setupLightingModel(builder:NodeMaterial):PhysicalLightingModel {
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