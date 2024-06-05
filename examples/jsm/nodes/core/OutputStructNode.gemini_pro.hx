import Node from "./Node";
import StructTypeNode from "./StructTypeNode";
import ShaderNode from "../shadernode/ShaderNode";

class OutputStructNode extends Node {

  public members: Array<Node>;
  public isOutputStructNode: Bool;

  public function new(members: Array<Node>) {
    super();
    this.members = members;
    this.isOutputStructNode = true;
  }

  override public function setup(builder: ShaderNode) {
    super.setup(builder);

    var types = new Array<String>();
    for (i in 0...members.length) {
      types.push(members[i].getNodeType(builder));
    }

    this.nodeType = builder.getStructTypeFromNode(new StructTypeNode(types)).name;
  }

  override public function generate(builder: ShaderNode, output: String): String {
    var nodeVar = builder.getVarFromNode(this);
    nodeVar.isOutputStructVar = true;

    var propertyName = builder.getPropertyName(nodeVar);

    var structPrefix = propertyName != "" ? propertyName + "." : "";

    for (i in 0...members.length) {
      var snippet = members[i].build(builder, output);
      builder.addLineFlowCode(structPrefix + "m" + i + " = " + snippet);
    }

    return propertyName;
  }

}

export default OutputStructNode;

export function outputStruct(members: Array<Node>): OutputStructNode {
  return new OutputStructNode(members);
}

Node.addNodeClass("OutputStructNode", OutputStructNode);