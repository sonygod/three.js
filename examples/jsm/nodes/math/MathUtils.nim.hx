import three.examples.jsm.nodes.OperatorNode.*;
import three.examples.jsm.shadernode.ShaderNode.*;
import three.examples.jsm.nodes.math.MathNode.*;

// remapping functions https://iquilezles.org/articles/functions/
@:expose
public static function parabola(x:Float, k:Float):Float {
  return Math.pow(mul(4.0, x.mul(sub(1.0, x))), k);
}

@:expose
public static function gain(x:Float, k:Float):Float {
  if (x < 0.5) {
    return parabola(x.mul(2.0), k).div(2.0);
  } else {
    return sub(1.0, parabola(mul(sub(1.0, x), 2.0), k).div(2.0));
  }
}

@:expose
public static function pcurve(x:Float, a:Float, b:Float):Float {
  return Math.pow(div(Math.pow(x, a), add(Math.pow(x, a), Math.pow(sub(1.0, x), b))), 1.0 / a);
}

@:expose
public static function sinc(x:Float, k:Float):Float {
  return sin(PI.mul(k.mul(x).sub(1.0))).div(PI.mul(k.mul(x).sub(1.0)));
}

addNodeElement("parabola", parabola);
addNodeElement("gain", gain);
addNodeElement("pcurve", pcurve);
addNodeElement("sinc", sinc);