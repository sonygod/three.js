import MathUtils.clamp;
import MathUtils.euclideanModulo;
import MathUtils.lerp;
import ColorManagement.ColorManagement;
import ColorManagement.SRGBToLinear;
import ColorManagement.LinearToSRGB;
import ColorManagement.SRGBColorSpace;

class Color {
    public var isColor:Bool = true;
    public var r:Float = 1;
    public var g:Float = 1;
    public var b:Float = 1;

    public function new(r:Float, g:Float, b:Float) {
        this.set(r, g, b);
    }

    public function set(r:Float, g:Float, b:Float):Color {
        if (g == null && b == null) {
            // r is THREE.Color, hex or string
            var value = r;
            if (value && value.isColor) {
                this.copy(value);
            } else if (Std.is(value, Int)) {
                this.setHex(value);
            } else if (Std.is(value, String)) {
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

    public function setHex(hex:Int, colorSpace:ColorSpace = SRGBColorSpace):Color {
        hex = Std.int(hex);
        this.r = (hex >> 16 & 255) / 255;
        this.g = (hex >> 8 & 255) / 255;
        this.b = (hex & 255) / 255;
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setRGB(r:Float, g:Float, b:Float, colorSpace:ColorSpace = ColorManagement.workingColorSpace):Color {
        this.r = r;
        this.g = g;
        this.b = b;
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setHSL(h:Float, s:Float, l:Float, colorSpace:ColorSpace = ColorManagement.workingColorSpace):Color {
        // h,s,l ranges are in 0.0 - 1.0
        h = euclideanModulo(h, 1);
        s = clamp(s, 0, 1);
        l = clamp(l, 0, 1);
        if (s == 0) {
            this.r = this.g = this.b = l;
        } else {
            var p = l <= 0.5 ? l * (1 + s) : l + s - (l * s);
            var q = (2 * l) - p;
            this.r = hue2rgb(q, p, h + 1 / 3);
            this.g = hue2rgb(q, p, h);
            this.b = hue2rgb(q, p, h - 1 / 3);
        }
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setStyle(style:String, colorSpace:ColorSpace = SRGBColorSpace):Color {
        function handleAlpha(string:String) {
            if (string == null) return;
            if (Std.parseFloat(string) < 1) {
                trace('THREE.Color: Alpha component of ' + style + ' will be ignored.');
            }
        }

        var m;
        if (m = ~/^(\w+)\(([^\)]*)\)/.exec(style)) {
            // rgb / hsl
            var color;
            var name = m[1];
            var components = m[2];
            switch (name) {
                case 'rgb':
                case 'rgba':
                    if (color = ~/^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(components)) {
                        // rgb(255,0,0) rgba(255,0,0,0.5)
                        handleAlpha(color[4]);
                        return this.setRGB(
                            Math.min(255, Std.parseInt(color[1], 10)) / 255,
                            Math.min(255, Std.parseInt(color[2], 10)) / 255,
                            Math.min(255, Std.parseInt(color[3], 10)) / 255,
                            colorSpace
                        );
                    }
                    if (color = ~/^\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(components)) {
                        // rgb(100%,0%,0%) rgba(100%,0%,0%,0.5)
                        handleAlpha(color[4]);
                        return this.setRGB(
                            Math.min(100, Std.parseInt(color[1], 10)) / 100,
                            Math.min(100, Std.parseInt(color[2], 10)) / 100,
                            Math.min(100, Std.parseInt(color[3], 10)) / 100,
                            colorSpace
                        );
                    }
                    break;
                case 'hsl':
                case 'hsla':
                    if (color = ~/^\s*(\d*\.?\d+)\s*,\s*(\d*\.?\d+)\%\s*,\s*(\d*\.?\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(components)) {
                        // hsl(120,50%,50%) hsla(120,50%,50%,0.5)
                        handleAlpha(color[4]);
                        return this.setHSL(
                            Std.parseFloat(color[1]) / 360,
                            Std.parseFloat(color[2]) / 100,
                            Std.parseFloat(color[3]) / 100,
                            colorSpace
                        );
                    }
                    break;
                default:
                    trace('THREE.Color: Unknown color model ' + style);
            }
        } else if (m = ~/^\#([A-Fa-f\d]+)$/.exec(style)) {
            // hex color
            var hex = m[1];
            var size = hex.length;
            if (size == 3) {
                // #ff0
                return this.setRGB(
                    Std.parseInt(hex.charAt(0), 16) / 15,
                    Std.parseInt(hex.charAt(1), 16) / 15,
                    Std.parseInt(hex.charAt(2), 16) / 15,
                    colorSpace
                );
            } else if (size == 6) {
                // #ff0000
                return this.setHex(Std.parseInt(hex, 16), colorSpace);
            } else {
                trace('THREE.Color: Invalid hex color ' + style);
            }
        } else if (style != null && style.length > 0) {
            return this.setColorName(style, colorSpace);
        }
        return this;
    }

    public function setColorName(style:String, colorSpace:ColorSpace = SRGBColorSpace):Color {
        // color keywords
        var hex = _colorKeywords[style.toLowerCase()];
        if (hex != null) {
            // red
            this.setHex(hex, colorSpace);
        } else {
            // unknown color
            trace('THREE.Color: Unknown color ' + style);
        }
        return this;
    }

    public function clone():Color {
        return new Color(this.r, this.g, this.b);
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

    public function getHex(colorSpace:ColorSpace = SRGBColorSpace):Int {
        ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
        return Std.int(clamp(_color.r * 255, 0, 255)) * 65536 + Std.int(clamp(_color.g * 255, 0, 255)) * 256 + Std.int(clamp(_color.b * 255, 0, 255));
    }

    public function getHexString(colorSpace:ColorSpace = SRGBColorSpace):String {
        return ('000000' + this.getHex(colorSpace).toString(16)).substr(-6);
    }

    public function getHSL(target:HSL, colorSpace:ColorSpace = ColorManagement.workingColorSpace):HSL {
        // h,s,l ranges are in 0.0 - 1.0
        ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
        var r = _color.r, g = _color.g, b = _color.b;
        var max = Math.max(r, g, b);
        var min = Math.min(r, g, b);
        var hue, saturation;
        var lightness = (min + max) / 2.0;
        if (min == max) {
            hue = 0;
            saturation = 0;
        } else {
            var delta = max - min;
            saturation = lightness <= 0.5 ? delta / (max + min) : delta / (2 - max - min);
            switch (max) {
                case r: hue = (g - b) / delta + (g < b ? 6 : 0); break;
                case g: hue = (b - r) / delta + 2; break;
                case b: hue = (r - g) / delta + 4; break;
            }
            hue /= 6;
        }
        target.h = hue;
        target.s = saturation;
        target.l = lightness;
        return target;
    }

    public function getRGB(target:RGB, colorSpace:ColorSpace = ColorManagement.workingColorSpace):RGB {
        ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
        target.r = _color.r;
        target.g = _color.g;
        target.b = _color.b;
        return target;
    }

    public function getStyle(colorSpace:ColorSpace = SRGBColorSpace):String {
        ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
        var r = _color.r, g = _color.g, b = _color.b;
        if (colorSpace != SRGBColorSpace) {
            // Requires CSS Color Module Level 4 (https://www.w3.org/TR/css-color-4/).
            return 'color(' + colorSpace + ' ' + r.toFixed(3) + ' ' + g.toFixed(3) + ' ' + b.toFixed(3) + ')';
        }
        return 'rgb(' + Math.round(r * 255) + ',' + Math.round(g * 255) + ',' + Math.round(b * 255) + ')';
    }

    public function offsetHSL(h:Float, s:Float, l:Float):Color {
        this.getHSL(_hslA);
        return this.setHSL(_hslA.h + h, _hslA.s + s, _hslA.l + l);
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
        this.getHSL(_hslA);
        color.getHSL(_hslB);
        var h = lerp(_hslA.h, _hslB.h, alpha);
        var s = lerp(_hslA.s, _hslB.s, alpha);
        var l = lerp(_hslA.l, _hslB.l, alpha);
        this.setHSL(h, s, l);
        return this;
    }

    public function setFromVector3(v:Vector3):Color {
        this.r = v.x;
        this.g = v.y;
        this.b = v.z;
        return this;
    }

    public function applyMatrix3(m:Matrix3):Color {
        var r = this.r, g = this.g, b = this.b;
        var e = m.elements;
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

    public function toJSON():String {
        return this.getHex().toString();
    }

    public function iterator():Iterator<Float> {
        return new Iterator<Float>([this.r, this.g, this.b]);
    }
}

class HSL {
    public var h:Float;
    public var s:Float;
    public var l:Float;
}

class RGB {
    public var r:Float;
    public var g:Float;
    public var b:Float;
}

class ColorManagement {
    public static var workingColorSpace:ColorSpace;
    public static function toWorkingColorSpace(color:Color, colorSpace:ColorSpace):Color {
        return color;
    }
    public static function fromWorkingColorSpace(color:Color, colorSpace:ColorSpace):Color {
        return color;
    }
}

class SRGBToLinear {
    public static function apply(color:Float):Float {
        return color;
    }
}

class LinearToSRGB {
    public static function apply(color:Float):Float {
        return color;
    }
}

class ColorSpace {
    public static var SRGB:ColorSpace;
}

class MathUtils {
    public static function clamp(value:Float, min:Float, max:Float):Float {
        return Math.min(Math.max(value, min), max);
    }
    public static function euclideanModulo(n:Float, m:Float):Float {
        return ((n % m) + m) % m;
    }
    public static function lerp(a:Float, b:Float, t:Float):Float {
        return a + (b - a) * t;
    }
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
    public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
        this.array = array;
        this.itemSize = itemSize;
        this.normalized = normalized;
    }
    public var array:Array<Float>;
    public var itemSize:Int;
    public var normalized:Bool;
    public function getX(index:Int):Float {
        return this.array[index * this.itemSize];
    }
    public function getY(index:Int):Float {
        return this.array[index * this.itemSize + 1];
    }
    public function getZ(index:Int):Float {
        return this.array[index * this.itemSize + 2];
    }
}

class Iterator<T> {
    public var array:Array<T>;
    public var index:Int;
    public function new(array:Array<T>) {
        this.array = array;
        this.index = 0;
    }
    public function hasNext():Bool {
        return this.index < this.array.length;
    }
    public function next():T {
        return this.array[this.index++];
    }
}

class _colorKeywords {
    public static var aliceblue:Int = 0xF0F8FF;
    public static var antiquewhite:Int = 0xFAEBD7;
    public static var aqua:Int = 0x00FFFF;
    public static var aquamarine:Int = 0x7FFFD4;
    public static var azure:Int = 0xF0FFFF;
    public static var beige:Int = 0xF5F5DC;
    public static var bisque:Int = 0xFFE4C4;
    public static var black:Int = 0x000000;
    public static var blanchedalmond:Int = 0xFFEBCD;
    public static var blue:Int = 0x0000FF;
    public static var blueviolet:Int = 0x8A2BE2;
    public static var brown:Int = 0xA52A2A;
    public static var burlywood:Int = 0xDEB887;
    public static var cadetblue:Int = 0x5F9EA0;
    public static var chartreuse:Int = 0x7FFF00;
    public static var chocolate:Int = 0xD2691E;
    public static var coral:Int = 0xFF7F50;
    public static var cornflowerblue:Int = 0x6495ED;
    public static var cornsilk:Int = 0xFFF8DC;
    public static var crimson:Int = 0xDC143C;
    public static var cyan:Int = 0x00FFFF;
    public static var darkblue:Int = 0x00008B;
    public static var darkcyan:Int = 0x008B8B;
    public static var darkgoldenrod:Int = 0xB8860B;
    public static var darkgray:Int = 0xA9A9A9;
    public static var darkgreen:Int = 0x006400;
    public static var darkgrey:Int = 0xA9A9A9;
    public static var darkkhaki:Int = 0xBDB76B;
    public static var darkmagenta:Int = 0x8B008B;
    public static var darkolivegreen:Int = 0x556B2F;
    public static var darkorange:Int = 0xFF8C00;
    public static var darkorchid:Int = 0x9932CC;
    public static var darkred:Int = 0x8B0000;
    public static var darksalmon:Int = 0xE9967A;
    public static var darkseagreen:Int = 0x8FBC8F;
    public static var darkslateblue:Int = 0x483D8B;
    public static var darkslategray:Int = 0x2F4F4F;
    public static var darkslategrey:Int = 0x2F4F4F;
    public static var darkturquoise:Int = 0x00CED1;
    public static var darkviolet:Int = 0x9400D3;
    public static var deeppink:Int = 0xFF1493;
    public static var deepskyblue:Int = 0x00BFFF;
    public static var dimgray:Int = 0x696969;
    public static var dimgrey:Int = 0x696969;
    public static var dodgerblue:Int = 0x1E90FF;
    public static var firebrick:Int = 0xB22222;
    public static var floralwhite:Int = 0xFFFAF0;
    public static var forestgreen:Int = 0x228B22;
    public static var fuchsia:Int = 0xFF00FF;
    public static var gainsboro:Int = 0xDCDCDC;
    public static var ghostwhite:Int = 0xF8F8FF;
    public static var gold:Int = 0xFFD700;
    public static var goldenrod:Int = 0xDAA520;
    public static var gray:Int = 0x808080;
    public static var green:Int = 0x008000;
    public static var greenyellow:Int = 0xADFF2F;
    public static var grey:Int = 0x808080;
    public static var honeydew:Int = 0xF0FFF0;
    public static var hotpink:Int = 0xFF69B4;
    public static var indianred:Int = 0xCD5C5C;
    public static var indigo:Int = 0x4B0082;
    public static var ivory:Int = 0xFFFFF0;
    public static var khaki:Int = 0xF0E68C;
    public static var lavender:Int = 0xE6E6FA;
    public static var lavenderblush:Int = 0xFFF0F5;
    public static var lawngreen:Int = 0x7CFC00;
    public static var lemonchiffon:Int = 0xFFFACD;
    public static var lightblue:Int = 0xADD8E6;
    public static var lightcoral:Int = 0xF08080;
    public static var lightcyan:Int = 0xE0FFFF;
    public static var lightgoldenrodyellow:Int = 0xFAFAD2;
    public static var lightgray:Int = 0xD3D3D3;
    public static var lightgreen:Int = 0x90EE90;
    public static var lightgrey:Int = 0xD3D3D3;
    public static var lightpink:Int = 0xFFB6C1;
    public static var lightsalmon:Int = 0xFFA07A;
    public static var lightseagreen:Int = 0x20B2AA;
    public static var lightskyblue:Int = 0x87CEFA;
    public static var lightslategray:Int = 0x778899;
    public static var lightslategrey:Int = 0x778899;
    public static var lightsteelblue:Int = 0xB0C4DE;
    public static var lightyellow:Int = 0xFFFFE0;
    public static var lime:Int = 0x00FF00;
    public static var limegreen:Int = 0x32CD32;
    public static var linen:Int = 0xFAF0E6;
    public static var magenta:Int = 0xFF00FF;
    public static var maroon:Int = 0x800000;
    public static var mediumaquamarine:Int = 0x66CDAA;
    public static var mediumblue:Int = 0x0000CD;
    public static var mediumorchid:Int = 0xBA55D3;
    public static var mediumpurple:Int = 0x9370DB;
    public static var mediumseagreen:Int = 0x3CB371;
    public static var mediumslateblue:Int = 0x7B68EE;
    public static var mediumspringgreen:Int = 0x00FA9A;
    public static var mediumturquoise:Int = 0x48D1CC;
    public static var mediumvioletred:Int = 0xC71585;
    public static var midnightblue:Int = 0x191970;
    public static var mintcream:Int = 0xF5FFFA;
    public static var mistyrose:Int = 0xFFE4E1;
    public static var moccasin:Int = 0xFFE4B5;
    public static var navajowhite:Int = 0xFFDEAD;
    public static var navy:Int = 0x000080;
    public static var oldlace:Int = 0xFDF5E6;
    public static var olive:Int = 0x808000;
    public static var olivedrab:Int = 0x6B8E23;
    public static var orange:Int = 0xFFA500;
    public static var orangered:Int = 0xFF4500;
    public static var orchid:Int = 0xDA70D6;
    public static var palegoldenrod:Int = 0xEEE8AA;
    public static var palegreen:Int = 0x98FB98;
    public static var paleturquoise:Int = 0xAFEEEE;
    public static var palevioletred:Int = 0xDB7093;
    public static var papayawhip:Int = 0xFFEFD5;
    public static var peachpuff:Int = 0xFFDAB9;
    public static var peru:Int = 0xCD853F;
    public static var pink:Int = 0xFFC0CB;
    public static var plum:Int = 0xDDA0DD;
    public static var powderblue:Int = 0xB0E0E6;
    public static var purple:Int = 0x800080;
    public static var rebeccapurple:Int = 0x663399;
    public static var red:Int = 0xFF0000;
    public static var rosybrown:Int = 0xBC8F8F;
    public static var royalblue:Int = 0x4169E1;
    public static var saddlebrown:Int = 0x8B4513;
    public static var salmon:Int = 0xFA8072;
    public static var sandybrown:Int = 0xF4A460;
    public static var seagreen:Int = 0x2E8B57;
    public static var seashell:Int = 0xFFF5EE;
    public static var sienna:Int = 0xA0522D;
    public static var silver:Int = 0xC0C0C0;
    public static var skyblue:Int = 0x87CEEB;
    public static var slateblue:Int = 0x6A5ACD;
    public static var slategray:Int = 0x708090;
    public static var slategrey:Int = 0x708090;
    public static var snow:Int = 0xFFFAFA;
    public static var springgreen:Int = 0x00FF7F;
    public static var steelblue:Int = 0x4682B4;
    public static var tan:Int = 0xD2B48C;
    public static var teal:Int = 0x008080;
    public static var thistle:Int = 0xD8BFD8;
    public static var tomato:Int = 0xFF6347;
    public static var turquoise:Int = 0x40E0D0;
    public static var violet:Int = 0xEE82EE;
    public static var wheat:Int = 0xF5DEB3;
    public static var white:Int = 0xFFFFFF;
    public static var whitesmoke:Int = 0xF5F5F5;
    public static var yellow:Int = 0xFFFF00;
    public static var yellowgreen:Int = 0x9ACD32;
}

class _hslA {
    public var h:Float = 0;
    public var s:Float = 0;
    public var l:Float = 0;
}

class _hslB {
    public var h:Float = 0;
    public var s:Float = 0;
    public var l:Float = 0;
}

function hue2rgb(p:Float, q:Float, t:Float):Float {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * 6 * (2 / 3 - t);
    return p;
}