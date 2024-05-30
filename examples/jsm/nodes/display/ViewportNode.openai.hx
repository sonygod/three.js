package three.js.examples.nodes.display;

import three.js.core.Node;
import three.js.core.constants.NodeUpdateType;
import three.js.core.UniformNode;
import three.js.shadernode.ShaderNode;

import three.Vector2;
import three.Vector4;

class ViewportNode extends Node {
    public var scope:String;

    public function new(scope:String) {
        super();
        this.scope = scope;
        this.isViewportNode = true;
    }

    public function getNodeType():String {
        if (scope == ViewportNode.VIEWPORT) return 'vec4';
        else if (scope == ViewportNode.COORDINATE) return 'vec3';
        else return 'vec2';
    }

    override public function getUpdateType():NodeUpdateType {
        var updateType:NodeUpdateType = NodeUpdateType.NONE;
        if (scope == ViewportNode.RESOLUTION || scope == ViewportNode.VIEWPORT) {
            updateType = NodeUpdateType.RENDER;
        }
        this.updateType = updateType;
        return updateType;
    }

    override public function update(renderer:Dynamic):Void {
        if (scope == ViewportNode.VIEWPORT) {
            renderer.getViewport(viewportResult);
        } else {
            renderer.getDrawingBufferSize(resolution);
        }
    }

    public function setup(builder:Dynamic):Void {
        var scope:String = this.scope;
        var output:Dynamic = null;
        if (scope == ViewportNode.RESOLUTION) {
            output = UniformNode.uniform(resolution != null ? resolution : (resolution = new Vector2()));
        } else if (scope == ViewportNode.VIEWPORT) {
            output = UniformNode.uniform(viewportResult != null ? viewportResult : (viewportResult = new Vector4()));
        } else {
            output = viewportCoordinate.div(viewportResolution);
            var outX:Float = output.x;
            var outY:Float = output.y;
            if (~scope.toLowerCase().indexOf('bottom')) outY = 1 - outY;
            if (~scope.toLowerCase().indexOf('right')) outX = 1 - outX;
            output = vec2(outX, outY);
        }
        return output;
    }

    override public function generate(builder:Dynamic):Dynamic {
        if (scope == ViewportNode.COORDINATE) {
            var coord:Dynamic = builder.getFragCoord();
            if (builder.isFlipY()) {
                // follow webgpu standards
                var resolution:Dynamic = builder.getNodeProperties(viewportResolution).outputNode.build(builder);
                coord = '${builder.getType('vec3')}(${coord}.x, ${resolution}.y - ${coord}.y, ${coord}.z)';
            }
            return coord;
        }
        return super.generate(builder);
    }

    static public inline var COORDINATE:String = 'coordinate';
    static public inline var RESOLUTION:String = 'resolution';
    static public inline var VIEWPORT:String = 'viewport';
    static public inline var TOP_LEFT:String = 'topLeft';
    static public inline var BOTTOM_LEFT:String = 'bottomLeft';
    static public inline var TOP_RIGHT:String = 'topRight';
    static public inline var BOTTOM_RIGHT:String = 'bottomRight';

    static public var viewportCoordinate:ViewportNode = nodeImmutable(ViewportNode, COORDINATE);
    static public var viewportResolution:ViewportNode = nodeImmutable(ViewportNode, RESOLUTION);
    static public var viewport:ViewportNode = nodeImmutable(ViewportNode, VIEWPORT);
    static public var viewportTopLeft:ViewportNode = nodeImmutable(ViewportNode, TOP_LEFT);
    static public var viewportBottomLeft:ViewportNode = nodeImmutable(ViewportNode, BOTTOM_LEFT);
    static public var viewportTopRight:ViewportNode = nodeImmutable(ViewportNode, TOP_RIGHT);
    static public var viewportBottomRight:ViewportNode = nodeImmutable(ViewportNode, BOTTOM_RIGHT);
}

Node.addClass('ViewportNode', ViewportNode);