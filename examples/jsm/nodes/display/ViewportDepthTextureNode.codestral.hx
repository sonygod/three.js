import three.nodes.display.ViewportTextureNode;
import three.core.Node;
import three.shadernode.ShaderNode;
import three.nodes.display.ViewportNode;
import three.textures.DepthTexture;

var sharedDepthbuffer: DepthTexture = null;

class ViewportDepthTextureNode extends ViewportTextureNode {

    public function new(uvNode: ShaderNode = ViewportNode.viewportTopLeft, levelNode: ShaderNode = null) {

        if (sharedDepthbuffer == null) {
            sharedDepthbuffer = new DepthTexture();
        }

        super(uvNode, levelNode, sharedDepthbuffer);
    }
}

@:native("ViewportDepthTextureNode")
abstract ViewportDepthTextureNodeExtern(ViewportDepthTextureNode) {}

var viewportDepthTexture = ShaderNode.nodeProxy(ViewportDepthTextureNodeExtern);

ShaderNode.addNodeElement("viewportDepthTexture", viewportDepthTexture);
Node.addNodeClass("ViewportDepthTextureNode", ViewportDepthTextureNodeExtern);