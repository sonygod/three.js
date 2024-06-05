import Node from "../core/Node";
import {NodeUpdateType} from "../core/constants";
import {uniform} from "../core/UniformNode";
import {nodeImmutable, vec2} from "../shadernode/ShaderNode";
import {Vector2, Vector4} from "three";

class ViewportNode extends Node {
	public scope:String;
	public isViewportNode:Bool;

	public constructor(scope:String) {
		super();
		this.scope = scope;
		this.isViewportNode = true;
	}

	public getNodeType():String {
		switch (this.scope) {
		case ViewportNode.VIEWPORT:
			return "vec4";
		case ViewportNode.COORDINATE:
			return "vec3";
		default:
			return "vec2";
		}
	}

	public getUpdateType():NodeUpdateType {
		var updateType = NodeUpdateType.NONE;
		if (this.scope == ViewportNode.RESOLUTION || this.scope == ViewportNode.VIEWPORT) {
			updateType = NodeUpdateType.RENDER;
		}
		this.updateType = updateType;
		return updateType;
	}

	public update(renderer:Dynamic):Void {
		if (this.scope == ViewportNode.VIEWPORT) {
			renderer.getViewport(viewportResult);
		} else {
			renderer.getDrawingBufferSize(resolution);
		}
	}

	public setup(builder:Dynamic):Dynamic {
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
			if (Std.string(scope).toLowerCase().indexOf("bottom") != -1) {
				outY = outY.oneMinus();
			}
			if (Std.string(scope).toLowerCase().indexOf("right") != -1) {
				outX = outX.oneMinus();
			}
			output = vec2(outX, outY);
		}
		return output;
	}

	public generate(builder:Dynamic):String {
		if (this.scope == ViewportNode.COORDINATE) {
			var coord = builder.getFragCoord();
			if (builder.isFlipY()) {
				var resolution = builder.getNodeProperties(viewportResolution).outputNode.build(builder);
				coord = `${builder.getType("vec3")}(${coord}.x, ${resolution}.y - ${coord}.y, ${coord}.z)`;
			}
			return coord;
		}
		return super.generate(builder);
	}

	public static COORDINATE:String = "coordinate";
	public static RESOLUTION:String = "resolution";
	public static VIEWPORT:String = "viewport";
	public static TOP_LEFT:String = "topLeft";
	public static BOTTOM_LEFT:String = "bottomLeft";
	public static TOP_RIGHT:String = "topRight";
	public static BOTTOM_RIGHT:String = "bottomRight";
}

var resolution:Vector2 = null;
var viewportResult:Vector4 = null;

export var viewportCoordinate = nodeImmutable(ViewportNode, ViewportNode.COORDINATE);
export var viewportResolution = nodeImmutable(ViewportNode, ViewportNode.RESOLUTION);
export var viewport = nodeImmutable(ViewportNode, ViewportNode.VIEWPORT);
export var viewportTopLeft = nodeImmutable(ViewportNode, ViewportNode.TOP_LEFT);
export var viewportBottomLeft = nodeImmutable(ViewportNode, ViewportNode.BOTTOM_LEFT);
export var viewportTopRight = nodeImmutable(ViewportNode, ViewportNode.TOP_RIGHT);
export var viewportBottomRight = nodeImmutable(ViewportNode, ViewportNode.BOTTOM_RIGHT);

export default ViewportNode;