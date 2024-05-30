import ViewportTextureNode from './ViewportTextureNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';
import { viewportTopLeft } from './ViewportNode.hx';
import DepthTexture from 'three/src/textures/DepthTexture.hx';

var sharedDepthbuffer = null;

class ViewportDepthTextureNode extends ViewportTextureNode {
    public function new(uvNode:ViewportTopLeft = viewportTopLeft, levelNode:Dynamic = null) {
        if (sharedDepthbuffer == null) {
            sharedDepthbuffer = DepthTexture.create(null, null, 0);
        }
        super(uvNode, levelNode, sharedDepthbuffer);
    }
}

@:autoBuild
class ViewportDepthTextureAutoBuild {
    public static function build(depthTexture:ViewportDepthTextureNode) {
        return nodeProxy(depthTexture);
    }
}

addNodeElement('viewportDepthTexture', ViewportDepthTextureAutoBuild.build);
addNodeClass('ViewportDepthTextureNode', ViewportDepthTextureNode);