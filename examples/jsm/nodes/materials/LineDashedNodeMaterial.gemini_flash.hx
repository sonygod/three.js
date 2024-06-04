import NodeMaterial from "./NodeMaterial";
import AttributeNode from "../core/AttributeNode";
import VaryingNode from "../core/VaryingNode";
import MaterialNode from "../accessors/MaterialNode";
import PropertyNode from "../core/PropertyNode";
import ShaderNode from "../shadernode/ShaderNode";

class LineDashedNodeMaterial extends NodeMaterial {

	public var offsetNode:ShaderNode;
	public var dashScaleNode:ShaderNode;
	public var dashSizeNode:ShaderNode;
	public var gapSizeNode:ShaderNode;

	public function new(parameters:Dynamic) {
		super();

		this.isLineDashedNodeMaterial = true;

		this.lights = false;
		this.normals = false;

		this.offsetNode = null;
		this.dashScaleNode = null;
		this.dashSizeNode = null;
		this.gapSizeNode = null;

		this.setValues(parameters);
	}

	override function setupVariants() {
		var offsetNode = this.offsetNode;
		var dashScaleNode = this.dashScaleNode != null ? ShaderNode.float(this.dashScaleNode) : MaterialNode.lineScale;
		var dashSizeNode = this.dashSizeNode != null ? ShaderNode.float(this.dashSizeNode) : MaterialNode.lineDashSize;
		var gapSizeNode = this.dashSizeNode != null ? ShaderNode.float(this.dashGapNode) : MaterialNode.lineGapSize;

		PropertyNode.dashSize.assign(dashSizeNode);
		PropertyNode.gapSize.assign(gapSizeNode);

		var vLineDistance = VaryingNode.create(AttributeNode.create("lineDistance").mul(dashScaleNode));
		var vLineDistanceOffset = offsetNode != null ? vLineDistance.add(offsetNode) : vLineDistance;

		vLineDistanceOffset.mod(PropertyNode.dashSize.add(PropertyNode.gapSize)).greaterThan(PropertyNode.dashSize).discard();
	}

}

export default LineDashedNodeMaterial;