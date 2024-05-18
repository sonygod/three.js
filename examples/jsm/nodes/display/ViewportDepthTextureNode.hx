package three.js.examples.jsm.nodes.display;

import three.js.examples.jsm.nodes.ViewportTextureNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.nodes.ViewportNode;

class ViewportDepthTextureNode extends ViewportTextureNode {
    
    static var sharedDepthbuffer:DepthTexture = null;

    public function new(uvNode:Dynamic = ViewportNode.viewportTopLeft, levelNode:Dynamic = null) {
        if (sharedDepthbuffer == null) {
            sharedDepthbuffer = new DepthTexture();
        }
        super(uvNode, levelNode, sharedDepthbuffer);
    }
}

// Export the class
@:expose("ViewportDepthTextureNode")
class _ViewportDepthTextureNode extends ViewportDepthTextureNode {}

// Add to node proxy
@:keep
@:native("viewportDepthTexture")
var viewportDepthTexture:Dynamic = nodeProxy(_ViewportDepthTextureNode);

// Add to node elements
@:keep
addNodeElement('viewportDepthTexture', viewportDepthTexture);

// Add to node classes
@:keep
addNodeClass('ViewportDepthTextureNode', _ViewportDepthTextureNode);