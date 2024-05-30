import MathUtils.*;
import ColorManagement.*;
import constants.SRGBColorSpace;

class Color {
    public var isColor:Bool;
    public var r:Float;
    public var g:Float;
    public var b:Float;

    public static var NAMES:Map<String, Int>;

    private static var _hslA:{ var h:Float; var s:Float; var l:Float; } = { h: 0, s: 0, l: 0 };
    private static var _hslB:{ var h:Float; var s:Float; var l:Float; } = { h: 0, s: 0, l: 0 };
    private static var _color:Color = new Color();

    public function new(r:Dynamic = 1, g:Float = 1, b:Float = 1) {
        isColor = true;
        this.r = 1;
        this.g = 1;
        this.b = 1;
        set(r, g, b);
    }

    public function set(r:Dynamic, g:Float = null, b:Float = null):Color {
        if (g == null && b == null) {
            // r is Color, hex or string
            var value:Dynamic = r;
            if (value != null && value.isColor) {
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

    public function setHex(hex:Int, colorSpace:String = SRGBColorSpace):Color {
        hex = Std.int(hex);
        this.r = ((hex >> 16) & 255) / 255;
        this.g = ((hex >> 8) & 255) / 255;
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
        h = euclideanModulo(h, 1);
        s = clamp(s, 0, 1);
        l = clamp(l, 0, 1);

        if (s == 0) {
            this.r = this.g = this.b = l;
        } else {
            var p = (l <= 0.5) ? (l * (1 + s)) : (l + s - (l * s));
            var q = (2 * l) - p;
            this.r = hue2rgb(q, p, h + 1 / 3);
            this.g = hue2rgb(q, p, h);
            this.b = hue2rgb(q, p, h - 1 / 3);
        }

        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setStyle(style:String, colorSpace:String = SRGBColorSpace):Color {
        function handleAlpha(string:String):Void {
            if (string == null) return;
            if (Std.parseFloat(string) < 1) {
                trace('THREE.Color: Alpha component of ' + style + ' will be ignored.');
            }
        }

        var m:EReg;

        if (m.match("^\\w+\\(([^\\)]*)\\)")) {
            var color:Dynamic;
            var name = m.matched(1);
            var components = m.matched(2);

            switch (name) {
                case 'rgb':
                case 'rgba':
                    if (color.match("^\\s*(\\d+)\\s*,\\s*(\\d+)\\s*,\\s*(\\d+)\\s*(?:,\\s*(\\d*\\.?\\d+)\\s*)?$")) {
                        handleAlpha(color.matched(4));
                        return this.setRGB(
                            Math.min(255, Std.parseInt(color.matched(1))) / 255,
                            Math.min(255, Std.parseInt(color.matched(2))) / 255,
                            Math.min(255, Std.parseInt(color.matched(3))) / 255,
                            colorSpace
                        );
                    }
                    if (color.match("^\\s*(\\d+)%\\s*,\\s*(\\d+)%\\s*,\\s*(\\d+)%\\s*(?:,\\s*(\\d*\\.?\\d+)\\s*)?$")) {
                        handleAlpha(color.matched(4));
                        return this.setRGB(
                            Math.min(100, Std.parseInt(color.matched(1))) / 100,
                            Math.min(100, Std.parseInt(color.matched(2))) / 100,
                            Math.min(100, Std.parseInt(color.matched(3))) / 100,
                            colorSpace
                        );
                    }
                    break;

                case 'hsl':
                case 'hsla':
                    if (color.match("^\\s*(\\d*\\.?\\d+)\\s*,\\s*(\\d*\\.?\\d+)%\\s*,\\s*(\\d*\\.?\\d+)%\\s*(?:,\\s*(\\d*\\.?\\d+)\\s*)?$")) {
                        handleAlpha(color.matched(4));
                        return this.setHSL(
                            Std.parseFloat(color.matched(1)) / 360,
                            Std.parseFloat(color.matched(2)) / 100,
                            Std.parseFloat(color.matched(3)) / 100,
                            colorSpace
                        );
                    }
                    break;

                default:
                    trace('THREE.Color: Unknown color model ' + style);
            }

        } else if (m.match("^\\#([A-Fa-f\\d]+)$")) {
            var hex = m.matched(1);
            var size = hex.length;

            if (size == 3) {
                return this.setRGB(
                    Std.parseInt(hex.charAt(0), 16) / 15,
                    Std.parseInt(hex.charAt(1), 16) / 15,
                    Std.parseInt(hex.charAt(2), 16) / 15,
                    colorSpace
                );
            } else if (size == 6) {
                return this.setHex(Std.parseInt(hex, 16), colorSpace);
            } else {
                trace('THREE.Color: Invalid hex color ' + style);
            }

        } else if (style != null && style.length > 0) {
            return this.setColorName(style, colorSpace);
        }

        return this;
    }

    public function setColorName(style:String, colorSpace:String = SRGBColorSpace):Color {
        var hex = Color.NAMES.get(style.toLowerCase());
        if (hex != null) {
            this.setHex(hex, colorSpace);
        } else {
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
        return this.copySRGBToLinear(this);
    }

    public function convertLinearToSRGB():Color {
        return this.copyLinearToSRGB(this);
    }

    public function getHex(colorSpace:String = SRGBColorSpace):Int {
        ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
        return Math.round(clamp(_color.r * 255, 0, 255)) * 65536 +
               Math.round(clamp(_color.g * 255, 0, 255)) * 256 +
               Math.round(clamp(_color.b * 255, 0, 255));
    }

    public function getHexString(colorSpace:String = SRGBColorSpace):String {
        return StringTools.lpad(Std.string(this.getHex(colorSpace)), "0", 6);
    }

    public function getHSL(target:{ var h:Float; var s:Float; var l:Float }, colorSpace:String = ColorManagement.workingColorSpace):Dynamic {
        ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
        var r = _color.r;
        var g = _color.g;
        var b = _color.b;
        var max = Math.max(r, g, b);
        var min = Math.min(r, g, b);

        var hue:Float;
        var saturation:Float;
        var lightness:Float = (min + max) / 2;

        if (min == max) {
            hue = 0;
            saturation = 0;
        } else {
            var delta = max - min;

            saturation = (lightness <= 0.5) ? (delta / (max + min)) : (delta / (2 - max - min));

            switch (max) {
                case r: hue = (g - b) / delta + ((g < b) ? 6 : 0); break;
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

    public function getStyle(colorSpace:String = SRGBColorSpace):String {
        return 'rgb(' + Math.round(clamp(this.r * 255, 0, 255)) + ',' +
                      Math.round(clamp(this.g * 255, 0, 255)) + ',' +
                      Math.round(clamp(this.b * 255, 0, 255)) + ')';
    }
}

class MathUtils {
    public static function euclideanModulo(n:Float, m:Float):Float {
        return ((n % m) + m) % m;
    }

    public static function clamp(value:Float, min:Float, max:Float):Float {
        return Math.max(min, Math.min(max, value));
    }

    public static function hue2rgb(p:Float, q:Float, t:Float):Float {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
    }
}

class ColorManagement {
    public static var SRGBColorSpace:String = "srgb";
    public static var workingColorSpace:String = SRGBColorSpace;

    public static function toWorkingColorSpace(color:Color, colorSpace:String):Void {
        // Implement color space conversion logic here
    }

    public static function fromWorkingColorSpace(color:Color, colorSpace:String):Void {
        // Implement color space conversion logic here
    }

    public static function SRGBToLinear(value:Float):Float {
        return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
    }

    public static function LinearToSRGB(value:Float):Float {
        return value <= 0.0031308 ? value * 12.92 : 1.055 * Math.pow(value, 1.0 / 2.4) - 0.055;
    }
}

class Main {
    static public function main() {
        var color = new Color();
        color.setStyle("rgb(255,0,0)");
        trace(color.getStyle());
    }
}