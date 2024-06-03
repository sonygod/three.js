import Node from '../core/Node.hx';
import addNodeClass from '../core/Node.hx';
import nodeImmutable from '../shadernode/ShaderNode.hx';

class PointUVNode extends Node {

    public function new() {
        super('vec2');
        this.isPointUVNode = true;
    }

    public function generate(): String {
        return 'vec2( gl_PointCoord.x, 1.0 - gl_PointCoord.y )';
    }
}

var pointUV = nodeImmutable(new PointUVNode());
addNodeClass('PointUVNode', PointUVNode);