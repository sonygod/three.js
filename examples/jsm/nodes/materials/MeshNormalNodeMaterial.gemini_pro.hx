import NodeMaterial from "./NodeMaterial";
import diffuseColor from "../core/PropertyNode";
import directionToColor from "../utils/PackingNode";
import materialOpacity from "../accessors/MaterialNode";
import transformedNormalView from "../accessors/NormalNode";
import { FloatNode, Vector4Node } from "../shadernode/ShaderNode";
import MeshNormalMaterial from "three";

class MeshNormalNodeMaterial extends NodeMaterial {

  public var isMeshNormalNodeMaterial:Bool = true;

  public function new(parameters:Dynamic = null) {
    super();
    this.setDefaultValues(new MeshNormalMaterial());
    this.setValues(parameters);
  }

  public function setupDiffuseColor() {
    var opacityNode = this.opacityNode != null ? new FloatNode(this.opacityNode) : materialOpacity;
    diffuseColor.assign(new Vector4Node(directionToColor(transformedNormalView), opacityNode));
  }
}

export default MeshNormalNodeMaterial;

NodeMaterial.addNodeMaterial("MeshNormalNodeMaterial", MeshNormalNodeMaterial);