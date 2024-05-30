package three.js.examples.jsm.nodes.display;

import three.js.examples.jsm.nodes.ViewportTextureNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.nodes.ViewportNode;
import three.Three;

class ViewportDepthTextureNode extends ViewportTextureNode {

    static var sharedDepthbuffer:DepthTexture = null;

    public function new(uvNode:ViewportNode = ViewportNode.viewportTopLeft, levelNode:Node = null) {
        if (sharedDepthbuffer == null) {
            sharedDepthbuffer = new DepthTexture();
        }
        super(uvNode, levelNode, sharedDepthbuffer);
    }
}

// Export the node class
@:keep
@:expose("ViewportDepthTextureNode")
class __Export__ {
    public static var viewportDepthTexture(get, never):ShaderNode;
    public static function get_viewportDepthTexture():ShaderNode {
        return nodeProxy(ViewportDepthTextureNode);
    }
}

// Register the node class
addNodeElement("viewportDepthTexture", __Export__.viewportDepthTexture);
addNodeClass("ViewportDepthTextureNode", ViewportDepthTextureNode);