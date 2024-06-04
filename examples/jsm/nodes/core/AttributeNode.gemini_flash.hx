import Node from "./Node";
import VaryingNode from "./VaryingNode";
import ShaderNode from "../shadernode/ShaderNode";

class AttributeNode extends Node {
  public defaultNode: Node;
  private _attributeName: String;

  public function new(attributeName: String, nodeType: String = null, defaultNode: Node = null) {
    super(nodeType);
    this.defaultNode = defaultNode;
    this._attributeName = attributeName;
  }

  public function isGlobal(): Bool {
    return true;
  }

  public function getHash(builder: ShaderNode.Builder): String {
    return this.getAttributeName(builder);
  }

  public function getNodeType(builder: ShaderNode.Builder): String {
    var nodeType = super.getNodeType(builder);
    if (nodeType == null) {
      var attributeName = this.getAttributeName(builder);
      if (builder.hasGeometryAttribute(attributeName)) {
        var attribute = builder.geometry.getAttribute(attributeName);
        nodeType = builder.getTypeFromAttribute(attribute);
      } else {
        nodeType = "float";
      }
    }
    return nodeType;
  }

  public function setAttributeName(attributeName: String): AttributeNode {
    this._attributeName = attributeName;
    return this;
  }

  public function getAttributeName(builder: ShaderNode.Builder): String {
    return this._attributeName;
  }

  public function generate(builder: ShaderNode.Builder): String {
    var attributeName = this.getAttributeName(builder);
    var nodeType = this.getNodeType(builder);
    var geometryAttribute = builder.hasGeometryAttribute(attributeName);

    if (geometryAttribute) {
      var attribute = builder.geometry.getAttribute(attributeName);
      var attributeType = builder.getTypeFromAttribute(attribute);

      var nodeAttribute = builder.getAttribute(attributeName, attributeType);

      if (builder.shaderStage == "vertex") {
        return builder.format(nodeAttribute.name, attributeType, nodeType);
      } else {
        var nodeVarying = new VaryingNode(this);
        return nodeVarying.build(builder, nodeType);
      }
    } else {
      trace("AttributeNode: Vertex attribute \"${attributeName}\" not found on geometry.");

      if (this.defaultNode != null) {
        return this.defaultNode.build(builder, nodeType);
      } else {
        return builder.generateConst(nodeType);
      }
    }
  }
}

class AttributeNodeBuilder {
  public static function attribute(name: String, nodeType: String = null, defaultNode: Node = null): AttributeNode {
    return new AttributeNode(name, nodeType, defaultNode);
  }
}

export default AttributeNode;
export var attribute: AttributeNodeBuilder = AttributeNodeBuilder;

Node.addNodeClass("AttributeNode", AttributeNode);