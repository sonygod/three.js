package three.js.examples.jm.nodes.accessors;

import three.core.Node;
import three.shadernode.ShaderNode;

@:forward(new)
abstract PointUVNode(Node) from Node to Node {

    public var isPointUVNode : Bool = true;

    inline function new() {
        super('vec2');
    }

    override function generate(builder : Dynamic) : String {
        return 'vec2( gl_PointCoord.x, 1.0 - gl_PointCoord.y )';
    }

}

abstract PointUV(String) from String to String {
    inline function new() {
        this = new PointUVNode();
    }
}

Node.addClass('PointUVNode', PointUVNode);

var pointUV : PointUVNode = new PointUVNode();