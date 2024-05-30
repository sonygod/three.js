package three.js.examples.jsm.nodes.math;

import three.js.examples.jsm.nodes.OperatorNode;
import three.js.examples.jsm.shadernode.ShaderNode;

class MathUtils {
  static var PI = Math.PI;

  static function pow(a:Float, b:Float):Float {
    return Math.pow(a, b);
  }

  static function sin(a:Float):Float {
    return Math.sin(a);
  }

  static function sub(a:Float, b:Float):Float {
    return a - b;
  }

  static function mul(a:Float, b:Float):Float {
    return a * b;
  }

  static function div(a:Float, b:Float):Float {
    return a / b;
  }

  static function add(a:Float, b:Float):Float {
    return a + b;
  }

  static function lessThan(a:Float, b:Float):Bool {
    return a < b;
  }

  static function parabola(x:Float, k:Float):Float {
    return pow(mul(4.0, mul(x, sub(1.0, x))), k);
  }

  static function gain(x:Float, k:Float):Float {
    return x < 0.5 ? parabola(mul(x, 2.0), k) / 2.0 : sub(1.0, parabola(mul(sub(1.0, x), 2.0), k) / 2.0);
  }

  static function pcurve(x:Float, a:Float, b:Float):Float {
    return pow(div(pow(x, a), add(pow(x, a), pow(sub(1.0, x), b))), 1.0 / a);
  }

  static function sinc(x:Float, k:Float):Float {
    return sin(mul(PI, mul(k, sub(x, 1.0)))) / mul(PI, mul(k, sub(x, 1.0)));
  }

  static function main() {
    ShaderNode.addNodeElement('parabola', parabola);
    ShaderNode.addNodeElement('gain', gain);
    ShaderNode.addNodeElement('pcurve', pcurve);
    ShaderNode.addNodeElement('sinc', sinc);
  }
}