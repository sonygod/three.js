import Math.min;
import Math.max;

class ColorConverter {

    static function setHSV(color:Color, h:Float, s:Float, v:Float):Color {

        // https://gist.github.com/xpansive/1337890#file-index-js

        h = euclideanModulo(h, 1);
        s = clamp(s, 0, 1);
        v = clamp(v, 0, 1);

        return color.setHSL(h, (s * v) / ((v = (2 - s) * v) < 1 ? v : (2 - v)), v * 0.5);

    }

    static function getHSV(color:Color, target:Color):Color {

        color.getHSL(_hsl);

        // based on https://gist.github.com/xpansive/1337890#file-index-js
        _hsl.s *= (_hsl.l < 0.5) ? _hsl.l : (1 - _hsl.l);

        target.h = _hsl.h;
        target.s = 2 * _hsl.s / (_hsl.l + _hsl.s);
        target.v = _hsl.l + _hsl.s;

        return target;

    }

    static function euclideanModulo(n:Float, m:Float):Float {
        return ((n % m) + m) % m;
    }

    static function clamp(value:Float, min:Float, max:Float):Float {
        return max(min(value, max), min);
    }

    static var _hsl = { h: 0, s: 0, l: 0 };

}