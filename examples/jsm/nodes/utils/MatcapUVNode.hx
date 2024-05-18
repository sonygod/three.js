package three.js.examples.jsm.nodes.utils;

import three.js.core.TempNode;
import three.accessors.NormalNode;
import three.accessors.PositionNode;
import three.shadernode.ShaderNode;

class MatcapUVNode extends TempNode {

    public function new() {
        super("vec2");
    }

    override public function setup():Vec2 {
        var x:Vec3 = new Vec3(positionViewDirection.z, 0, -positionViewDirection.x).normalize();
        var y:Vec3 = positionViewDirection.cross(x);
        return new Vec2(x.dot(transformedNormalView), y.dot(transformedNormalView)).mul(0.495).add(0.5);
    }

}

class MatcapUV {
    public static var node(get, never):MatcapUVNode;

    private static function get_node():MatcapUVNode {
        return nodeImmutable(new MatcapUVNode());
    }
}

Node.addClass("MatcapUVNode", MatcapUVNode);