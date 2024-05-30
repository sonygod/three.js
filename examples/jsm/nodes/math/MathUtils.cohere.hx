import js.OperatorNode.sub;
import js.OperatorNode.mul;
import js.OperatorNode.div;
import js.OperatorNode.add;
import js.ShaderNode.addNodeElement;
import js.MathNode.{PI, pow, sin};

// remapping functions https://iquilezles.org/articles/functions/
function parabola(x:Float, k:Float):Float {
    return pow(mul(4.0, mul(x, sub(1.0, x)))), k);
}

function gain(x:Float, k:Float):Float {
    if (x < 0.5) {
        return div(parabola(mul(x, 2.0), k), 2.0);
    } else {
        return sub(1.0, div(parabola(mul(sub(1.0, x), 2.0), k), 2.0));
    }
}

function pcurve(x:Float, a:Float, b:Float):Float {
    return pow(div(pow(x, a), add(pow(x, a), pow(sub(1.0, x), b)))), (1.0 / a));
}

function sinc(x:Float, k:Float):Float {
    return div(sin(mul(PI, mul(mul(k, x), sub(1.0))))), mul(PI, mul(mul(k, x), sub(1.0))));
}

addNodeElement('parabola', parabola);
addNodeElement('gain', gain);
addNodeElement('pcurve', pcurve);
addNodeElement('sinc', sinc);