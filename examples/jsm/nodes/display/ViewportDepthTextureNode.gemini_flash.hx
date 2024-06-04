import ViewportTextureNode from "./ViewportTextureNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import ViewportNode from "./ViewportNode";
import DepthTexture from "three";

class ViewportDepthTextureNode extends ViewportTextureNode {

  static sharedDepthbuffer: DepthTexture = null;

  public function new(uvNode: Node = ViewportNode.viewportTopLeft, levelNode: Node = null) {
    if (ViewportDepthTextureNode.sharedDepthbuffer == null) {
      ViewportDepthTextureNode.sharedDepthbuffer = new DepthTexture();
    }
    super(uvNode, levelNode, ViewportDepthTextureNode.sharedDepthbuffer);
  }
}

var viewportDepthTexture = ShaderNode.nodeProxy(ViewportDepthTextureNode);

ShaderNode.addNodeElement("viewportDepthTexture", viewportDepthTexture);

Node.addNodeClass("ViewportDepthTextureNode", ViewportDepthTextureNode);

export default ViewportDepthTextureNode;
export var viewportDepthTexture: ShaderNode.ShaderNodeProxy = viewportDepthTexture;