import ViewportTextureNode from './ViewportTextureNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';
import { viewportTopLeft } from './ViewportNode.hx';
import three.DepthTexture;

var sharedDepthbuffer:Null<DepthTexture> = null;

class ViewportDepthTextureNode extends ViewportTextureNode {

	public function new(uvNode:ViewportTextureNode = viewportTopLeft, levelNode:Null<Node> = null) {

		if (sharedDepthbuffer === null) {

			sharedDepthbuffer = new DepthTexture();

		}

		super(uvNode, levelNode, sharedDepthbuffer);

	}

}

var viewportDepthTexture = nodeProxy(ViewportDepthTextureNode);

addNodeElement('viewportDepthTexture', viewportDepthTexture);

addNodeClass('ViewportDepthTextureNode', ViewportDepthTextureNode);