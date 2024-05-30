import Node from '../core/Node.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { uniform } from '../core/UniformNode.hx';
import { nodeImmutable, vec2 } from '../shadernode/ShaderNode.hx';

import Vector2 from 'three/src/math/Vector2.hx';
import Vector4 from 'three/src/math/Vector4.hx';

class ViewportNode extends Node {
    public scope:String;
    public isViewportNode:Bool = true;

    public function new(scope:String) {
        super();
        this.scope = scope;
    }

    public function getNodeType():String {
        switch (this.scope) {
            case ViewportNode.VIEWPORT:
                return 'vec4';
            case ViewportNode.COORDINATE:
                return 'vec3';
            default:
                return 'vec2';
        }
    }

    public function getUpdateType():NodeUpdateType {
        var updateType = NodeUpdateType.NONE;
        if (this.scope == ViewportNode.RESOLUTION || this.scope == ViewportNode.VIEWPORT) {
            updateType = NodeUpdateType.RENDER;
        }
        this.updateType = updateType;
        return updateType;
    }

    public function update(renderer:Dynamic) {
        if (this.scope == ViewportNode.VIEWPORT) {
            viewportResult = renderer.getViewport();
        } else {
            resolution = renderer.getDrawingBufferSize();
        }
    }

    public function setup():Dynamic {
        var scope = this.scope;
        var output:Dynamic = null;

        if (scope == ViewportNode.RESOLUTION) {
            output = uniform(resolution ?? new Vector2());
        } else if (scope == ViewportNode.VIEWPORT) {
            output = uniform(viewportResult ?? new Vector4());
        } else {
            output = viewportCoordinate / viewportResolution;
            var outX = output.x;
            var outY = output.y;
            if (StringTools.startsWithCI(scope, 'bottom')) outY = 1.0 - outY;
            if (StringTools.startsWithCI(scope, 'right')) outX = 1.0 - outX;
            output = vec2(outX, outY);
        }

        return output;
    }

    public function generate(builder:Dynamic):Dynamic {
        if (this.scope == ViewportNode.COORDINATE) {
            var coord = builder.getFragCoord();
            if (builder.isFlipY()) {
                // follow webgpu standards
                var resolution = builder.getNodeProperties(viewportResolution).outputNode.build(builder);
                coord = '${ builder.getType('vec3') }(${ coord }.x, ${ resolution }.y - ${ coord }.y, ${ coord }.z)';
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

class ViewportNodeLib {
    public static function addViewportNodeClass() {
        Node.addNodeClass('ViewportNode', ViewportNode);
    }
}