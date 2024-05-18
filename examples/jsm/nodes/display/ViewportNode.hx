package three.js.examples.jsm.nodes.display;

import three.js.core.Node;
import three.js.core.constants.NodeUpdateType;
import three.js.core.UniformNode;
import three.js.shadernode.ShaderNode;

import three.Vector2;
import three.Vector4;

class ViewportNode extends Node {

    public var scope:String;

    public var isViewportNode:Bool = true;

    public function new(scope:String) {
        super();
        this.scope = scope;
    }

    public function getNodeType():String {
        if (scope == ViewportNode.VIEWPORT) return 'vec4';
        else if (scope == ViewportNode.COORDINATE) return 'vec3';
        else return 'vec2';
    }

    public function getUpdateType():NodeUpdateType {
        var updateType:NodeUpdateType = NodeUpdateType.NONE;
        if (scope == ViewportNode.RESOLUTION || scope == ViewportNode.VIEWPORT) {
            updateType = NodeUpdateType.RENDER;
        }
        this.updateType = updateType;
        return updateType;
    }

    public function update(renderer:Dynamic) {
        if (scope == ViewportNode.VIEWPORT) {
            renderer.getViewport(viewportResult);
        } else {
            renderer.getDrawingBufferSize(resolution);
        }
    }

    public function setup(builder:Dynamic):Dynamic {
        var scope = this.scope;
        var output:Dynamic = null;
        if (scope == ViewportNode.RESOLUTION) {
            output = UniformNode.uniform(resolution != null ? resolution : (resolution = new Vector2()));
        } else if (scope == ViewportNode.VIEWPORT) {
            output = UniformNode.uniform(viewportResult != null ? viewportResult : (viewportResult = new Vector4()));
        } else {
            output = viewportCoordinate.div(viewportResolution);
            var outX:Float = output.x;
            var outY:Float = output.y;
            if (~scope.indexOf('bottom', 0)) outY = 1.0 - outY;
            if (~scope.indexOf('right', 0)) outX = 1.0 - outX;
            output = new Vector2(outX, outY);
        }
        return output;
    }

    public function generate(builder:Dynamic):Dynamic {
        if (scope == ViewportNode.COORDINATE) {
            var coord = builder.getFragCoord();
            if (builder.isFlipY()) {
                // follow webgpu standards
                var resolution = builder.getNodeProperties(viewportResolution).outputNode.build(builder);
                coord = 'vec3(${coord}.x, ${resolution}.y - ${coord}.y, ${coord}.z)';
            }
            return coord;
        }
        return super.generate(builder);
    }
}

class ViewportNode {
    public static inline var COORDINATE:String = 'coordinate';
    public static inline var RESOLUTION:String = 'resolution';
    public static inline var VIEWPORT:String = 'viewport';
    public static inline var TOP_LEFT:String = 'topLeft';
    public static inline var BOTTOM_LEFT:String = 'bottomLeft';
    public static inline var TOP_RIGHT:String = 'topRight';
    public static inline var BOTTOM_RIGHT:String = 'bottomRight';
}

var viewportCoordinate:ViewportNode = nodeImmutable(ViewportNode, ViewportNode.COORDINATE);
var viewportResolution:ViewportNode = nodeImmutable(ViewportNode, ViewportNode.RESOLUTION);
var viewport:ViewportNode = nodeImmutable(ViewportNode, ViewportNode.VIEWPORT);
var viewportTopLeft:ViewportNode = nodeImmutable(ViewportNode, ViewportNode.TOP_LEFT);
var viewportBottomLeft:ViewportNode = nodeImmutable(ViewportNode, ViewportNode.BOTTOM_LEFT);
var viewportTopRight:ViewportNode = nodeImmutable(ViewportNode, ViewportNode.TOP_RIGHT);
var viewportBottomRight:ViewportNode = nodeImmutable(ViewportNode, ViewportNode.BOTTOM_RIGHT);

Node.addNodeClass('ViewportNode', ViewportNode);