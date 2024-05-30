import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.constants.NodeUpdateType;
import three.js.examples.jsm.nodes.core.UniformNode.uniform;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.{nodeImmutable, vec2};

import three.Vector2;
import three.Vector4;

var resolution:Vector2, viewportResult:Vector4;

class ViewportNode extends Node {

	public var scope:String;

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
		var updateType = NodeUpdateType.NONE;
		if (this.scope == ViewportNode.RESOLUTION || this.scope == ViewportNode.VIEWPORT) {
			updateType = NodeUpdateType.RENDER;
		}
		this.updateType = updateType;
		return updateType;
	}

	public function update(renderer:Renderer) {
		if (this.scope == ViewportNode.VIEWPORT) {
			renderer.getViewport(viewportResult);
		} else {
			renderer.getDrawingBufferSize(resolution);
		}
	}

	public function setup():ShaderNode {
		var scope = this.scope;
		var output:ShaderNode = null;
		if (scope == ViewportNode.RESOLUTION) {
			output = uniform(resolution || (resolution = new Vector2()));
		} else if (scope == ViewportNode.VIEWPORT) {
			output = uniform(viewportResult || (viewportResult = new Vector4()));
		} else {
			output = viewportCoordinate.div(viewportResolution);
			var outX = output.x;
			var outY = output.y;
			if (/bottom/i.test(scope)) outY = outY.oneMinus();
			if (/right/i.test(scope)) outX = outX.oneMinus();
			output = vec2(outX, outY);
		}
		return output;
	}

	public function generate(builder:ShaderBuilder):String {
		if (this.scope == ViewportNode.COORDINATE) {
			var coord = builder.getFragCoord();
			if (builder.isFlipY()) {
				var resolution = builder.getNodeProperties(viewportResolution).outputNode.build(builder);
				coord = "${builder.getType('vec3')} (${coord}.x, ${resolution}.y - ${coord}.y, ${coord}.z)";
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

addNodeClass('ViewportNode', ViewportNode);