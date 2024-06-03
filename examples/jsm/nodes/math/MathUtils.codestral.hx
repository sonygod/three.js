import js.MathNode;
import js.OperatorNode;
import js.ShaderNode;

class MathUtils {
    public static function parabola(x:Float, k:Float):Float {
        return MathNode.pow(OperatorNode.mul(4.0, OperatorNode.mul(x, OperatorNode.sub(1.0, x))), k);
    }

    public static function gain(x:Float, k:Float):Float {
        if (x < 0.5) {
            return MathUtils.parabola(OperatorNode.mul(x, 2.0), k) / 2.0;
        } else {
            return OperatorNode.sub(1.0, MathUtils.parabola(OperatorNode.mul(OperatorNode.sub(1.0, x), 2.0), k) / 2.0);
        }
    }

    public static function pcurve(x:Float, a:Float, b:Float):Float {
        return MathNode.pow(OperatorNode.div(MathNode.pow(x, a), OperatorNode.add(MathNode.pow(x, a), MathNode.pow(OperatorNode.sub(1.0, x), b))), 1.0 / a);
    }

    public static function sinc(x:Float, k:Float):Float {
        return OperatorNode.div(MathNode.sin(OperatorNode.mul(MathNode.PI, OperatorNode.sub(OperatorNode.mul(k, x), 1.0))), OperatorNode.mul(MathNode.PI, OperatorNode.sub(OperatorNode.mul(k, x), 1.0)));
    }
}

ShaderNode.addNodeElement('parabola', MathUtils.parabola);
ShaderNode.addNodeElement('gain', MathUtils.gain);
ShaderNode.addNodeElement('pcurve', MathUtils.pcurve);
ShaderNode.addNodeElement('sinc', MathUtils.sinc);