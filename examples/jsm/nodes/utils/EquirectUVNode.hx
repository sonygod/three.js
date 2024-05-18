package three.js.examples.jsm.nodes.utils;

import three.js.core.TempNode;
import three.js.accessors.PositionNode;
import three.js.shadernode.ShaderNode;

class EquirectUVNode extends TempNode {
    public var dirNode:PositionNode;

    public function new(?dirNode:PositionNode) {
        super('vec2');
        this.dirNode = dirNode != null ? dirNode : PositionNode.positionWorldDirection;
    }

    public function setup():Vec2 {
        var dir = this.dirNode;
        var u = Math.atan2(dir.z, dir.x) * (1 / (Math.PI * 2)) + 0.5;
        var v = Math.asin(dir.y).clamp(-1.0, 1.0) * (1 / Math.PI) + 0.5;
        return new Vec2(u, v);
    }
}

typedef EquirectUV = EquirectUVNode;

ShaderNode.addNodeClass('EquirectUVNode', EquirectUVNode);