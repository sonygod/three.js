import three.nodes.display.ViewportTextureNode;
import three.nodes.core.Node;
import three.nodes.shadernode.ShaderNode;
import three.nodes.display.ViewportNode;
import three.FramebufferTexture;

var _sharedFramebuffer:FramebufferTexture = null;

class ViewportSharedTextureNode extends ViewportTextureNode {

	public function new(uvNode:ViewportNode = ViewportNode.viewportTopLeft, levelNode:Node = null) {

		if (_sharedFramebuffer == null) {

			_sharedFramebuffer = new FramebufferTexture();

		}

		super(uvNode, levelNode, _sharedFramebuffer);

	}

	public function updateReference():ViewportSharedTextureNode {

		return this;

	}

}

Node.addNodeClass('ViewportSharedTextureNode', ViewportSharedTextureNode);

var viewportSharedTexture = ShaderNode.nodeProxy(ViewportSharedTextureNode);

ShaderNode.addNodeElement('viewportSharedTexture', viewportSharedTexture);