package three.js.examples.jsm.nodes.fog;

import three.js.examples.jsm.nodes.FogNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class FogExp2Node extends FogNode {

  public var isFogExp2Node:Bool = true;

  public var densityNode:ShaderNode;

  public function new(colorNode:ShaderNode, densityNode:ShaderNode) {
    super(colorNode);
    this.densityNode = densityNode;
  }

  public function setup(builder:Dynamic):ShaderNode {
    var viewZ = getViewZNode(builder);
    var density = densityNode;
    return density.mul(density, viewZ, viewZ).negate().exp().oneMinus();
  }

}

// Export the class
@:keep
@:native("FogExp2Node")
class __FogExp2Node__ extends FogExp2Node {}

// Export the proxy
@:keep
@:native("densityFog")
var densityFog:ShaderNode = nodeProxy(__FogExp2Node__);

// Register the node element
ShaderNode.addNodeElement("densityFog", densityFog);

// Register the node class
Node.addNodeClass("FogExp2Node", __FogExp2Node__);