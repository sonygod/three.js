import ViewportTextureNode from './ViewportTextureNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';
import { viewportTopLeft } from './ViewportNode.hx';
import { FramebufferTexture } from 'three';

var _sharedFramebuffer = null;

class ViewportSharedTextureNode extends ViewportTextureNode {

	public function new(uvNode:ViewportTopLeft = viewportTopLeft, levelNode:Dynamic = null) {

		if (_sharedFramebuffer == null) {

			_sharedFramebuffer = new FramebufferTexture();

		}

		super(uvNode, levelNode, _sharedFramebuffer);

	}

	public function updateReference():Dynamic {

		return this;

	}

}

@:extern
@:suppress
class ViewportSharedTextureNodeExtern {

	public static inline var __typename__ : String = "ViewportSharedTextureNode";

	public static inline var viewportSharedTexture : Dynamic = nodeProxy(ViewportSharedTextureNode);

}

addNodeElement('viewportSharedTexture', ViewportSharedTextureNode.viewportSharedTexture);

addNodeClass('ViewportSharedTextureNode', ViewportSharedTextureNode);