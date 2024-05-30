package three.js.examples.jsm.nodes.display;

import three.js.examples.jsm.nodes.ViewportTextureNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.display.ViewportNode;
import three.THREE.FramebufferTexture;

class ViewportSharedTextureNode extends ViewportTextureNode {
    static var _sharedFramebuffer:FramebufferTexture = null;

    public function new(uvNode:Dynamic = ViewportNode.viewportTopLeft, levelNode:Dynamic = null) {
        if (_sharedFramebuffer == null) {
            _sharedFramebuffer = new FramebufferTexture();
        }
        super(uvNode, levelNode, _sharedFramebuffer);
    }

    public function updateReference():ViewportSharedTextureNode {
        return this;
    }
}

// Export the class
@:nativeGen
class ViewportSharedTextureNodeProxy extends ViewportSharedTextureNode {
    public function new(uvNode:Dynamic = ViewportNode.viewportTopLeft, levelNode:Dynamic = null) {
        super(uvNode, levelNode);
    }
}

// Register the node
ShaderNode.addNodeElement("viewportSharedTexture", ViewportSharedTextureNodeProxy);
Node.addNodeClass("ViewportSharedTextureNode", ViewportSharedTextureNode);