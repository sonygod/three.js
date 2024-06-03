import js.Browser;
import nodes.core.TempNode;
import nodes.accessors.NormalNode;
import nodes.accessors.PositionNode;
import nodes.shadernode.ShaderNode;
import nodes.core.Node;

class MatcapUVNode extends TempNode {

    public function new() {
        super("vec2");
    }

    override public function setup() {
        var x = new ShaderNode.vec3(PositionNode.positionViewDirection.z, 0, -PositionNode.positionViewDirection.x);
        x.normalize();
        var y = PositionNode.positionViewDirection.cross(x);

        var result = new ShaderNode.vec2(x.dot(NormalNode.transformedNormalView), y.dot(NormalNode.transformedNormalView));
        return result.mul(0.495).add(0.5); // 0.495 to remove artifacts caused by undersized matcap disks
    }
}

@:expose
class MatcapUVNodeJS {
    static public function get matcapUV():Dynamic {
        return ShaderNode.nodeImmutable(MatcapUVNode);
    }
}

js.Browser.window.MatcapUVNode = MatcapUVNode;
js.Browser.window.matcapUV = MatcapUVNodeJS.matcapUV;
Node.addNodeClass("MatcapUVNode", MatcapUVNode);