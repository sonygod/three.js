import TextureNode from '../accessors/TextureNode.js';
import { NodeUpdateType } from '../core/constants.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';
import { viewportTopLeft } from './ViewportNode.js';
import { Vector2, FramebufferTexture, LinearMipmapLinearFilter } from 'three';

class _size extends Vector2();

class ViewportTextureNode extends TextureNode {

	public function new( uvNode = viewportTopLeft, levelNode = null, framebufferTexture = null ) {

		if ( framebufferTexture == null ) {

			framebufferTexture = new FramebufferTexture();
			framebufferTexture.minFilter = LinearMipmapLinearFilter;

		}

		super( framebufferTexture, uvNode, levelNode );

		this.generateMipmaps = false;

		this.isOutputTextureNode = true;

		this.updateBeforeType = NodeUpdateType.FRAME;

	}

	public function updateBefore( frame ) {

		var renderer = frame.renderer;
		renderer.getDrawingBufferSize( _size );

		//

		var framebufferTexture = this.value;

		if ( framebufferTexture.image.width != _size.width || framebufferTexture.image.height != _size.height ) {

			framebufferTexture.image.width = _size.width;
			framebufferTexture.image.height = _size.height;
			framebufferTexture.needsUpdate = true;

		}

		//

		var currentGenerateMipmaps = framebufferTexture.generateMipmaps;
		framebufferTexture.generateMipmaps = this.generateMipmaps;

		renderer.copyFramebufferToTexture( framebufferTexture );

		framebufferTexture.generateMipmaps = currentGenerateMipmaps;

	}

	public function clone() {

		var viewportTextureNode = new this.constructor( this.uvNode, this.levelNode, this.value );
		viewportTextureNode.generateMipmaps = this.generateMipmaps;

		return viewportTextureNode;

	}

}

export default ViewportTextureNode;

export var viewportTexture = nodeProxy( ViewportTextureNode );
export var viewportMipTexture = nodeProxy( ViewportTextureNode, null, null, { generateMipmaps: true } );

addNodeElement( 'viewportTexture', viewportTexture );
addNodeElement( 'viewportMipTexture', viewportMipTexture );

addNodeClass( 'ViewportTextureNode', ViewportTextureNode );