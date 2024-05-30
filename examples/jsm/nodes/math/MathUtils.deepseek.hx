import three.js.examples.jsm.nodes.math.OperatorNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.math.MathNode;

class MathUtils {
    static public function parabola(x:Float, k:Float):Float {
        return MathNode.pow(OperatorNode.mul(4.0, OperatorNode.mul(x, OperatorNode.sub(1.0, x))), k);
    }

    static public function gain(x:Float, k:Float):Float {
        if (x < 0.5) {
            return parabola(OperatorNode.mul(2.0, x), k) / 2.0;
        } else {
            return 1.0 - parabola(OperatorNode.mul(2.0, OperatorNode.sub(1.0, x)), k) / 2.0;
        }
    }

    static public function pcurve(x:Float, a:Float, b:Float):Float {
        return MathNode.pow(OperatorNode.div(MathNode.pow(x, a), OperatorNode.add(MathNode.pow(x, a), MathNode.pow(OperatorNode.sub(1.0, x), b))), 1.0 / a);
    }

    static public function sinc(x:Float, k:Float):Float {
        return MathNode.sin(MathNode.mul(MathNode.mul(MathNode.PI, k), OperatorNode.sub(x, 1.0))) / MathNode.mul(MathNode.mul(MathNode.PI, k), OperatorNode.sub(x, 1.0));
    }

    static public function main():Void {
        ShaderNode.addNodeElement('parabola', parabola);
        ShaderNode.addNodeElement('gain', gain);
        ShaderNode.addNodeElement('pcurve', pcurve);
        ShaderNode.addNodeElement('sinc', sinc);
    }
}