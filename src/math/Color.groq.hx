package three.math;

import haxe.ds.StringMap;
import math.Math;

using Lambda;

class Color {
    public var r:Float = 1;
    public var g:Float = 1;
    public var b:Float = 1;

    public function new(r:Float = 1, g:Float = 1, b:Float = 1) {
        set(r, g, b);
    }

    public function set(r:Float, g:Float, b:Float):Color {
        if (g == null && b == null) {
            // r is THREE.Color, hex or string
            var value:Dynamic = r;
            if (value != null && Std.is(value, Color)) {
                copy(value);
            } else if (Std.is(value, Int)) {
                setHex(value);
            } else if (Std.is(value, String)) {
                setStyle(value);
            }
        } else {
            setRGB(r, g, b);
        }
        return this;
    }

    public function setScalar(scalar:Float):Color {
        r = scalar;
        g = scalar;
        b = scalar;
        return this;
    }

    public function setHex(hex:Int, colorSpace:Int = SRGBColorSpace):Color {
        hex = Math.floor(hex);
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
        h = Math.fmod(h, 1);
        s = Math.max(0, Math.min(s, 1));
        l = Math.max(0, Math.min(l, 1));
        if (s == 0) {
            r = l;
            g = l;
            b = l;
        } else {
            var p:Float = l <= 0.5 ? l * (1 + s) : l + s - (l * s);
            var q:Float = 2 * l - p;
            r = hue2rgb(q, p, h + 1 / 3);
            g = hue2rgb(q, p, h);
            b = hue2rgb(q, p, h - 1 / 3);
        }
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setStyle(style:String, colorSpace:Int = SRGBColorSpace):Color {
        // ... (implementation omitted for brevity)
        return this;
    }

    public function clone():Color {
        return new Color(r, g, b);
    }

    public function copy(color:Color):Color {
        r = color.r;
        g = color.g;
        b = color.b;
        return this;
    }

    public function copySRGBToLinear(color:Color):Color {
        r = SRGBToLinear(color.r);
        g = SRGBToLinear(color.g);
        b = SRGBToLinear(color.b);
        return this;
    }

    public function copyLinearToSRGB(color:Color):Color {
        r = LinearToSRGB(color.r);
        g = LinearToSRGB(color.g);
        b = LinearToSRGB(color.b);
        return this;
    }

    public function convertSRGBToLinear():Color {
        copySRGBToLinear(this);
        return this;
    }

    public function convertLinearToSRGB():Color {
        copyLinearToSRGB(this);
        return this;
    }

    public function getHex(colorSpace:Int = SRGBColorSpace):Int {
        ColorManagement.fromWorkingColorSpace(this, colorSpace);
        return Math.round(clamp(r * 255, 0, 255)) * 65536 + Math.round(clamp(g * 255, 0, 255)) * 256 + Math.round(clamp(b * 255, 0, 255));
    }

    public function getHexString(colorSpace:Int = SRGBColorSpace):String {
        return StringTools.hex(getHex(colorSpace));
    }

    public function getHSL(target:Object, colorSpace:Int = ColorManagement.workingColorSpace):Object {
        ColorManagement.fromWorkingColorSpace(this, colorSpace);
        var r:Float = this.r;
        var g:Float = this.g;
        var b:Float = this.b;
        var max:Float = Math.max(r, g, b);
        var min:Float = Math.min(r, g, b);
        var l:Float = (min + max) / 2;
        var saturation:Float;
        if (min == max) {
            saturation = 0;
        } else {
            var delta:Float = max - min;
            saturation = l <= 0.5 ? delta / (max + min) : delta / (2 - max - min);
        }
        var hue:Float;
        if (max == r) {
            hue = (g - b) / delta + (g < b ? 6 : 0);
        } else if (max == g) {
            hue = (b - r) / delta + 2;
        } else {
            hue = (r - g) / delta + 4;
        }
        hue /= 6;
        target.h = hue;
        target.s = saturation;
        target.l = l;
        return target;
    }

    public function getRGB(target:Object, colorSpace:Int = ColorManagement.workingColorSpace):Object {
        ColorManagement.fromWorkingColorSpace(this, colorSpace);
        target.r = r;
        target.g = g;
        target.b = b;
        return target;
    }

    public function getStyle(colorSpace:Int = SRGBColorSpace):String {
        ColorManagement.fromWorkingColorSpace(this, colorSpace);
        var r:Float = this.r;
        var g:Float = this.g;
        var b:Float = this.b;
        return 'rgb(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(b * 255)})';
    }

    public function offsetHSL(h:Float, s:Float, l:Float):Color {
        getHSL(_hslA);
        setHSL(_hslA.h + h, _hslA.s + s, _hslA.l + l);
        return this;
    }

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
        getHSL(_hslA);
        color.getHSL(_hslB);
        var h:Float = lerp(_hslA.h, _hslB.h, alpha);
        var s:Float = lerp(_hslA.s, _hslB.s, alpha);
        var l:Float = lerp(_hslA.l, _hslB.l, alpha);
        setHSL(h, s, l);
        return this;
    }

    public function setFromVector3(v:Vector3):Color {
        r = v.x;
        g = v.y;
        b = v.z;
        return this;
    }

    public function applyMatrix3(m:Matrix3):Color {
        var r:Float = this.r;
        var g:Float = this.g;
        var b:Float = this.b;
        var e:Array<Float> = m.elements;
        this.r = e[0] * r + e[3] * g + e[6] * b;
        this.g = e[1] * r + e[4] * g + e[7] * b;
        this.b = e[2] * r + e[5] * g + e[8] * b;
        return this;
    }

    public function equals(c:Color):Bool {
        return c.r == r && c.g == g && c.b == b;
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Color {
        r = array[offset];
        g = array[offset + 1];
        b = array[offset + 2];
        return this;
    }

    public function toArray(array:Array<Float>, offset:Int = 0):Array<Float> {
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

    static var _hslA:Object = {};
    static var _hslB:Object = {};
    static var _colorKeywords:Map<String, Int> = [
        'aliceblue' => 0xF0F8FF,
        'antiquewhite' => 0xFAEBD7,
        'aqua' => 0x00FFFF,
        'aquamarine' => 0x7FFFD4,
        'azure' => 0xF0FFFF,
        // ...
    ];

    public static function hue2rgb(p:Float, q:Float, t:Float):Float {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * 6 * (2 / 3 - t);
        return p;
    }
}