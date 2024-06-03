import three.nodes.core.TempNode;
import three.nodes.accessors.PositionNode.positionWorldDirection;
import three.nodes.shadernode.ShaderNode.nodeProxy;
import three.nodes.shadernode.ShaderNode.vec2;
import three.nodes.core.Node.addNodeClass;

class EquirectUVNode extends TempNode {

    public var dirNode: Node;

    public function new(dirNode: Node = positionWorldDirection) {
        super('vec2');
        this.dirNode = dirNode;
    }

    public function setup(): Vec2 {
        var dir = this.dirNode;
        var u = dir.z.atan2(dir.x).mul(1 / (Math.PI * 2)).add(0.5);
        var v = dir.y.clamp(-1.0, 1.0).asin().mul(1 / Math.PI).add(0.5);
        return vec2(u, v);
    }

}

class Main {
    static function main() {
        addNodeClass('EquirectUVNode', EquirectUVNode);
    }
}

// Haxe does not support default exports, so you cannot directly export a default instance of EquirectUVNode.
// However, you can define a constant for nodeProxy(EquirectUVNode) as follows:

static var equirectUV = nodeProxy(EquirectUVNode);