import three.math.MathUtils;

class ColorConverter {
  private static var _hsl:Object = {};

  public static function setHSV(color:Color, h:Float, s:Float, v:Float):Color {
    h = MathUtils.euclideanModulo(h, 1);
    s = MathUtils.clamp(s, 0, 1);
    v = MathUtils.clamp(v, 0, 1);

    return color.setHSL(h, (s * v) / (((h = (2 - s) * v) < 1) ? h : (2 - h)), h * 0.5);
  }

  public static function getHSV(color:Color, target:Object):Object {
    color.getHSL(_hsl);

    _hsl.s *= (_hsl.l < 0.5) ? _hsl.l : (1 - _hsl.l);

    target.h = _hsl.h;
    target.s = 2 * _hsl.s / (_hsl.l + _hsl.s);
    target.v = _hsl.l + _hsl.s;

    return target;
  }
}