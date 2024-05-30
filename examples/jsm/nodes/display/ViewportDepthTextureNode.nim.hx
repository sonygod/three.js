import ViewportTextureNode from './ViewportTextureNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';
import { viewportTopLeft } from './ViewportNode.js';
import { DepthTexture } from 'three';

var sharedDepthbuffer = null;

class ViewportDepthTextureNode extends ViewportTextureNode {

	public function new(uvNode = viewportTopLeft, levelNode = null) {

		if (sharedDepthbuffer == null) {

			sharedDepthbuffer = new DepthTexture();

		}

		super(uvNode, levelNode, sharedDepthbuffer);

	}

}

export default ViewportDepthTextureNode;

export var viewportDepthTexture = nodeProxy(ViewportDepthTextureNode);

addNodeElement('viewportDepthTexture', viewportDepthTexture);

addNodeClass('ViewportDepthTextureNode', ViewportDepthTextureNode);