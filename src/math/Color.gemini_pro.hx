import MathUtils;
import ColorManagement;
import ColorSpace;

class Color {
	public var isColor:Bool = true;
	public var r:Float = 1.0;
	public var g:Float = 1.0;
	public var b:Float = 1.0;

	public function new(r:Float, g:Float, b:Float) {
		this.set(r, g, b);
	}

	public function set(r:Dynamic, g:Dynamic = null, b:Dynamic = null):Color {
		if (g == null && b == null) {
			if (r != null && Std.is(r, Color)) {
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

	public function setHex(hex:Int, colorSpace:ColorSpace = ColorSpace.SRGB):Color {
		hex = Math.floor(hex);
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

	public function setStyle(style:String, colorSpace:ColorSpace = ColorSpace.SRGB):Color {
		var m = style.match(/(\\w+)\\(([\\^\\)]*)\\)/);
		if (m != null) {
			// rgb / hsl
			var name = m[1];
			var components = m[2];
			switch (name) {
				case "rgb":
				case "rgba":
					var color = components.match(/\\s*(\\d+)\\s*,\\s*(\\d+)\\s*,\\s*(\\d+)\\s*(?:,\\s*(\\d*\\.?\\d+)\\s*)?/);
					if (color != null) {
						// rgb(255,0,0) rgba(255,0,0,0.5)
						if (color[4] != null) {
							if (Float.parseFloat(color[4]) < 1) {
								Sys.warning("THREE.Color: Alpha component of " + style + " will be ignored.");
							}
						}
						return this.setRGB(
							Math.min(255, Int.parseInt(color[1])) / 255,
							Math.min(255, Int.parseInt(color[2])) / 255,
							Math.min(255, Int.parseInt(color[3])) / 255,
							colorSpace
						);
					}
					color = components.match(/\\s*(\\d+)\\%\\s*,\\s*(\\d+)\\%\\s*,\\s*(\\d+)\\%\\s*(?:,\\s*(\\d*\\.?\\d+)\\s*)?/);
					if (color != null) {
						// rgb(100%,0%,0%) rgba(100%,0%,0%,0.5)
						if (color[4] != null) {
							if (Float.parseFloat(color[4]) < 1) {
								Sys.warning("THREE.Color: Alpha component of " + style + " will be ignored.");
							}
						}
						return this.setRGB(
							Math.min(100, Int.parseInt(color[1])) / 100,
							Math.min(100, Int.parseInt(color[2])) / 100,
							Math.min(100, Int.parseInt(color[3])) / 100,
							colorSpace
						);
					}
					break;
				case "hsl":
				case "hsla":
					color = components.match(/\\s*(\\d*\\.?\\d+)\\s*,\\s*(\\d*\\.?\\d+)\\%\\s*,\\s*(\\d*\\.?\\d+)\\%\\s*(?:,\\s*(\\d*\\.?\\d+)\\s*)?/);
					if (color != null) {
						// hsl(120,50%,50%) hsla(120,50%,50%,0.5)
						if (color[4] != null) {
							if (Float.parseFloat(color[4]) < 1) {
								Sys.warning("THREE.Color: Alpha component of " + style + " will be ignored.");
							}
						}
						return this.setHSL(
							Float.parseFloat(color[1]) / 360,
							Float.parseFloat(color[2]) / 100,
							Float.parseFloat(color[3]) / 100,
							colorSpace
						);
					}
					break;
				default:
					Sys.warning("THREE.Color: Unknown color model " + style);
			}
		} else if (m = style.match(/\\#([A-Fa-f\\d]+)/)) {
			// hex color
			var hex = m[1];
			var size = hex.length;
			if (size == 3) {
				// #ff0
				return this.setRGB(
					Int.parseInt(hex.charAt(0), 16) / 15,
					Int.parseInt(hex.charAt(1), 16) / 15,
					Int.parseInt(hex.charAt(2), 16) / 15,
					colorSpace
				);
			} else if (size == 6) {
				// #ff0000
				return this.setHex(Int.parseInt(hex, 16), colorSpace);
			} else {
				Sys.warning("THREE.Color: Invalid hex color " + style);
			}
		} else if (style.length > 0) {
			return this.setColorName(style, colorSpace);
		}
		return this;
	}

	public function setColorName(style:String, colorSpace:ColorSpace = ColorSpace.SRGB):Color {
		// color keywords
		var hex = _colorKeywords[style.toLowerCase()];
		if (hex != null) {
			// red
			this.setHex(hex, colorSpace);
		} else {
			// unknown color
			Sys.warning("THREE.Color: Unknown color " + style);
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

	public function getHex(colorSpace:ColorSpace = ColorSpace.SRGB):Int {
		ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
		return Math.round(MathUtils.clamp(_color.r * 255, 0, 255)) * 65536 + Math.round(MathUtils.clamp(_color.g * 255, 0, 255)) * 256 + Math.round(MathUtils.clamp(_color.b * 255, 0, 255));
	}

	public function getHexString(colorSpace:ColorSpace = ColorSpace.SRGB):String {
		return ("000000" + this.getHex(colorSpace).toString(16)).substr(- 6);
	}

	public function getHSL(target:Dynamic, colorSpace:ColorSpace = ColorManagement.workingColorSpace):Dynamic {
		ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
		var r = _color.r, g = _color.g, b = _color.b;
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

	public function getRGB(target:Dynamic, colorSpace:ColorSpace = ColorManagement.workingColorSpace):Dynamic {
		ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
		target.r = _color.r;
		target.g = _color.g;
		target.b = _color.b;
		return target;
	}

	public function getStyle(colorSpace:ColorSpace = ColorSpace.SRGB):String {
		ColorManagement.fromWorkingColorSpace(_color.copy(this), colorSpace);
		var r = _color.r, g = _color.g, b = _color.b;
		if (colorSpace != ColorSpace.SRGB) {
			return "color(" + colorSpace + " " + r.toFixed(3) + " " + g.toFixed(3) + " " + b.toFixed(3) + ")";
		}
		return "rgb(" + Math.round(r * 255) + "," + Math.round(g * 255) + "," + Math.round(b * 255) + ")";
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
		var h = MathUtils.lerp(_hslA.h, _hslB.h, alpha);
		var s = MathUtils.lerp(_hslA.s, _hslB.s, alpha);
		var l = MathUtils.lerp(_hslA.l, _hslB.l, alpha);
		this.setHSL(h, s, l);
		return this;
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

	public function equals(c:Color):Bool {
		return (c.r == this.r) && (c.g == this.g) && (c.b == this.b);
	}

	public function toJSON():Int {
		return this.getHex();
	}

	public function iterator():Iterator<Float> {
		return new haxe.iterators.ArrayIterator([this.r, this.g, this.b]);
	}
}

var _colorKeywords:Map<String, Int> = new Map<String, Int>();

_colorKeywords.set("aliceblue", 0xF0F8FF);
_colorKeywords.set("antiquewhite", 0xFAEBD7);
_colorKeywords.set("aqua", 0x00FFFF);
_colorKeywords.set("aquamarine", 0x7FFFD4);
_colorKeywords.set("azure", 0xF0FFFF);
_colorKeywords.set("beige", 0xF5F5DC);
_colorKeywords.set("bisque", 0xFFE4C4);
_colorKeywords.set("black", 0x000000);
_colorKeywords.set("blanchedalmond", 0xFFEBCD);
_colorKeywords.set("blue", 0x0000FF);
_colorKeywords.set("blueviolet", 0x8A2BE2);
_colorKeywords.set("brown", 0xA52A2A);
_colorKeywords.set("burlywood", 0xDEB887);
_colorKeywords.set("cadetblue", 0x5F9EA0);
_colorKeywords.set("chartreuse", 0x7FFF00);
_colorKeywords.set("chocolate", 0xD2691E);
_colorKeywords.set("coral", 0xFF7F50);
_colorKeywords.set("cornflowerblue", 0x6495ED);
_colorKeywords.set("cornsilk", 0xFFF8DC);
_colorKeywords.set("crimson", 0xDC143C);
_colorKeywords.set("cyan", 0x00FFFF);
_colorKeywords.set("darkblue", 0x00008B);
_colorKeywords.set("darkcyan", 0x008B8B);
_colorKeywords.set("darkgoldenrod", 0xB8860B);
_colorKeywords.set("darkgray", 0xA9A9A9);
_colorKeywords.set("darkgreen", 0x006400);
_colorKeywords.set("darkgrey", 0xA9A9A9);
_colorKeywords.set("darkkhaki", 0xBDB76B);
_colorKeywords.set("darkmagenta", 0x8B008B);
_colorKeywords.set("darkolivegreen", 0x556B2F);
_colorKeywords.set("darkorange", 0xFF8C00);
_colorKeywords.set("darkorchid", 0x9932CC);
_colorKeywords.set("darkred", 0x8B0000);
_colorKeywords.set("darksalmon", 0xE9967A);
_colorKeywords.set("darkseagreen", 0x8FBC8F);
_colorKeywords.set("darkslateblue", 0x483D8B);
_colorKeywords.set("darkslategray", 0x2F4F4F);
_colorKeywords.set("darkslategrey", 0x2F4F4F);
_colorKeywords.set("darkturquoise", 0x00CED1);
_colorKeywords.set("darkviolet", 0x9400D3);
_colorKeywords.set("deeppink", 0xFF1493);
_colorKeywords.set("deepskyblue", 0x00BFFF);
_colorKeywords.set("dimgray", 0x696969);
_colorKeywords.set("dimgrey", 0x696969);
_colorKeywords.set("dodgerblue", 0x1E90FF);
_colorKeywords.set("firebrick", 0xB22222);
_colorKeywords.set("floralwhite", 0xFFFAF0);
_colorKeywords.set("forestgreen", 0x228B22);
_colorKeywords.set("fuchsia", 0xFF00FF);
_colorKeywords.set("gainsboro", 0xDCDCDC);
_colorKeywords.set("ghostwhite", 0xF8F8FF);
_colorKeywords.set("gold", 0xFFD700);
_colorKeywords.set("goldenrod", 0xDAA520);
_colorKeywords.set("gray", 0x808080);
_colorKeywords.set("green", 0x008000);
_colorKeywords.set("greenyellow", 0xADFF2F);
_colorKeywords.set("grey", 0x808080);
_colorKeywords.set("honeydew", 0xF0FFF0);
_colorKeywords.set("hotpink", 0xFF69B4);
_colorKeywords.set("indianred", 0xCD5C5C);
_colorKeywords.set("indigo", 0x4B0082);
_colorKeywords.set("ivory", 0xFFFFF0);
_colorKeywords.set("khaki", 0xF0E68C);
_colorKeywords.set("lavender", 0xE6E6FA);
_colorKeywords.set("lavenderblush", 0xFFF0F5);
_colorKeywords.set("lawngreen", 0x7CFC00);
_colorKeywords.set("lemonchiffon", 0xFFFACD);
_colorKeywords.set("lightblue", 0xADD8E6);
_colorKeywords.set("lightcoral", 0xF08080);
_colorKeywords.set("lightcyan", 0xE0FFFF);
_colorKeywords.set("lightgoldenrodyellow", 0xFAFAD2);
_colorKeywords.set("lightgray", 0xD3D3D3);
_colorKeywords.set("lightgreen", 0x90EE90);
_colorKeywords.set("lightgrey", 0xD3D3D3);
_colorKeywords.set("lightpink", 0xFFB6C1);
_colorKeywords.set("lightsalmon", 0xFFA07A);
_colorKeywords.set("lightseagreen", 0x20B2AA);
_colorKeywords.set("lightskyblue", 0x87CEFA);
_colorKeywords.set("lightslategray", 0x778899);
_colorKeywords.set("lightslategrey", 0x778899);
_colorKeywords.set("lightsteelblue", 0xB0C4DE);
_colorKeywords.set("lightyellow", 0xFFFFE0);
_colorKeywords.set("lime", 0x00FF00);
_colorKeywords.set("limegreen", 0x32CD32);
_colorKeywords.set("linen", 0xFAF0E6);
_colorKeywords.set("magenta", 0xFF00FF);
_colorKeywords.set("maroon", 0x800000);
_colorKeywords.set("mediumaquamarine", 0x66CDAA);
_colorKeywords.set("mediumblue", 0x0000CD);
_colorKeywords.set("mediumorchid", 0xBA55D3);
_colorKeywords.set("mediumpurple", 0x9370DB);
_colorKeywords.set("mediumseagreen", 0x3CB371);
_colorKeywords.set("mediumslateblue", 0x7B68EE);
_colorKeywords.set("mediumspringgreen", 0x00FA9A);
_colorKeywords.set("mediumturquoise", 0x48D1CC);
_colorKeywords.set("mediumvioletred", 0xC71585);
_colorKeywords.set("midnightblue", 0x191970);
_colorKeywords.set("mintcream", 0xF5FFFA);
_colorKeywords.set("mistyrose", 0xFFE4E1);
_colorKeywords.set("moccasin", 0xFFE4B5);
_colorKeywords.set("navajowhite", 0xFFDEAD);
_colorKeywords.set("navy", 0x000080);
_colorKeywords.set("oldlace", 0xFDF5E6);
_colorKeywords.set("olive", 0x808000);
_colorKeywords.set("olivedrab", 0x6B8E23);
_colorKeywords.set("orange", 0xFFA500);
_colorKeywords.set("orangered", 0xFF4500);
_colorKeywords.set("orchid", 0xDA70D6);
_colorKeywords.set("palegoldenrod", 0xEEE8AA);
_colorKeywords.set("palegreen", 0x98FB98);
_colorKeywords.set("paleturquoise", 0xAFEEEE);
_colorKeywords.set("palevioletred", 0xDB7093);
_colorKeywords.set("papayawhip", 0xFFEFD5);
_colorKeywords.set("peachpuff", 0xFFDAB9);
_colorKeywords.set("peru", 0xCD853F);
_colorKeywords.set("pink", 0xFFC0CB);
_colorKeywords.set("plum", 0xDDA0DD);
_colorKeywords.set("powderblue", 0xB0E0E6);
_colorKeywords.set("purple", 0x800080);
_colorKeywords.set("rebeccapurple", 0x663399);
_colorKeywords.set("red", 0xFF0000);
_colorKeywords.set("rosybrown", 0xBC8F8F);
_colorKeywords.set("royalblue", 0x4169E1);
_colorKeywords.set("saddlebrown", 0x8B4513);
_colorKeywords.set("salmon", 0xFA8072);
_colorKeywords.set("sandybrown", 0xF4A460);
_colorKeywords.set("seagreen", 0x2E8B57);
_colorKeywords.set("seashell", 0xFFF5EE);
_colorKeywords.set("sienna", 0xA0522D);
_colorKeywords.set("silver", 0xC0C0C0);
_colorKeywords.set("skyblue", 0x87CEEB);
_colorKeywords.set("slateblue", 0x6A5ACD);
_colorKeywords.set("slategray", 0x708090);
_colorKeywords.set("slategrey", 0x708090);
_colorKeywords.set("snow", 0xFFFAFA);
_colorKeywords.set("springgreen", 0x00FF7F);
_colorKeywords.set("steelblue", 0x4682B4);
_colorKeywords.set("tan", 0xD2B48C);
_colorKeywords.set("teal", 0x008080);
_colorKeywords.set("thistle", 0xD8BFD8);
_colorKeywords.set("tomato", 0xFF6347);
_colorKeywords.set("turquoise", 0x40E0D0);
_colorKeywords.set("violet", 0xEE82EE);
_colorKeywords.set("wheat", 0xF5DEB3);
_colorKeywords.set("white", 0xFFFFFF);
_colorKeywords.set("whitesmoke", 0xF5F5F5);
_colorKeywords.set("yellow", 0xFFFF00);
_colorKeywords.set("yellowgreen", 0x9ACD32);

var _hslA:Dynamic = {h: 0, s: 0, l: 0};
var _hslB:Dynamic = {h: 0, s: 0, l: 0};

function hue2rgb(p:Float, q:Float, t:Float):Float {
	if (t < 0) t += 1;
	if (t > 1) t -= 1;
	if (t < 1 / 6) return p + (q - p) * 6 * t;
	if (t < 1 / 2) return q;
	if (t < 2 / 3) return p + (q - p) * 6 * (2 / 3 - t);
	return p;
}

var _color:Color = new Color();

class Color {
	public static var NAMES:Map<String, Int> = _colorKeywords;
}