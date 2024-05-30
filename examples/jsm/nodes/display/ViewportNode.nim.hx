import Node, { addNodeClass } from '../core/Node.js';
import { NodeUpdateType } from '../core/constants.js';
import { uniform } from '../core/UniformNode.js';
import { nodeImmutable, vec2 } from '../shadernode/ShaderNode.js';

import Vector2, Vector4 from 'three';

var resolution, viewportResult;

class ViewportNode extends Node {

	var scope;

	public function new( scope ) {

		super();

		this.scope = scope;

		this.isViewportNode = true;

	}

	function getNodeType() {

		if ( this.scope === ViewportNode.VIEWPORT ) return 'vec4';
		else if ( this.scope === ViewportNode.COORDINATE ) return 'vec3';
		else return 'vec2';

	}

	function getUpdateType() {

		var updateType = NodeUpdateType.NONE;

		if ( this.scope === ViewportNode.RESOLUTION || this.scope === ViewportNode.VIEWPORT ) {

			updateType = NodeUpdateType.RENDER;

		}

		this.updateType = updateType;

		return updateType;

	}

	function update( renderer ) {

		if ( this.scope === ViewportNode.VIEWPORT ) {

			renderer.getViewport( viewportResult );

		} else {

			renderer.getDrawingBufferSize( resolution );

		}

	}

	function setup( /*builder*/ ) {

		var scope = this.scope;

		var output = null;

		if ( scope === ViewportNode.RESOLUTION ) {

			output = uniform( resolution || ( resolution = new Vector2() ) );

		} else if ( scope === ViewportNode.VIEWPORT ) {

			output = uniform( viewportResult || ( viewportResult = new Vector4() ) );

		} else {

			output = viewportCoordinate.div( viewportResolution );

			var outX = output.x;
			var outY = output.y;

			if ( /bottom/i.test( scope ) ) outY = outY.oneMinus();
			if ( /right/i.test( scope ) ) outX = outX.oneMinus();

			output = vec2( outX, outY );

		}

		return output;

	}

	function generate( builder ) {

		if ( this.scope === ViewportNode.COORDINATE ) {

			var coord = builder.getFragCoord();

			if ( builder.isFlipY() ) {

				// follow webgpu standards

				var resolution = builder.getNodeProperties( viewportResolution ).outputNode.build( builder );

				coord = `${ builder.getType( 'vec3' ) }( ${ coord }.x, ${ resolution }.y - ${ coord }.y, ${ coord }.z )`;

			}

			return coord;

		}

		return super.generate( builder );

	}

}

ViewportNode.COORDINATE = 'coordinate';
ViewportNode.RESOLUTION = 'resolution';
ViewportNode.VIEWPORT = 'viewport';
ViewportNode.TOP_LEFT = 'topLeft';
ViewportNode.BOTTOM_LEFT = 'bottomLeft';
ViewportNode.TOP_RIGHT = 'topRight';
ViewportNode.BOTTOM_RIGHT = 'bottomRight';

export default ViewportNode;

export var viewportCoordinate = nodeImmutable( ViewportNode, ViewportNode.COORDINATE );
export var viewportResolution = nodeImmutable( ViewportNode, ViewportNode.RESOLUTION );
export var viewport = nodeImmutable( ViewportNode, ViewportNode.VIEWPORT );
export var viewportTopLeft = nodeImmutable( ViewportNode, ViewportNode.TOP_LEFT );
export var viewportBottomLeft = nodeImmutable( ViewportNode, ViewportNode.BOTTOM_LEFT );
export var viewportTopRight = nodeImmutable( ViewportNode, ViewportNode.TOP_RIGHT );
export var viewportBottomRight = nodeImmutable( ViewportNode, ViewportNode.BOTTOM_RIGHT );

addNodeClass( 'ViewportNode', ViewportNode );