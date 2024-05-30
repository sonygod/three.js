import Node, { addNodeClass } from '../core/Node.js';
import { nodeImmutable, nodeProxy } from '../shadernode/ShaderNode.js';
import { cameraNear, cameraFar } from '../accessors/CameraNode.js';
import { positionView } from '../accessors/PositionNode.js';
import { viewportDepthTexture } from './ViewportDepthTextureNode.js';

class ViewportDepthNode extends Node {

	public var scope:String;
	public var valueNode:Node;

	public function new( scope:String, valueNode:Node? ) {

		super('float');

		this.scope = scope;
		this.valueNode = valueNode;

		this.isViewportDepthNode = true;

	}

	public function generate( builder ) {

		var { scope } = this;

		if ( scope == ViewportDepthNode.DEPTH_PIXEL ) {

			return builder.getFragDepth();

		}

		return super.generate( builder );

	}

	public function setup( /*builder*/ ) {

		var { scope } = this;

		var node:Node = null;

		if ( scope == ViewportDepthNode.DEPTH ) {

			node = viewZToOrthographicDepth( positionView.z, cameraNear, cameraFar );

		} else if ( scope == ViewportDepthNode.DEPTH_TEXTURE ) {

			var texture:Node = this.valueNode ? this.valueNode : viewportDepthTexture();

			var viewZ:Node = perspectiveDepthToViewZ( texture, cameraNear, cameraFar );
			node = viewZToOrthographicDepth( viewZ, cameraNear, cameraFar );

		} else if ( scope == ViewportDepthNode.DEPTH_PIXEL ) {

			if ( this.valueNode != null ) {

				node = depthPixelBase().assign( this.valueNode );

			}

		}

		return node;

	}

}

// NOTE: viewZ, the z-coordinate in camera space, is negative for points in front of the camera

// -near maps to 0; -far maps to 1
public static function viewZToOrthographicDepth( viewZ:Node, near:Node, far:Node ) {
	return viewZ.add( near ).div( near.sub( far ) );
}

// maps orthographic depth in [ 0, 1 ] to viewZ
public static function orthographicDepthToViewZ( depth:Node, near:Node, far:Node ) {
	return near.sub( far ).mul( depth ).sub( near );
}

// -near maps to 0; -far maps to 1
public static function viewZToPerspectiveDepth( viewZ:Node, near:Node, far:Node ) {
	return near.add( viewZ ).mul( far ).div( far.sub( near ).mul( viewZ ) );
}

// maps perspective depth in [ 0, 1 ] to viewZ
public static function perspectiveDepthToViewZ( depth:Node, near:Node, far:Node ) {
	return near.mul( far ).div( far.sub( near ).mul( depth ).sub( far ) );
}

ViewportDepthNode.DEPTH = 'depth';
ViewportDepthNode.DEPTH_TEXTURE = 'depthTexture';
ViewportDepthNode.DEPTH_PIXEL = 'depthPixel';

addNodeClass( 'ViewportDepthNode', ViewportDepthNode );

const depthPixelBase = nodeProxy( ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL );

const depth = nodeImmutable( ViewportDepthNode, ViewportDepthNode.DEPTH );
const depthTexture = nodeProxy( ViewportDepthNode, ViewportDepthNode.DEPTH_TEXTURE );
const depthPixel = nodeImmutable( ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL );

depthPixel.assign = ( value ) => depthPixelBase( value );