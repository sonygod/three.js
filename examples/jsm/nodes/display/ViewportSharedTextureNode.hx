package three.js.examples.jsm.nodes.display;

import three.js.nodes.ViewportTextureNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.nodes.ViewportNode;

class ViewportSharedTextureNode extends ViewportTextureNode {

    static var _sharedFramebuffer:FramebufferTexture = null;

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

// Register the node class
Node.addNodeClass('ViewportSharedTextureNode', ViewportSharedTextureNode);

// Create a node proxy
var viewportSharedTexture:ShaderNode = ShaderNode.nodeProxy(ViewportSharedTextureNode);

// Register the node element
ShaderNode.addNodeElement('viewportSharedTexture', viewportSharedTexture);