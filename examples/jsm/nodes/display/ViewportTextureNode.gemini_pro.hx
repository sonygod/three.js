import TextureNode from "../accessors/TextureNode";
import {NodeUpdateType} from "../core/constants";
import {addNodeClass, Node} from "../core/Node";
import {addNodeElement, nodeProxy} from "../shadernode/ShaderNode";
import {viewportTopLeft} from "./ViewportNode";
import {Vector2, FramebufferTexture, LinearMipmapLinearFilter} from "three";

class ViewportTextureNode extends TextureNode {
	static __meta__ = {
		fields: {
			_size: {
				type: "Vector2"
			}
		}
	};

	public _size:Vector2;

	public constructor(uvNode:Node = viewportTopLeft, levelNode:Node = null, framebufferTexture:FramebufferTexture = null) {
		if (framebufferTexture == null) {
			framebufferTexture = new FramebufferTexture();
			framebufferTexture.minFilter = LinearMipmapLinearFilter;
		}
		super(framebufferTexture, uvNode, levelNode);
		this.generateMipmaps = false;
		this.isOutputTextureNode = true;
		this.updateBeforeType = NodeUpdateType.FRAME;
		this._size = new Vector2();
	}

	public updateBefore(frame:any) {
		var renderer = frame.renderer;
		renderer.getDrawingBufferSize(this._size);
		var framebufferTexture = this.value;
		if (framebufferTexture.image.width != this._size.width || framebufferTexture.image.height != this._size.height) {
			framebufferTexture.image.width = this._size.width;
			framebufferTexture.image.height = this._size.height;
			framebufferTexture.needsUpdate = true;
		}
		var currentGenerateMipmaps = framebufferTexture.generateMipmaps;
		framebufferTexture.generateMipmaps = this.generateMipmaps;
		renderer.copyFramebufferToTexture(framebufferTexture);
		framebufferTexture.generateMipmaps = currentGenerateMipmaps;
	}

	public clone():ViewportTextureNode {
		var viewportTextureNode = new ViewportTextureNode(this.uvNode, this.levelNode, this.value);
		viewportTextureNode.generateMipmaps = this.generateMipmaps;
		return viewportTextureNode;
	}
}

export default ViewportTextureNode;

export var viewportTexture = nodeProxy(ViewportTextureNode);
export var viewportMipTexture = nodeProxy(ViewportTextureNode, null, null, {generateMipmaps: true});

addNodeElement("viewportTexture", viewportTexture);
addNodeElement("viewportMipTexture", viewportMipTexture);

addNodeClass("ViewportTextureNode", ViewportTextureNode);