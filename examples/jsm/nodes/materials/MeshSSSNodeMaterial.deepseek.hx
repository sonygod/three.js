import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.nodes.functions.PhysicalLightingModel;
import three.js.examples.jsm.nodes.materials.MeshPhysicalNodeMaterial;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class SSSLightingModel extends PhysicalLightingModel {

	public function new(useClearcoat:Bool, useSheen:Bool, useIridescence:Bool, useSSS:Bool) {
		super(useClearcoat, useSheen, useIridescence);
		this.useSSS = useSSS;
	}

	public function direct(lightDirection:ShaderNode, lightColor:ShaderNode, reflectedLight:ShaderNode, stack:Dynamic, builder:Dynamic) {
		if (this.useSSS) {
			var material = builder.material;
			var thicknessColorNode = material.thicknessColorNode;
			var thicknessDistortionNode = material.thicknessDistortionNode;
			var thicknessAmbientNode = material.thicknessAmbientNode;
			var thicknessAttenuationNode = material.thicknessAttenuationNode;
			var thicknessPowerNode = material.thicknessPowerNode;
			var thicknessScaleNode = material.thicknessScaleNode;

			var scatteringHalf = lightDirection.add(NormalNode.transformedNormalView.mul(thicknessDistortionNode)).normalize();
			var scatteringDot = ShaderNode.float(PositionNode.positionViewDirection.dot(scatteringHalf.negate()).saturate().pow(thicknessPowerNode).mul(thicknessScaleNode));
			var scatteringIllu = ShaderNode.vec3(scatteringDot.add(thicknessAmbientNode).mul(thicknessColorNode));

			reflectedLight.directDiffuse.addAssign(scatteringIllu.mul(thicknessAttenuationNode.mul(lightColor)));
		}
		super.direct(lightDirection, lightColor, reflectedLight, stack, builder);
	}
}

class MeshSSSNodeMaterial extends MeshPhysicalNodeMaterial {

	public function new(parameters:Dynamic) {
		super(parameters);
		this.thicknessColorNode = null;
		this.thicknessDistortionNode = ShaderNode.float(0.1);
		this.thicknessAmbientNode = ShaderNode.float(0.0);
		this.thicknessAttenuationNode = ShaderNode.float(0.1);
		this.thicknessPowerNode = ShaderNode.float(2.0);
		this.thicknessScaleNode = ShaderNode.float(10.0);
	}

	public function get_useSSS():Bool {
		return this.thicknessColorNode != null;
	}

	public function setupLightingModel(builder:Dynamic):SSSLightingModel {
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

NodeMaterial.addNodeMaterial('MeshSSSNodeMaterial', MeshSSSNodeMaterial);