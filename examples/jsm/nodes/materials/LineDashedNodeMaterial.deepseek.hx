import three.js.examples.jsm.nodes.materials.NodeMaterial;
import three.js.examples.jsm.nodes.core.AttributeNode;
import three.js.examples.jsm.nodes.core.VaryingNode;
import three.js.examples.jsm.nodes.accessors.MaterialNode;
import three.js.examples.jsm.nodes.core.PropertyNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.materials.LineDashedMaterial;

class LineDashedNodeMaterial extends NodeMaterial {

	public function new(parameters:Dynamic) {

		super();

		this.isLineDashedNodeMaterial = true;

		this.lights = false;
		this.normals = false;

		this.setDefaultValues(new LineDashedMaterial());

		this.offsetNode = null;
		this.dashScaleNode = null;
		this.dashSizeNode = null;
		this.gapSizeNode = null;

		this.setValues(parameters);

	}

	public function setupVariants() {

		var offsetNode = this.offsetNode;
		var dashScaleNode = this.dashScaleNode ? ShaderNode.float(this.dashScaleNode) : MaterialNode.materialLineScale;
		var dashSizeNode = this.dashSizeNode ? ShaderNode.float(this.dashSizeNode) : MaterialNode.materialLineDashSize;
		var gapSizeNode = this.dashSizeNode ? ShaderNode.float(this.dashGapNode) : MaterialNode.materialLineGapSize;

		PropertyNode.dashSize.assign(dashSizeNode);
		PropertyNode.gapSize.assign(gapSizeNode);

		var vLineDistance = VaryingNode.varying(AttributeNode.attribute('lineDistance').mul(dashScaleNode));
		var vLineDistanceOffset = offsetNode ? vLineDistance.add(offsetNode) : vLineDistance;

		vLineDistanceOffset.mod(PropertyNode.dashSize.add(PropertyNode.gapSize)).greaterThan(PropertyNode.dashSize).discard();

	}

}

NodeMaterial.addNodeMaterial('LineDashedNodeMaterial', LineDashedNodeMaterial);