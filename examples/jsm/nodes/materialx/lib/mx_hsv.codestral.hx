import js.html.ArrayBufferFloat32View;
import js.Array;

class MX_HSV {

    inline static function mx_hsvtorgb(hsv:Float[]):Float[] {
        var h:Float = hsv[0];
        var s:Float = hsv[1];
        var v:Float = hsv[2];

        if(s < 0.0001) {
            return [v, v, v];
        } else {
            h = (6.0 * (h - Math.floor(h)));
            var hi:Int = Math.trunc(h);
            var f:Float = h - hi;
            var p:Float = v * (1.0 - s);
            var q:Float = v * (1.0 - s * f);
            var t:Float = v * (1.0 - s * (1.0 - f));

            switch(hi) {
                case 0:
                    return [v, t, p];
                case 1:
                    return [q, v, p];
                case 2:
                    return [p, v, t];
                case 3:
                    return [p, q, v];
                case 4:
                    return [t, p, v];
                default:
                    return [v, p, q];
            }
        }
    }

    inline static function mx_rgbtohsv(c:Float[]):Float[] {
        var r:Float = c[0];
        var g:Float = c[1];
        var b:Float = c[2];
        var mincomp:Float = Math.min(r, Math.min(g, b));
        var maxcomp:Float = Math.max(r, Math.max(g, b));
        var delta:Float = maxcomp - mincomp;
        var h:Float = 0.0, s:Float = 0.0, v:Float = maxcomp;

        if(maxcomp > 0.0) {
            s = delta / maxcomp;
        }

        if(s <= 0.0) {
            h = 0.0;
        } else {
            if(r >= maxcomp) {
                h = (g - b) / delta;
            } else if(g >= maxcomp) {
                h = 2.0 + (b - r) / delta;
            } else {
                h = 4.0 + (r - g) / delta;
            }

            h *= 1.0 / 6.0;

            if(h < 0.0) {
                h += 1.0;
            }
        }

        return [h, s, v];
    }
}