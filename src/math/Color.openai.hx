package three.math;

import haxe.ds.StringMap;
import three.math.ColorManagement;

class Color {
    public var r:Float;
    public var g:Float;
    public var b:Float;

    public function new(r:Float = 1, g:Float = 1, b:Float = 1) {
        this.r = r;
        this.g = g;
        this.b = b;
    }

    public function set(r:Float, g:Float, b:Float):Color {
        this.r = r;
        this.g = g;
        this.b = b;
        return this;
    }

    public function setScalar(scalar:Float):Color {
        this.r = scalar;
        this.g = scalar;
        this.b = scalar;
        return this;
    }

    public function setHex(hex:Int, colorSpace:String = SRGBColorSpace):Color {
        this.r = (hex >> 16 & 255) / 255;
        this.g = (hex >> 8 & 255) / 255;
        this.b = (hex & 255) / 255;
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setRGB(r:Float, g:Float, b:Float, colorSpace:String = ColorManagement.workingColorSpace):Color {
        this.r = r;
        this.g = g;
        this.b = b;
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setHSL(h:Float, s:Float, l:Float, colorSpace:String = ColorManagement.workingColorSpace):Color {
        // h,s,l ranges are in 0.0 - 1.0
        h = EuclideanModulo(h, 1);
        s = clamp(s, 0, 1);
        l = clamp(l, 0, 1);

        if (s == 0) {
            this.r = this.g = this.b = l;
        } else {
            var p:Float = l <= 0.5 ? l * (1 + s) : l + s - (l * s);
            var q:Float = (2 * l) - p;

            this.r = hue2rgb(q, p, h + 1/3);
            this.g = hue2rgb(q, p, h);
            this.b = hue2rgb(q, p, h - 1/3);
        }

        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setStyle(style:String, colorSpace:String = SRGBColorSpace):Color {
        // ...
    }

    // ... other methods ...

    static var NAMES:StringMap<Int> = [
        'aliceblue' => 0xF0F8FF,
        'antiquewhite' => 0xFAEBD7,
        // ...
    ];
}