package three.math;

import haxe.ds.StringMap;
import three.color.ColorManagement;
import three.color.SRGBColorSpace;
import three.constants.Constants;

class Color {
    public var r:Float = 1;
    public var g:Float = 1;
    public var b:Float = 1;

    public function new(r:Float = 1, g:Float = 1, b:Float = 1) {
        this.set(r, g, b);
    }

    public function set(r:Float, g:Float, b:Float):Color {
        if (g == null && b == null) {
            // r is Color, hex or string
            var value:Dynamic = r;
            if (value.isColor) {
                this.copy(value);
            } else if (Std.isOfType(value, Int)) {
                this.setHex(value);
            } else if (Std.isOfType(value, String)) {
                this.setStyle(value);
            }
        } else {
            this.setRGB(r, g, b);
        }
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
        // h,s,l ranges are in 0.0 - 1.0
        h = Math.fmod(h, 1);
        s = Math.max(0, Math.min(1, s));
        l = Math.max(0, Math.min(1, l));

        if (s == 0) {
            this.r = this.g = this.b = l;
        } else {
            var p:Float = l <= 0.5 ? l * (1 + s) : l + s - (l * s);
            var q:Float = 2 * l - p;

            this.r = hue2rgb(q, p, h + 1 / 3);
            this.g = hue2rgb(q, p, h);
            this.b = hue2rgb(q, p, h - 1 / 3);
        }

        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setStyle(style:String, colorSpace:Int = SRGBColorSpace):Color {
        // ...
    }

    public function setColorName(style:String, colorSpace:Int = SRGBColorSpace):Color {
        // ...
    }

    public function clone():Color {
        return new Color(r, g, b);
    }

    public function copy(color:Color):Color {
        this.r = color.r;
        this.g = color.g;
        this.b = color.b;
        return this;
    }

    public function copySRGBToLinear(color:Color):Color {
        this.r = SRGBToLinear(color.r);
        this.g = SRGBToLinear(color.g);
        this.b = SRGBToLinear(color.b);
        return this;
    }

    public function copyLinearToSRGB(color:Color):Color {
        this.r = LinearToSRGB(color.r);
        this.g = LinearToSRGB(color.g);
        this.b = LinearToSRGB(color.b);
        return this;
    }

    public function convertSRGBToLinear():Color {
        this.copySRGBToLinear(this);
        return this;
    }

    public function convertLinearToSRGB():Color {
        this.copyLinearToSRGB(this);
        return this;
    }

    public function getHex(colorSpace:Int = SRGBColorSpace):Int {
        ColorManagement.fromWorkingColorSpace(this.copy(), colorSpace);
        return Math.round(clamp(r * 255, 0, 255)) * 65536 + Math.round(clamp(g * 255, 0, 255)) * 256 + Math.round(clamp(b * 255, 0, 255));
    }

    public function getHexString(colorSpace:Int = SRGBColorSpace):String {
        return ( '000000' + getHex(colorSpace).toString(16) ).substr(-6);
    }

    public function getHSL(target:Dynamic, colorSpace:Int = ColorManagement.workingColorSpace):Void {
        // ...
    }

    public function getRGB(target:Dynamic, colorSpace:Int = ColorManagement.workingColorSpace):Void {
        // ...
    }

    public function getStyle(colorSpace:Int = SRGBColorSpace):String {
        // ...
    }

    public function offsetHSL(h:Float, s:Float, l:Float):Color {
        getHSL(_hslA);
        return setHSL(_hslA.h + h, _hslA.s + s, _hslA.l + l);
    }

    public function add(color:Color):Color {
        this.r += color.r;
        this.g += color.g;
        this.b += color.b;
        return this;
    }

    public function addColors(color1:Color, color2:Color):Color {
        this.r = color1.r + color2.r;
        this.g = color1.g + color2.g;
        this.b = color1.b + color2.b;
        return this;
    }

    public function addScalar(s:Float):Color {
        this.r += s;
        this.g += s;
        this.b += s;
        return this;
    }

    public function sub(color:Color):Color {
        this.r = Math.max(0, this.r - color.r);
        this.g = Math.max(0, this.g - color.g);
        this.b = Math.max(0, this.b - color.b);
        return this;
    }

    public function multiply(color:Color):Color {
        this.r *= color.r;
        this.g *= color.g;
        this.b *= color.b;
        return this;
    }

    public function multiplyScalar(s:Float):Color {
        this.r *= s;
        this.g *= s;
        this.b *= s;
        return this;
    }

    public function lerp(color:Color, alpha:Float):Color {
        this.r += (color.r - this.r) * alpha;
        this.g += (color.g - this.g) * alpha;
        this.b += (color.b - this.b) * alpha;
        return this;
    }

    public function lerpColors(color1:Color, color2:Color, alpha:Float):Color {
        this.r = color1.r + (color2.r - color1.r) * alpha;
        this.g = color1.g + (color2.g - color1.g) * alpha;
        this.b = color1.b + (color2.b - color1.b) * alpha;
        return this;
    }

    public function lerpHSL(color:Color, alpha:Float):Color {
        getHSL(_hslA);
        color.getHSL(_hslB);
        var h:Float = lerp(_hslA.h, _hslB.h, alpha);
        var s:Float = lerp(_hslA.s, _hslB.s, alpha);
        var l:Float = lerp(_hslA.l, _hslB.l, alpha);
        setHSL(h, s, l);
        return this;
    }

    public function setFromVector3(v:Vector3):Color {
        this.r = v.x;
        this.g = v.y;
        this.b = v.z;
        return this;
    }

    public function applyMatrix3(m:Matrix3):Color {
        var r:Float = this.r, g:Float = this.g, b:Float = this.b;
        var e:Array<Float> = m.elements;
        this.r = e[0] * r + e[3] * g + e[6] * b;
        this.g = e[1] * r + e[4] * g + e[7] * b;
        this.b = e[2] * r + e[5] * g + e[8] * b;
        return this;
    }

    public function equals(c:Color):Bool {
        return (c.r == this.r) && (c.g == this.g) && (c.b == this.b);
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Color {
        this.r = array[offset];
        this.g = array[offset + 1];
        this.b = array[offset + 2];
        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        array[offset] = this.r;
        array[offset + 1] = this.g;
        array[offset + 2] = this.b;
        return array;
    }

    public function fromBufferAttribute(attribute:BufferAttribute, index:Int):Color {
        this.r = attribute.getX(index);
        this.g = attribute.getY(index);
        this.b = attribute.getZ(index);
        return this;
    }

    public function toJSON():Int {
        return getHex();
    }

    public function iterator():Iterator<Float> {
        return new Iterator<Float>([r, g, b]);
    }

    static public var NAMES:StringMap<Int> = _colorKeywords;
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

class Constants {
    public static var SRGBColorSpace:Int;
}

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;
}

class Matrix3 {
    public var elements:Array<Float>;
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

class Iterator<T> {
    public function new(arr:Array<T>):Void {
        // ...
    }
}

function hue2rgb(q:Float, p:Float, t:Float):Float {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * 6 * (2 / 3 - t);
    return p;
}

function lerp(a:Float, b:Float, alpha:Float):Float {
    return a + (b - a) * alpha;
}

function clamp(v:Float, min:Float, max:Float):Float {
    return Math.max(min, Math.min(max, v));
}

function euclideanModulo(a:Float, b:Float):Float {
    return a - Math.floor(a / b) * b;
}

function SRGBToLinear(v:Float):Float {
    // ...
}

function LinearToSRGB(v:Float):Float {
    // ...
}