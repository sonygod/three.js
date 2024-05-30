import TextureNode from '../accessors/TextureNode.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';
import { viewportTopLeft } from './ViewportNode.hx';
import { Vector2, FramebufferTexture, LinearMipmapLinearFilter } from 'three';

var _size = new Vector2();

class ViewportTextureNode extends TextureNode {

	public function new(uvNode = viewportTopLeft, levelNode = null, framebufferTexture = null) {

		if (framebufferTexture == null) {

			framebufferTexture = new FramebufferTexture();
			framebufferTexture.minFilter = LinearMipmapLinearFilter;

		}

		super(framebufferTexture, uvNode, levelNode);

		this.generateMipmaps = false;

		this.isOutputTextureNode = true;

		this.updateBeforeType = NodeUpdateType.FRAME;

	}

	public function updateBefore(frame) {

		var renderer = frame.renderer;
		renderer.getDrawingBufferSize(_size);

		//

		var framebufferTexture = this.value;

		if (framebufferTexture.image.width != _size.width || framebufferTexture.image.height != _size.height) {

			framebufferTexture.image.width = _size.width;
			framebufferTexture.image.height = _size.height;
			framebufferTexture.needsUpdate = true;

		}

		//

		var currentGenerateMipmaps = framebufferTexture.generateMipmaps;
		framebufferTexture.generateMipmaps = this.generateMipmaps;

		renderer.copyFramebufferToTexture(framebufferTexture);

		framebufferTexture.generateMipmaps = currentGenerateMipmaps;

	}

	public function clone() {

		var viewportTextureNode = new ViewportTextureNode(this.uvNode, this.levelNode, this.value);
		viewportTextureNode.generateMipmaps = this.generateMipmaps;

		return viewportTextureNode;

	}

}

var viewportTexture = nodeProxy(ViewportTextureNode);
var viewportMipTexture = nodeProxy(ViewportTextureNode, null, null, { generateMipmaps: true });

addNodeElement('viewportTexture', viewportTexture);
addNodeElement('viewportMipTexture', viewportMipTexture);

addNodeClass('ViewportTextureNode', ViewportTextureNode);