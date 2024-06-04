import ViewportTextureNode from "./ViewportTextureNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import ViewportNode from "./ViewportNode";
import three from "three";

class ViewportSharedTextureNode extends ViewportTextureNode {

	static _sharedFramebuffer:three.FramebufferTexture;

	public function new(uvNode:Node = ViewportNode.viewportTopLeft, levelNode:Node = null) {
		if (ViewportSharedTextureNode._sharedFramebuffer == null) {
			ViewportSharedTextureNode._sharedFramebuffer = new three.FramebufferTexture();
		}
		super(uvNode, levelNode, ViewportSharedTextureNode._sharedFramebuffer);
	}

	public function updateReference():ViewportSharedTextureNode {
		return this;
	}
}

export var viewportSharedTexture = ShaderNode.nodeProxy(ViewportSharedTextureNode);

Node.addNodeElement("viewportSharedTexture", viewportSharedTexture);

Node.addNodeClass("ViewportSharedTextureNode", ViewportSharedTextureNode);