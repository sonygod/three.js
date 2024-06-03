import three.WebGLCoordinateSystem;
import three.BackSide;
import shadernode.ShaderNode;
import node.Node;

class FrontFacingNode extends Node {

    public function new() {
        super("bool");
        this.isFrontFacingNode = true;
    }

    public function generate(builder:Dynamic):String {
        var renderer = Reflect.field(builder, "renderer");
        var material = Reflect.field(builder, "material");

        if (renderer.coordinateSystem == WebGLCoordinateSystem) {
            if (material.side == BackSide) {
                return "false";
            }
        }

        return builder.getFrontFacing();
    }
}

class Main {
    static function main() {
        var frontFacing = ShaderNode.nodeImmutable(FrontFacingNode);
        var faceDirection = ShaderNode.float(frontFacing).mul(2.0).sub(1.0);

        Node.addNodeClass("FrontFacingNode", FrontFacingNode);
    }
}