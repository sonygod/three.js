import three.math.MathUtils.clamp;
import three.math.MathUtils.euclideanModulo;
import three.math.MathUtils.lerp;
import three.core.ColorManagement;
import three.core.ColorManagement.SRGBToLinear;
import three.core.ColorManagement.LinearToSRGB;
import three.constants.SRGBColorSpace;

class Color {
    public var isColor:Bool = true;
    public var r:Float;
    public var g:Float;
    public var b:Float;

    private static var _colorKeywords:Map<String, Int> = [
        'aliceblue' => 0xF0F8FF, 'antiquewhite' => 0xFAEBD7, 'aqua' => 0x00FFFF, 'aquamarine' => 0x7FFFD4, 'azure' => 0xF0FFFF,
        'beige' => 0xF5F5DC, 'bisque' => 0xFFE4C4, 'black' => 0x000000, 'blanchedalmond' => 0xFFEBCD, 'blue' => 0x0000FF, 
        // Add the remaining color keywords here
    ];

    private static var _hslA = { h: 0.0, s: 0.0, l: 0.0 };
    private static var _hslB = { h: 0.0, s: 0.0, l: 0.0 };

    public function new(?r:Dynamic, ?g:Dynamic, ?b:Dynamic) {
        this.r = 1;
        this.g = 1;
        this.b = 1;
        this.set(r, g, b);
    }

    public function set(r:Dynamic, ?g:Dynamic, ?b:Dynamic):Color {
        if (g == null && b == null) {
            // r is Color, hex or string
            var value = r;
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

    public function setHex(hex:Int, colorSpace:Dynamic = SRGBColorSpace):Color {
        hex = Std.int(hex);
        this.r = ((hex >> 16) & 255) / 255;
        this.g = ((hex >> 8) & 255) / 255;
        this.b = (hex & 255) / 255;
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setRGB(r:Float, g:Float, b:Float, colorSpace:Dynamic = ColorManagement.workingColorSpace):Color {
        this.r = r;
        this.g = g;
        this.b = b;
        ColorManagement.toWorkingColorSpace(this, colorSpace);
        return this;
    }

    public function setHSL(h:Float, s:Float, l:Float, colorSpace:Dynamic = ColorManagement.workingColorSpace):Color {
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

    public function setStyle(style:String, colorSpace:Dynamic = SRGBColorSpace):Color {
        var handleAlpha = function(string:String) {
            if (string == null) return;
            if (Std.parseFloat(string) < 1) {
                trace('THREE.Color: Alpha component of ' + style + ' will be ignored.');
            }
        };

        var regex:EReg;
        if ((regex = ~/\w+\(([^\)]*)\)/).match(style)) {
            var components = regex.matched(1);
            var color:Dynamic;

            switch (regex.matched(0)) {
                case 'rgb':
                case 'rgba':
                    if ((color = ~/\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?/).match(components)) {
                        handleAlpha(color[4]);
                        return this.setRGB(
                            Math.min(255, Std.parseInt(color[1])) / 255,
                            Math.min(255, Std.parseInt(color[2])) / 255,
                            Math.min(255, Std.parseInt(color[3])) / 255,
                            colorSpace
                        );
                    }

                    if ((color = ~/\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?/).match(components)) {
                        handleAlpha(color[4]);
                        return this.setRGB(
                            Math.min(100, Std.parseInt(color[1])) / 100,
                            Math.min(100, Std.parseInt(color[2])) / 100,
                            Math.min(100, Std.parseInt(color[3])) / 100,
                            colorSpace
                        );
                    }
                    break;

                case 'hsl':
                case 'hsla':
                    if ((color = ~/\s*(\d*\.?\d+)\s*,\s*(\d*\.?\d+)\%\s*,\s*(\d*\.?\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?/).match(components)) {
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
        } else if ((regex = ~/\#([A-Fa-f\d]+)/).match(style)) {
            var hex = regex.matched(1);
            switch (hex.length) {
                case 3:
                    return this.setRGB(
                        Std.parseInt(hex.charAt(0), 16) / 15,
                        Std.parseInt(hex.charAt(1), 16) / 15,
                        Std.parseInt(hex.charAt(2), 16) / 15,
                        colorSpace
                    );
                case 6:
                    return this.setHex(Std.parseInt(hex, 16), colorSpace);
                default:
                    trace('THREE.Color: Invalid hex color ' + style);
            }
        } else if (style != null && style.length > 0) {
            return this.setColorName(style, colorSpace);
        }
        return this;
    }

    public function setColorName(style:String, colorSpace:Dynamic = SRGBColorSpace):Color {
        var hex = _colorKeywords.get(style.toLowerCase());
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

    public function getHex(colorSpace:Dynamic = SRGBColorSpace):Int {
        var _color = new Color();
        ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
        return Math.round(clamp(_color.r * 255, 0, 255)) * 65536 + Math.round(clamp(_color.g * 255, 0, 255)) * 256 + Math.round(clamp(_color.b * 255, 0, 255));
    }

    public function getHexString(colorSpace:Dynamic = SRGBColorSpace):String {
        return StringTools.hex(this.getHex(colorSpace), 6);
    }

    public function getHSL(target:Dynamic = null):Dynamic {
        if (target == null) {
            target = { h: 0.0, s: 0.0, l: 0.0 };
        }
        var r = this.r, g = this.g, b = this.b;
        var max = Math.max(r, g, b);
        var min = Math.min(r, g, b);

        var hue:Float, saturation:Float;
        var lightness:Float = (min + max) / 2.0;

        if (min == max) {
            hue = 0;
            saturation = 0;
        } else {
            var delta = max - min;
            saturation = lightness <= 0.5 ? delta / (max + min) : delta / (2 - max - min);

            switch (max) {
                case r:
                    hue = (g - b) / delta + (g < b ? 6 : 0);
                    break;
                case g:
                    hue = (b - r) / delta + 2;
                    break;
                case b:
                    hue = (r - g) / delta + 4;
                    break;
            }
            hue /= 6;
        }

        target.h = hue;
        target.s = saturation;
        target.l = lightness;

        return target;
    }

    private function hue2rgb(p:Float, q:Float, t:Float):Float {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
    }
}