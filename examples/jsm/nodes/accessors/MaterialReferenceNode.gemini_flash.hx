import ReferenceNode from "./ReferenceNode";
//import { renderGroup } from "../core/UniformGroupNode";
//import { NodeUpdateType } from "../core/constants";
import { addNodeClass } from "../core/Node";
import { nodeObject } from "../shadernode/ShaderNode";

class MaterialReferenceNode extends ReferenceNode {
  public material:Dynamic;

  public function new(property:String, inputType:String, material:Dynamic = null) {
    super(property, inputType, material);
    this.material = material;
    //this.updateType = NodeUpdateType.RENDER;
  }

  /*public function setNodeType(node:Dynamic) {
    super.setNodeType(node);
    this.node.groupNode = renderGroup;
  }*/

  public function updateReference(state:Dynamic):Dynamic {
    this.reference = if (this.material != null) this.material else state.material;
    return this.reference;
  }
}

export var materialReference = (name:String, type:String, material:Dynamic) => nodeObject(new MaterialReferenceNode(name, type, material));

addNodeClass("MaterialReferenceNode", MaterialReferenceNode);