package three.js.examples.jm.math;

import three.MathUtils;

class ColorConverter {
  static var _hsl:Dynamic = {};

  public static function setHSV(color:Dynamic, h:Float, s:Float, v:Float):Void {
    h = MathUtils.euclideanModulo(h, 1);
    s = MathUtils.clamp(s, 0, 1);
    v = MathUtils.clamp(v, 0, 1);

    color.setHSL(h, (s * v) / ((h = (2 - s) * v) < 1 ? h : (2 - h)), h * 0.5);
  }

  public static function getHSV(color:Dynamic, target:Dynamic):Dynamic {
    color.getHSL(_hsl);

    _hsl.s *= (_hsl.l < 0.5) ? _hsl.l : (1 - _hsl.l);

    target.h = _hsl.h;
    target.s = 2 * _hsl.s / (_hsl.l + _hsl.s);
    target.v = _hsl.l + _hsl.s;

    return target;
  }
}