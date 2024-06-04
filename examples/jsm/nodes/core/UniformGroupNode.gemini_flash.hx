import Node from "./Node";
import NodeTools from "./NodeTools";

class UniformGroupNode extends Node {
  public var name:String;
  public var version:Int = 0;
  public var shared:Bool;
  public var isUniformGroup:Bool = true;

  public function new(name:String, shared:Bool = false) {
    super("string");
    this.name = name;
    this.shared = shared;
  }

  public function set needsUpdate(value:Bool) {
    if (value) {
      version++;
    }
  }
}

var uniformGroup = (name:String) -> UniformGroupNode {
  return new UniformGroupNode(name);
};

var sharedUniformGroup = (name:String) -> UniformGroupNode {
  return new UniformGroupNode(name, true);
};

var frameGroup = sharedUniformGroup("frame");
var renderGroup = sharedUniformGroup("render");
var objectGroup = uniformGroup("object");

NodeTools.addNodeClass("UniformGroupNode", UniformGroupNode);

export {
  UniformGroupNode,
  uniformGroup,
  sharedUniformGroup,
  frameGroup,
  renderGroup,
  objectGroup,
};