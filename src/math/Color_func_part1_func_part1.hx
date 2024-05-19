package three.math;

import haxe.ds.StringMap;

using Lambda;

class Color {
    public var r:Float = 1.0;
    public var g:Float = 1.0;
    public var b:Float = 1.0;

    public function new(r:Float = 1.0, g:Float = 1.0, b:Float = 1.0) {
        set(r, g, b);
    }

    public function set(r:Float, g:Float, b:Float):Color {
        this.r = r;
        this.g = g;
        this.b = b;
        return this;
    }

    public function setScalar(scalar:Float):Color {
        r = scalar;
        g = scalar;
        b = scalar;
        return this;
    }

    public function setHex(hex:Int, colorSpace:Int = SRGBColorSpace):Color {
        r = (hex >> 16 & 255) / 255;
        g = (hex >> 8 & 255) / 255;
        b = (hex & 255) / 255;
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
        if (s == 0) {
            r = l;
            g = l;
            b = l;
        } else {
            var p = l <= 0.5 ? l * (1 + s) : l + s - (l * s);
            var q = 2 * l - p;
            r = hue2rgb(q, p, h + 1/3);
            g = hue2rgb(q, p, h);
            b = hue2rgb(q, p, h - 1/3);
        }
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setStyle(style:String, colorSpace:Int = SRGBColorSpace):Color {
        // ...
    }

    // ...

    public function getHex(colorSpace:Int = SRGBColorSpace):Int {
        ColorManagement.fromWorkingColorSpace(this, colorSpace);
        return Math.round(clamp(r * 255, 0, 255)) * 65536 + Math.round(clamp(g * 255, 0, 255)) * 256 + Math.round(clamp(b * 255, 0, 255));
    }

    public function getHexString(colorSpace:Int = SRGBColorSpace):String {
        return ( '000000' + getHex(colorSpace).toString(16) ).substr(-6);
    }

    public function getHSL(target:Object, colorSpace:Int = ColorManagement.workingColorSpace):Object {
        // ...
    }

    public function getRGB(target:Object, colorSpace:Int = ColorManagement.workingColorSpace):Object {
        // ...
    }

    public function getStyle(colorSpace:Int = SRGBColorSpace):String {
        // ...
    }

    // ...

    public function add(color:Color):Color {
        r += color.r;
        g += color.g;
        b += color.b;
        return this;
    }

    public function addColors(color1:Color, color2:Color):Color {
        r = color1.r + color2.r;
        g = color1.g + color2.g;
        b = color1.b + color2.b;
        return this;
    }

    public function addScalar(s:Float):Color {
        r += s;
        g += s;
        b += s;
        return this;
    }

    public function sub(color:Color):Color {
        r = Math.max(0, r - color.r);
        g = Math.max(0, g - color.g);
        b = Math.max(0, b - color.b);
        return this;
    }

    public function multiply(color:Color):Color {
        r *= color.r;
        g *= color.g;
        b *= color.b;
        return this;
    }

    public function multiplyScalar(s:Float):Color {
        r *= s;
        g *= s;
        b *= s;
        return this;
    }

    public function lerp(color:Color, alpha:Float):Color {
        r += (color.r - r) * alpha;
        g += (color.g - g) * alpha;
        b += (color.b - b) * alpha;
        return this;
    }

    public function lerpColors(color1:Color, color2:Color, alpha:Float):Color {
        r = color1.r + (color2.r - color1.r) * alpha;
        g = color1.g + (color2.g - color1.g) * alpha;
        b = color1.b + (color2.b - color1.b) * alpha;
        return this;
    }

    public function lerpHSL(color:Color, alpha:Float):Color {
        // ...
    }

    public function setFromVector3(v:Vector3):Color {
        r = v.x;
        g = v.y;
        b = v.z;
        return this;
    }

    public function applyMatrix3(m:Matrix3):Color {
        var e:Array<Float> = m.elements;
        var r0 = r;
        var g0 = g;
        var b0 = b;
        r = e[0] * r0 + e[3] * g0 + e[6] * b0;
        g = e[1] * r0 + e[4] * g0 + e[7] * b0;
        b = e[2] * r0 + e[5] * g0 + e[8] * b0;
        return this;
    }

    public function equals(c:Color):Bool {
        return (c.r == r) && (c.g == g) && (c.b == b);
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Color {
        r = array[offset];
        g = array[offset + 1];
        b = array[offset + 2];
        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        array[offset] = r;
        array[offset + 1] = g;
        array[offset + 2] = b;
        return array;
    }

    public function fromBufferAttribute(attribute:BufferAttribute, index:Int):Color {
        r = attribute.getX(index);
        g = attribute.getY(index);
        b = attribute.getZ(index);
        return this;
    }

    public function toJSON():Int {
        return getHex();
    }

    public function iterator():Iterator<Float> {
        return [r, g, b].iterator();
    }
}

class ColorManagement {
    public static function toWorkingColorSpace(color:Color, colorSpace:Int):Void {
        // ...
    }

    public static function fromWorkingColorSpace(color:Color, colorSpace:Int):Void {
        // ...
    }
}

class SRGBColorSpace {
    public static var workingColorSpace:Int;
}

class SRGBToLinear {
    public static function toLinear(value:Float):Float {
        // ...
    }
}

class LinearToSRGB {
    public static function fromLinear(value:Float):Float {
        // ...
    }
}

class MathUtils {
    public static function clamp(value:Float, min:Float, max:Float):Float {
        // ...
    }

    public static function euclideanModulo(a:Float, n:Float):Float {
        // ...
    }

    public static function lerp(a:Float, b:Float, alpha:Float):Float {
        // ...
    }
}

class Matrix3 {
    public var elements:Array<Float>;
}

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;
}

class BufferAttribute {
    public function getX(index:Int):Float {
        // ...
    }

    public function getY(index:Int):Float {
        // ...
    }

    public function getZ(index:Int):Float {
        // ...
    }
}

class ColorKeywords {
    public static var aliceblue:Int;
    public static var antiquewhite:Int;
    // ...
}