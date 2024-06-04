import Node from '../core/Node.hx';
import NodeUpdateType from '../core/constants.hx';
import {uniform} from '../core/UniformNode.hx';
import {nodeImmutable, vec2} from '../shadernode/ShaderNode.hx';

import {Vector2, Vector4} from 'three';

class ViewportNode extends Node {
	var scope:String;
	var resolution:Vector2;
	var viewportResult:Vector4;

	public function new(scope:String) {
		super();
		this.scope = scope;
		this.isViewportNode = true;
	}

	public function getNodeType():String {
		if (this.scope == ViewportNode.VIEWPORT) return 'vec4';
		else if (this.scope == ViewportNode.COORDINATE) return 'vec3';
		else return 'vec2';
	}

	public function getUpdateType():NodeUpdateType {
		var updateType:NodeUpdateType = NodeUpdateType.NONE;
		if (this.scope == ViewportNode.RESOLUTION || this.scope == ViewportNode.VIEWPORT) {
			updateType = NodeUpdateType.RENDER;
		}
		this.updateType = updateType;
		return updateType;
	}

	public function update(renderer:Dynamic) {
		if (this.scope == ViewportNode.VIEWPORT) {
			renderer.getViewport(viewportResult);
		} else {
			renderer.getDrawingBufferSize(resolution);
		}
	}

	public function setup(builder:Dynamic):Dynamic {
		var scope = this.scope;
		var output:Dynamic = null;

		if (scope == ViewportNode.RESOLUTION) {
			output = uniform(resolution == null ? (resolution = new Vector2()) : resolution);
		} else if (scope == ViewportNode.VIEWPORT) {
			output = uniform(viewportResult == null ? (viewportResult = new Vector4()) : viewportResult);
		} else {
			output = viewportCoordinate.div(viewportResolution);
			var outX = output.x;
			var outY = output.y;
			if (scope.toLowerCase().indexOf("bottom") != -1) outY = outY.oneMinus();
			if (scope.toLowerCase().indexOf("right") != -1) outX = outX.oneMinus();
			output = vec2(outX, outY);
		}

		return output;
	}

	public function generate(builder:Dynamic):String {
		if (this.scope == ViewportNode.COORDINATE) {
			var coord = builder.getFragCoord();
			if (builder.isFlipY()) {
				// follow webgpu standards
				var resolution = builder.getNodeProperties(viewportResolution).outputNode.build(builder);
				coord = '${builder.getType('vec3')}(${coord}.x, ${resolution}.y - ${coord}.y, ${coord}.z)';
			}
			return coord;
		}
		return super.generate(builder);
	}

	public static var COORDINATE:String = 'coordinate';
	public static var RESOLUTION:String = 'resolution';
	public static var VIEWPORT:String = 'viewport';
	public static var TOP_LEFT:String = 'topLeft';
	public static var BOTTOM_LEFT:String = 'bottomLeft';
	public static var TOP_RIGHT:String = 'topRight';
	public static var BOTTOM_RIGHT:String = 'bottomRight';
}

var viewportCoordinate = nodeImmutable(ViewportNode, ViewportNode.COORDINATE);
var viewportResolution = nodeImmutable(ViewportNode, ViewportNode.RESOLUTION);
var viewport = nodeImmutable(ViewportNode, ViewportNode.VIEWPORT);
var viewportTopLeft = nodeImmutable(ViewportNode, ViewportNode.TOP_LEFT);
var viewportBottomLeft = nodeImmutable(ViewportNode, ViewportNode.BOTTOM_LEFT);
var viewportTopRight = nodeImmutable(ViewportNode, ViewportNode.TOP_RIGHT);
var viewportBottomRight = nodeImmutable(ViewportNode, ViewportNode.BOTTOM_RIGHT);

export default ViewportNode;