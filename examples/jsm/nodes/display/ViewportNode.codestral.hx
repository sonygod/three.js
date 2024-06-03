import three.core.Node;
import three.core.NodeUpdateType;
import three.core.UniformNode;
import three.shadernode.ShaderNode;
import three.math.Vector2;
import three.math.Vector4;
import three.renderers.shaders.ShaderBuilder;
import three.renderers.WebGLRenderer;

class ViewportNode extends Node {
    public var scope:String;
    public var isViewportNode:Bool = true;

    public function new(scope:String) {
        super();
        this.scope = scope;
    }

    public function getNodeType():String {
        switch(this.scope) {
            case ViewportNode.VIEWPORT: return 'vec4';
            case ViewportNode.COORDINATE: return 'vec3';
            default: return 'vec2';
        }
    }

    public function getUpdateType():NodeUpdateType {
        var updateType:NodeUpdateType = NodeUpdateType.NONE;

        if (this.scope == ViewportNode.RESOLUTION || this.scope == ViewportNode.VIEWPORT) {
            updateType = NodeUpdateType.RENDER;
        }

        this.updateType = updateType;
        return updateType;
    }

    public function update(renderer:WebGLRenderer) {
        if (this.scope == ViewportNode.VIEWPORT) {
            renderer.getViewport(viewportResult);
        } else {
            renderer.getDrawingBufferSize(resolution);
        }
    }

    public function setup():ShaderNode {
        var output:ShaderNode = null;

        if (this.scope == ViewportNode.RESOLUTION) {
            output = UniformNode.uniform(resolution == null ? resolution = new Vector2() : resolution);
        } else if (this.scope == ViewportNode.VIEWPORT) {
            output = UniformNode.uniform(viewportResult == null ? viewportResult = new Vector4() : viewportResult);
        } else {
            output = viewportCoordinate.div(viewportResolution);
            var outX = output.x;
            var outY = output.y;

            if (new EReg("bottom", "i").match(this.scope)) outY = outY.oneMinus();
            if (new EReg("right", "i").match(this.scope)) outX = outX.oneMinus();

            output = ShaderNode.vec2(outX, outY);
        }

        return output;
    }

    public function generate(builder:ShaderBuilder):String {
        if (this.scope == ViewportNode.COORDINATE) {
            var coord = builder.getFragCoord();

            if (builder.isFlipY()) {
                var resolution = builder.getNodeProperties(viewportResolution).outputNode.build(builder);
                coord = "${builder.getType('vec3')}(${coord}.x, ${resolution}.y - ${coord}.y, ${coord}.z)";
            }

            return coord;
        }

        return super.generate(builder);
    }
}

Node.addNodeClass('ViewportNode', ViewportNode);

class ViewportNodeScope {
    public static var COORDINATE:String = 'coordinate';
    public static var RESOLUTION:String = 'resolution';
    public static var VIEWPORT:String = 'viewport';
    public static var TOP_LEFT:String = 'topLeft';
    public static var BOTTOM_LEFT:String = 'bottomLeft';
    public static var TOP_RIGHT:String = 'topRight';
    public static var BOTTOM_RIGHT:String = 'bottomRight';
}

var resolution:Vector2;
var viewportResult:Vector4;

var viewportCoordinate = ShaderNode.nodeImmutable(ViewportNode, ViewportNodeScope.COORDINATE);
var viewportResolution = ShaderNode.nodeImmutable(ViewportNode, ViewportNodeScope.RESOLUTION);
var viewport = ShaderNode.nodeImmutable(ViewportNode, ViewportNodeScope.VIEWPORT);
var viewportTopLeft = ShaderNode.nodeImmutable(ViewportNode, ViewportNodeScope.TOP_LEFT);
var viewportBottomLeft = ShaderNode.nodeImmutable(ViewportNode, ViewportNodeScope.BOTTOM_LEFT);
var viewportTopRight = ShaderNode.nodeImmutable(ViewportNode, ViewportNodeScope.TOP_RIGHT);
var viewportBottomRight = ShaderNode.nodeImmutable(ViewportNode, ViewportNodeScope.BOTTOM_RIGHT);