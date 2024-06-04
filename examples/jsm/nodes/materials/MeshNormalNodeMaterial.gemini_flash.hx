import NodeMaterial from "./NodeMaterial";
import PropertyNode from "../core/PropertyNode";
import PackingNode from "../utils/PackingNode";
import MaterialNode from "../accessors/MaterialNode";
import NormalNode from "../accessors/NormalNode";
import ShaderNode from "../shadernode/ShaderNode";
import MeshNormalMaterial from "three/examples/jsm/materials/MeshNormalMaterial";

class MeshNormalNodeMaterial extends NodeMaterial {

	public var isMeshNormalNodeMaterial:Bool = true;

	public function new(parameters:Dynamic) {
		super();
		this.setDefaultValues(new MeshNormalMaterial());
		this.setValues(parameters);
	}

	public function setupDiffuseColor():Void {
		var opacityNode = this.opacityNode != null ? ShaderNode.float(this.opacityNode) : MaterialNode.materialOpacity;
		PropertyNode.diffuseColor.assign(ShaderNode.vec4(PackingNode.directionToColor(NormalNode.transformedNormalView), opacityNode));
	}

}

NodeMaterial.addNodeMaterial("MeshNormalNodeMaterial", MeshNormalNodeMaterial);