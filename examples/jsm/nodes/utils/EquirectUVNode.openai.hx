package three.js.examples.jsm.nodes.utils;

import three.js.core.TempNode;
import three.js.accessors.PositionNode;
import three.js.shadernode.ShaderNode;

class EquirectUVNode extends TempNode {

    public var dirNode:Node;

    public function new(dirNode:Node = PositionNode.positionWorldDirection) {
        super('vec2');
        this.dirNode = dirNode;
    }

    public function setup():Vec2 {
        var dir:Vec3 = cast this.dirNode;
        var u:Float = Math.atan2(dir.z, dir.x) / (Math.PI * 2) + 0.5;
        var v:Float = Math.asin(dir.y.clamp(-1.0, 1.0)) / Math.PI + 0.5;
        return new Vec2(u, v);
    }

}

extern class EquirectUVNodeProxy {
    public static var equirectUV:EquirectUVNode;
}

ShaderNode.addNodeClass('EquirectUVNode', EquirectUVNode);
EquirectUVNodeProxy.equirectUV = ShaderNode.nodeProxy(EquirectUVNode);