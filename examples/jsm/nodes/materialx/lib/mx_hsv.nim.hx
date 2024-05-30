// Haxe Transpiler
// https://github.com/AcademySoftwareFoundation/MaterialX/blob/main/libraries/stdlib/genglsl/lib/mx_hsv.glsl

import Int;
import Float;
import Vec3;
import If;
import tslFn;
import Add;
import Sub;
import Mul;

class mx_hsvtorgb {
    public static function main(hsv_immutable:Vec3):Vec3 {
        var hsv:Vec3 = hsv_immutable;
        var h:Float = hsv.x;
        var s:Float = hsv.y;
        var v:Float = hsv.z;

        if (s < 0.0001) {
            return Vec3(v, v, v);
        } else {
            h = Mul(6.0, Sub(h, Floor(h)));
            var hi:Int = Floor(h);
            var f:Float = Sub(h, Float(hi));
            var p:Float = Mul(v, Sub(1.0, s));
            var q:Float = Mul(v, Sub(1.0, Mul(s, f)));
            var t:Float = Mul(v, Sub(1.0, Mul(s, Sub(1.0, f))));

            if (hi == 0) {
                return Vec3(v, t, p);
            } else if (hi == 1) {
                return Vec3(q, v, p);
            } else if (hi == 2) {
                return Vec3(p, v, t);
            } else if (hi == 3) {
                return Vec3(p, q, v);
            } else if (hi == 4) {
                return Vec3(t, p, v);
            }

            return Vec3(v, p, q);
        }
    }
}

class mx_rgbtohsv {
    public static function main(c_immutable:Vec3):Vec3 {
        var c:Vec3 = c_immutable;
        var r:Float = c.x;
        var g:Float = c.y;
        var b:Float = c.z;
        var mincomp:Float = Min(r, Min(g, b));
        var maxcomp:Float = Max(r, Max(g, b));
        var delta:Float = Sub(maxcomp, mincomp);
        var h:Float = 0.0;
        var s:Float = 0.0;
        var v:Float = maxcomp;

        if (maxcomp > 0.0) {
            s = Div(delta, maxcomp);
        } else {
            s = 0.0;
        }

        if (s <= 0.0) {
            h = 0.0;
        } else {
            if (r >= maxcomp) {
                h = Div(Sub(g, b), delta);
            } else if (g >= maxcomp) {
                h = Add(2.0, Div(Sub(b, r), delta));
            } else {
                h = Add(4.0, Div(Sub(r, g), delta));
            }

            h = Mul(h, 1.0 / 6.0);

            if (h < 0.0) {
                h = Add(h, 1.0);
            }
        }

        return Vec3(h, s, v);
    }
}

// layouts

mx_hsvtorgb.setLayout({
    name: 'mx_hsvtorgb',
    type: 'vec3',
    inputs: [{ name: 'hsv', type: 'vec3' }]
});

mx_rgbtohsv.setLayout({
    name: 'mx_rgbtohsv',
    type: 'vec3',
    inputs: [{ name: 'c', type: 'vec3' }]
});

export { mx_hsvtorgb, mx_rgbtohsv };