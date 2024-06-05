import ViewportTextureNode from "./ViewportTextureNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import ViewportNode from "./ViewportNode";
import DepthTexture from "three";

class ViewportDepthTextureNode extends ViewportTextureNode {

  static sharedDepthbuffer: DepthTexture = null;

  public function new(uvNode:ShaderNode = ViewportNode.viewportTopLeft, levelNode:ShaderNode = null) {
    if (ViewportDepthTextureNode.sharedDepthbuffer == null) {
      ViewportDepthTextureNode.sharedDepthbuffer = new DepthTexture();
    }
    super(uvNode, levelNode, ViewportDepthTextureNode.sharedDepthbuffer);
  }
}

export var viewportDepthTexture = ShaderNode.nodeProxy(ViewportDepthTextureNode);

Node.addNodeElement("viewportDepthTexture", viewportDepthTexture);
Node.addNodeClass("ViewportDepthTextureNode", ViewportDepthTextureNode);

export default ViewportDepthTextureNode;