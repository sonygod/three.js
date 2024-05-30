import ViewportTextureNode.hx from './ViewportTextureNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';
import { viewportTopLeft } from './ViewportNode.hx';
import { FramebufferTexture } from 'three';

var _sharedFramebuffer = null;

class ViewportSharedTextureNode extends ViewportTextureNode.hx {

	public function new(uvNode = viewportTopLeft, levelNode = null) {

		if (_sharedFramebuffer == null) {

			_sharedFramebuffer = new FramebufferTexture();

		}

		super(uvNode, levelNode, _sharedFramebuffer);

	}

	public function updateReference() {

		return this;

	}

}

export default ViewportSharedTextureNode;

export var viewportSharedTexture = nodeProxy(ViewportSharedTextureNode);

addNodeElement('viewportSharedTexture', viewportSharedTexture);

addNodeClass('ViewportSharedTextureNode', ViewportSharedTextureNode);