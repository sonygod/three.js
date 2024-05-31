import three.math.MathUtils;
import three.math.ColorManagement;
import three.constants.SRGBColorSpace;

class Color {
	public var isColor:Bool = true;
	public var r:Float = 1.0;
	public var g:Float = 1.0;
	public var b:Float = 1.0;

	public function new(?r:Dynamic, ?g:Dynamic, ?b:Dynamic) {
		if (g == null && b == null) {
			if (r != null && r.isColor) {
				this.copy(r);
			} else if (Std.is(r, Int)) {
				this.setHex(r);
			} else if (Std.is(r, String)) {
				this.setStyle(r);
			}
		} else {
			this.setRGB(r, g, b);
		}
	}

	public function set(?r:Dynamic, ?g:Dynamic, ?b:Dynamic):Color {
		if (g == null && b == null) {
			if (r != null && r.isColor) {
				this.copy(r);
			} else if (Std.is(r, Int)) {
				this.setHex(r);
			} else if (Std.is(r, String)) {
				this.setStyle(r);
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

	public function setHex(hex:Int, colorSpace:SRGBColorSpace = SRGBColorSpace):Color {
		hex = Math.floor(hex);
		this.r = (hex >> 16 & 255) / 255;
		this.g = (hex >> 8 & 255) / 255;
		this.b = (hex & 255) / 255;
		ColorManagement.toWorkingColorSpace(this, colorSpace);
		return this;
	}

	public function setRGB(r:Float, g:Float, b:Float, colorSpace:ColorManagement.ColorSpace = ColorManagement.workingColorSpace):Color {
		this.r = r;
		this.g = g;
		this.b = b;
		ColorManagement.toWorkingColorSpace(this, colorSpace);
		return this;
	}

	public function setHSL(h:Float, s:Float, l:Float, colorSpace:ColorManagement.ColorSpace = ColorManagement.workingColorSpace):Color {
		h = MathUtils.euclideanModulo(h, 1);
		s = MathUtils.clamp(s, 0, 1);
		l = MathUtils.clamp(l, 0, 1);
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

	public function setStyle(style:String, colorSpace:SRGBColorSpace = SRGBColorSpace):Color {
		var m = style.match(/(\w+)\(([^)]*)\)/);
		if (m != null) {
			var color:String;
			var name:String = m[1];
			var components:String = m[2];
			switch(name) {
			case "rgb":
			case "rgba":
				color = components.match(/^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?$/);
				if (color != null) {
					handleAlpha(color[4]);
					return this.setRGB(
						Math.min(255, Std.parseInt(color[1])) / 255,
						Math.min(255, Std.parseInt(color[2])) / 255,
						Math.min(255, Std.parseInt(color[3])) / 255,
						colorSpace
					);
				}
				color = components.match(/^\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/);
				if (color != null) {
					handleAlpha(color[4]);
					return this.setRGB(
						Math.min(100, Std.parseInt(color[1])) / 100,
						Math.min(100, Std.parseInt(color[2])) / 100,
						Math.min(100, Std.parseInt(color[3])) / 100,
						colorSpace
					);
				}
				break;
			case "hsl":
			case "hsla":
				color = components.match(/^\s*(\d*\.?\d+)\s*,\s*(\d*\.?\d+)\%\s*,\s*(\d*\.?\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/);
				if (color != null) {
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
				Sys.println("THREE.Color: Unknown color model " + style);
			}
		} else if (m = style.match(/^\#([A-Fa-f\d]+)$/)) {
			var hex:String = m[1];
			var size:Int = hex.length;
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
				Sys.println("THREE.Color: Invalid hex color " + style);
			}
		} else if (style.length > 0) {
			return this.setColorName(style, colorSpace);
		}
		return this;
	}

	public function setColorName(style:String, colorSpace:SRGBColorSpace = SRGBColorSpace):Color {
		var hex:Int = Color.NAMES[style.toLowerCase()];
		if (hex != null) {
			this.setHex(hex, colorSpace);
		} else {
			Sys.println("THREE.Color: Unknown color " + style);
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
		this.r = ColorManagement.SRGBToLinear(color.r);
		this.g = ColorManagement.SRGBToLinear(color.g);
		this.b = ColorManagement.SRGBToLinear(color.b);
		return this;
	}

	public function copyLinearToSRGB(color:Color):Color {
		this.r = ColorManagement.LinearToSRGB(color.r);
		this.g = ColorManagement.LinearToSRGB(color.g);
		this.b = ColorManagement.LinearToSRGB(color.b);
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

	public function getHex(colorSpace:SRGBColorSpace = SRGBColorSpace):Int {
		ColorManagement.fromWorkingColorSpace(new Color().copy(this), colorSpace);
		return Math.round(MathUtils.clamp(_color.r * 255, 0, 255)) * 65536 + Math.round(MathUtils.clamp(_color.g * 255, 0, 255)) * 256 + Math.round(MathUtils.clamp(_color.b * 255, 0, 255));
	}

	public function getHexString(colorSpace:SRGBColorSpace = SRGBColorSpace):String {
		return ("000000" + this.getHex(colorSpace).toString(16)).substr(-6);
	}

	public function getHSL(target:Dynamic, colorSpace:ColorManagement.ColorSpace = ColorManagement.workingColorSpace):Dynamic {
		ColorManagement.fromWorkingColorSpace(new Color().copy(this), colorSpace);
		var r = _color.r;
		var g = _color.g;
		var b = _color.b;
		var max = Math.max(r, g, b);
		var min = Math.min(r, g, b);
		var hue:Float, saturation:Float;
		var lightness = (min + max) / 2.0;
		if (min == max) {
			hue = 0;
			saturation = 0;
		} else {
			var delta = max - min;
			saturation = lightness <= 0.5 ? delta / (max + min) : delta / (2 - max - min);
			switch(max) {
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

	public function getRGB(target:Dynamic, colorSpace:ColorManagement.ColorSpace = ColorManagement.workingColorSpace):Dynamic {
		ColorManagement.fromWorkingColorSpace(new Color().copy(this), colorSpace);
		target.r = _color.r;
		target.g = _color.g;
		target.b = _color.b;
		return target;
	}

	public function getStyle(colorSpace:SRGBColorSpace = SRGBColorSpace):String {
		ColorManagement.fromWorkingColorSpace(new Color().copy(this), colorSpace);
		var r = _color.r;
		var g = _color.g;
		var b = _color.b;
		if (colorSpace != SRGBColorSpace) {
			return "color(${colorSpace} ${r.toFixed(3)} ${g.toFixed(3)} ${b.toFixed(3)})";
		}
		return "rgb(${Math.round(r * 255)},${Math.round(g * 255)},${Math.round(b * 255)})";
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
		var h:Float = MathUtils.lerp(_hslA.h, _hslB.h, alpha);
		var s:Float = MathUtils.lerp(_hslA.s, _hslB.s, alpha);
		var l:Float = MathUtils.lerp(_hslA.l, _hslB.l, alpha);
		this.setHSL(h, s, l);
		return this;
	}

	public function setFromVector3(v:Dynamic):Color {
		this.r = v.x;
		this.g = v.y;
		this.b = v.z;
		return this;
	}

	public function applyMatrix3(m:Dynamic):Color {
		var r = this.r;
		var g = this.g;
		var b = this.b;
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

	public function fromBufferAttribute(attribute:Dynamic, index:Int):Color {
		this.r = attribute.getX(index);
		this.g = attribute.getY(index);
		this.b = attribute.getZ(index);
		return this;
	}

	public function toJSON():Int {
		return this.getHex();
	}

	public function iterator():Iterator<Float> {
		return new haxe.iterators.ArrayIterator([this.r, this.g, this.b]);
	}

	static public var NAMES:Map<String, Int> = _colorKeywords;

	static private function handleAlpha(string:String):Void {
		if (string == null) return;
		if (Std.parseFloat(string) < 1) {
			Sys.println("THREE.Color: Alpha component of " + string + " will be ignored.");
		}
	}

	static private function hue2rgb(p:Float, q:Float, t:Float):Float {
		if (t < 0) t += 1;
		if (t > 1) t -= 1;
		if (t < 1 / 6) return p + (q - p) * 6 * t;
		if (t < 1 / 2) return q;
		if (t < 2 / 3) return p + (q - p) * 6 * (2 / 3 - t);
		return p;
	}

	static private var _colorKeywords:Map<String, Int> = {
		"aliceblue": 0xF0F8FF,
		"antiquewhite": 0xFAEBD7,
		"aqua": 0x00FFFF,
		"aquamarine": 0x7FFFD4,
		"azure": 0xF0FFFF,
		"beige": 0xF5F5DC,
		"bisque": 0xFFE4C4,
		"black": 0x000000,
		"blanchedalmond": 0xFFEBCD,
		"blue": 0x0000FF,
		"blueviolet": 0x8A2BE2,
		"brown": 0xA52A2A,
		"burlywood": 0xDEB887,
		"cadetblue": 0x5F9EA0,
		"chartreuse": 0x7FFF00,
		"chocolate": 0xD2691E,
		"coral": 0xFF7F50,
		"cornflowerblue": 0x6495ED,
		"cornsilk": 0xFFF8DC,
		"crimson": 0xDC143C,
		"cyan": 0x00FFFF,
		"darkblue": 0x00008B,
		"darkcyan": 0x008B8B,
		"darkgoldenrod": 0xB8860B,
		"darkgray": 0xA9A9A9,
		"darkgreen": 0x006400,
		"darkgrey": 0xA9A9A9,
		"darkkhaki": 0xBDB76B,
		"darkmagenta": 0x8B008B,
		"darkolivegreen": 0x556B2F,
		"darkorange": 0xFF8C00,
		"darkorchid": 0x9932CC,
		"darkred": 0x8B0000,
		"darksalmon": 0xE9967A,
		"darkseagreen": 0x8FBC8F,
		"darkslateblue": 0x483D8B,
		"darkslategray": 0x2F4F4F,
		"darkslategrey": 0x2F4F4F,
		"darkturquoise": 0x00CED1,
		"darkviolet": 0x9400D3,
		"deeppink": 0xFF1493,
		"deepskyblue": 0x00BFFF,
		"dimgray": 0x696969,
		"dimgrey": 0x696969,
		"dodgerblue": 0x1E90FF,
		"firebrick": 0xB22222,
		"floralwhite": 0xFFFAF0,
		"forestgreen": 0x228B22,
		"fuchsia": 0xFF00FF,
		"gainsboro": 0xDCDCDC,
		"ghostwhite": 0xF8F8FF,
		"gold": 0xFFD700,
		"goldenrod": 0xDAA520,
		"gray": 0x808080,
		"green": 0x008000,
		"greenyellow": 0xADFF2F,
		"grey": 0x808080,
		"honeydew": 0xF0FFF0,
		"hotpink": 0xFF69B4,
		"indianred": 0xCD5C5C,
		"indigo": 0x4B0082,
		"ivory": 0xFFFFF0,
		"khaki": 0xF0E68C,
		"lavender": 0xE6E6FA,
		"lavenderblush": 0xFFF0F5,
		"lawngreen": 0x7CFC00,
		"lemonchiffon": 0xFFFACD,
		"lightblue": 0xADD8E6,
		"lightcoral": 0xF08080,
		"lightcyan": 0xE0FFFF,
		"lightgoldenrodyellow": 0xFAFAD2,
		"lightgray": 0xD3D3D3,
		"lightgreen": 0x90EE90,
		"lightgrey": 0xD3D3D3,
		"lightpink": 0xFFB6C1,
		"lightsalmon": 0xFFA07A,
		"lightseagreen": 0x20B2AA,
		"lightskyblue": 0x87CEFA,
		"lightslategray": 0x778899,
		"lightslategrey": 0x778899,
		"lightsteelblue": 0xB0C4DE,
		"lightyellow": 0xFFFFE0,
		"lime": 0x00FF00,
		"limegreen": 0x32CD32,
		"linen": 0xFAF0E6,
		"magenta": 0xFF00FF,
		"maroon": 0x800000,
		"mediumaquamarine": 0x66CDAA,
		"mediumblue": 0x0000CD,
		"mediumorchid": 0xBA55D3,
		"mediumpurple": 0x9370DB,
		"mediumseagreen": 0x3CB371,
		"mediumslateblue": 0x7B68EE,
		"mediumspringgreen": 0x00FA9A,
		"mediumturquoise": 0x48D1CC,
		"mediumvioletred": 0xC71585,
		"midnightblue": 0x191970,
		"mintcream": 0xF5FFFA,
		"mistyrose": 0xFFE4E1,
		"moccasin": 0xFFE4B5,
		"navajowhite": 0xFFDEAD,
		"navy": 0x000080,
		"oldlace": 0xFDF5E6,
		"olive": 0x808000,
		"olivedrab": 0x6B8E23,
		"orange": 0xFFA500,
		"orangered": 0xFF4500,
		"orchid": 0xDA70D6,
		"palegoldenrod": 0xEEE8AA,
		"palegreen": 0x98FB98,
		"paleturquoise": 0xAFEEEE,
		"palevioletred": 0xDB7093,
		"papayawhip": 0xFFEFD5,
		"peachpuff": 0xFFDAB9,
		"peru": 0xCD853F,
		"pink": 0xFFC0CB,
		"plum": 0xDDA0DD,
		"powderblue": 0xB0E0E6,
		"purple": 0x800080,
		"rebeccapurple": 0x663399,
		"red": 0xFF0000,
		"rosybrown": 0xBC8F8F,
		"royalblue": 0x4169E1,
		"saddlebrown": 0x8B4513,
		"salmon": 0xFA8072,
		"sandybrown": 0xF4A460,
		"seagreen": 0x2E8B57,
		"seashell": 0xFFF5EE,
		"sienna": 0xA0522D,
		"silver": 0xC0C0C0,
		"skyblue": 0x87CEEB,
		"slateblue": 0x6A5ACD,
		"slategray": 0x708090,
		"slategrey": 0x708090,
		"snow": 0xFFFAFA,
		"springgreen": 0x00FF7F,
		"steelblue": 0x4682B4,
		"tan": 0xD2B48C,
		"teal": 0x008080,
		"thistle": 0xD8BFD8,
		"tomato": 0xFF6347,
		"turquoise": 0x40E0D0,
		"violet": 0xEE82EE,
		"wheat": 0xF5DEB3,
		"white": 0xFFFFFF,
		"whitesmoke": 0xF5F5F5,
		"yellow": 0xFFFF00,
		"yellowgreen": 0x9ACD32
	};

	static private var _hslA:Dynamic = {h: 0, s: 0, l: 0};
	static private var _hslB:Dynamic = {h: 0, s: 0, l: 0};

	static private var _color:Color = new Color();
}