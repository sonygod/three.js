import ViewportTextureNode from './ViewportTextureNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';
import { viewportTopLeft } from './ViewportNode.hx';
import { FramebufferTexture } from 'three';

var _sharedFramebuffer:FramebufferTexture = null;

class ViewportSharedTextureNode extends ViewportTextureNode {

	public function new(uvNode:Dynamic = viewportTopLeft, levelNode:Dynamic = null) {

		if (_sharedFramebuffer === null) {

			_sharedFramebuffer = new FramebufferTexture();

		}

		super(uvNode, levelNode, _sharedFramebuffer);

	}

	public function updateReference():Dynamic {

		return this;

	}

}

var viewportSharedTexture:Dynamic = nodeProxy(ViewportSharedTextureNode);

addNodeElement('viewportSharedTexture', viewportSharedTexture);

addNodeClass('ViewportSharedTextureNode', ViewportSharedTextureNode);