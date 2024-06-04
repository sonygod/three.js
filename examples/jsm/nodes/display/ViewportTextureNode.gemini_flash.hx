import TextureNode from "../accessors/TextureNode";
import NodeUpdateType from "../core/constants";
import {addNodeClass, Node} from "../core/Node";
import {addNodeElement, nodeProxy} from "../shadernode/ShaderNode";
import {viewportTopLeft} from "./ViewportNode";
import {Vector2, FramebufferTexture, LinearMipmapLinearFilter} from "three";

class ViewportTextureNode extends TextureNode {

	private static _size:Vector2 = new Vector2();

	public generateMipmaps:Bool;

	public constructor(uvNode:Node = viewportTopLeft, levelNode:Node = null, framebufferTexture:FramebufferTexture = null) {

		if (framebufferTexture == null) {

			framebufferTexture = new FramebufferTexture();
			framebufferTexture.minFilter = LinearMipmapLinearFilter;

		}

		super(framebufferTexture, uvNode, levelNode);

		this.generateMipmaps = false;

		this.isOutputTextureNode = true;

		this.updateBeforeType = NodeUpdateType.FRAME;

	}

	public updateBefore(frame:Dynamic):Void {

		var renderer = frame.renderer;
		renderer.getDrawingBufferSize(ViewportTextureNode._size);

		//

		var framebufferTexture = this.value;

		if (framebufferTexture.image.width != ViewportTextureNode._size.width || framebufferTexture.image.height != ViewportTextureNode._size.height) {

			framebufferTexture.image.width = ViewportTextureNode._size.width;
			framebufferTexture.image.height = ViewportTextureNode._size.height;
			framebufferTexture.needsUpdate = true;

		}

		//

		var currentGenerateMipmaps:Bool = framebufferTexture.generateMipmaps;
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

export var viewportTexture:Node = nodeProxy(ViewportTextureNode);
export var viewportMipTexture:Node = nodeProxy(ViewportTextureNode, null, null, {generateMipmaps: true});

addNodeElement("viewportTexture", viewportTexture);
addNodeElement("viewportMipTexture", viewportMipTexture);

addNodeClass("ViewportTextureNode", ViewportTextureNode);