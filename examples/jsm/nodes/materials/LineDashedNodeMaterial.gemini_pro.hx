import NodeMaterial from "./NodeMaterial";
import AttributeNode from "../core/AttributeNode";
import VaryingNode from "../core/VaryingNode";
import MaterialNode from "../accessors/MaterialNode";
import PropertyNode from "../core/PropertyNode";
import ShaderNode from "../shadernode/ShaderNode";

class LineDashedNodeMaterial extends NodeMaterial {

	public var isLineDashedNodeMaterial:Bool = true;

	public var lights:Bool = false;
	public var normals:Bool = false;

	public var offsetNode:ShaderNode;
	public var dashScaleNode:ShaderNode;
	public var dashSizeNode:ShaderNode;
	public var gapSizeNode:ShaderNode;

	public function new(parameters:Dynamic = null) {
		super();
		this.setDefaultValues(LineDashedNodeMaterial.defaultValues);
		this.setValues(parameters);
	}

	public function setupVariants():Void {
		var offsetNode = this.offsetNode;
		var dashScaleNode = this.dashScaleNode != null ? ShaderNode.float(this.dashScaleNode) : MaterialNode.materialLineScale;
		var dashSizeNode = this.dashSizeNode != null ? ShaderNode.float(this.dashSizeNode) : MaterialNode.materialLineDashSize;
		var gapSizeNode = this.dashSizeNode != null ? ShaderNode.float(this.dashGapNode) : MaterialNode.materialLineGapSize;

		PropertyNode.dashSize.assign(dashSizeNode);
		PropertyNode.gapSize.assign(gapSizeNode);

		var vLineDistance = VaryingNode.varying(AttributeNode.attribute("lineDistance").mul(dashScaleNode));
		var vLineDistanceOffset = offsetNode != null ? vLineDistance.add(offsetNode) : vLineDistance;

		vLineDistanceOffset.mod(PropertyNode.dashSize.add(PropertyNode.gapSize)).greaterThan(PropertyNode.dashSize).discard();
	}

	static public var defaultValues:Dynamic;

	static public function init():Void {
		defaultValues = new LineDashedMaterial();
	}

}

LineDashedNodeMaterial.init();
NodeMaterial.addNodeMaterial("LineDashedNodeMaterial", LineDashedNodeMaterial);