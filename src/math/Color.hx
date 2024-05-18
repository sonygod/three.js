package three.math;

import haxe.ds.StringMap;
import Math;

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

    public function setHex(hex:Int, colorSpace:Int = SRGBColorSpace):Color {
        hex = Math.floor(hex);
        this.r = (hex >> 16 & 255) / 255;
        this.g = (hex >> 8 & 255) / 255;
        this.b = (hex & 255) / 255;
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setRGB(r:Float, g:Float, b:Float, colorSpace:Int = ColorManagement.workingColorSpace):Color {
        this.r = r;
        this.g = g;
        this.b = b;
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setHSL(h:Float, s:Float, l:Float, colorSpace:Int = ColorManagement.workingColorSpace):Color {
        h = euclideanModulo(h, 1);
        s = clamp(s, 0, 1);
        l = clamp(l, 0, 1);
        if (s == 0) {
            this.r = this.g = this.b = l;
        } else {
            var p:Float = l <= 0.5 ? l * (1 + s) : l + s - (l * s);
            var q:Float = 2 * l - p;
            this.r = hue2rgb(q, p, h + 1/3);
            this.g = hue2rgb(q, p, h);
            this.b = hue2rgb(q, p, h - 1/3);
        }
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setStyle(style:String, colorSpace:Int = SRGBColorSpace):Color {
        // ... (omitted for brevity)
    }

    // ... (omitted for brevity)

    public function clone():Color {
        return new Color(r, g, b);
    }

    public function copy(color:Color):Color {
        this.r = color.r;
        this.g = color.g;
        this.b = color.b;
        return this;
    }

    // ... (omitted for brevity)
}

class ColorManagement {
    public static function toWorkingColorSpace(color:Color, colorSpace:Int):Void {
        // ... (omitted for brevity)
    }

    public static function fromWorkingColorSpace(color:Color, colorSpace:Int):Void {
        // ... (omitted for brevity)
    }
}

class MathUtils {
    public static function clamp(value:Float, min:Float, max:Float):Float {
        return Math.max(min, Math.min(max, value));
    }

    public static function euclideanModulo(a:Float, b:Float):Float {
        return a - b * Math.floor(a / b);
    }

    public static function lerp(a:Float, b:Float, alpha:Float):Float {
        return a + (b - a) * alpha;
    }
}

class StringMap<T> {
    public var h:Array<T>;
    public function new() {
        h = [];
    }

    public function get(key:String):T {
        return h[key];
    }

    public function set(key:String, value:T):Void {
        h[key] = value;
    }
}

var _colorKeywords:StringMap<Int> = [
    'aliceblue' => 0xF0F8FF,
    'antiquewhite' => 0xFAEBD7,
    'aqua' => 0x00FFFF,
    // ... (omitted for brevity)
];