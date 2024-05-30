import three.Color;
import three.LinearSRGBColorSpace;
import three.MathUtils;

class Lut {

	var isLut:Bool;
	var lut:Array<Color>;
	var map:Array<Array<Float>>;
	var n:Int;
	var minV:Float;
	var maxV:Float;

	public function new(colormap:String, count:Int = 32) {
		isLut = true;
		lut = [];
		map = [];
		n = 0;
		minV = 0;
		maxV = 1;
		setColorMap(colormap, count);
	}

	public function set(value:Lut):Lut {
		if (value.isLut) {
			copy(value);
		}
		return this;
	}

	public function setMin(min:Float):Lut {
		minV = min;
		return this;
	}

	public function setMax(max:Float):Lut {
		maxV = max;
		return this;
	}

	public function setColorMap(colormap:String, count:Int = 32):Lut {
		map = ColorMapKeywords[colormap] ?? ColorMapKeywords.rainbow;
		n = count;
		var step = 1.0 / n;
		var minColor = new Color();
		var maxColor = new Color();
		lut.length = 0;
		lut.push(new Color(map[0][1]));
		for (i in 1...count) {
			var alpha = i * step;
			for (j in 0...map.length - 1) {
				if (alpha > map[j][0] && alpha <= map[j + 1][0]) {
					var min = map[j][0];
					var max = map[j + 1][0];
					minColor.setHex(map[j][1], LinearSRGBColorSpace);
					maxColor.setHex(map[j + 1][1], LinearSRGBColorSpace);
					var color = new Color().lerpColors(minColor, maxColor, (alpha - min) / (max - min));
					lut.push(color);
				}
			}
		}
		lut.push(new Color(map[map.length - 1][1]));
		return this;
	}

	public function copy(lut:Lut):Lut {
		this.lut = lut.lut;
		this.map = lut.map;
		this.n = lut.n;
		this.minV = lut.minV;
		this.maxV = lut.maxV;
		return this;
	}

	public function getColor(alpha:Float):Color {
		alpha = MathUtils.clamp(alpha, minV, maxV);
		alpha = (alpha - minV) / (maxV - minV);
		var colorPosition = Math.round(alpha * n);
		return lut[colorPosition];
	}

	public function addColorMap(name:String, arrayOfColors:Array<Array<Float>>):Lut {
		ColorMapKeywords[name] = arrayOfColors;
		return this;
	}

	public function createCanvas():js.html.CanvasElement {
		var canvas = js.Browser.document.createElement('canvas');
		canvas.width = 1;
		canvas.height = n;
		updateCanvas(canvas);
		return canvas;
	}

	public function updateCanvas(canvas:js.html.CanvasElement):js.html.CanvasElement {
		var ctx = canvas.getContext('2d', { alpha: false });
		var imageData = ctx.getImageData(0, 0, 1, n);
		var data = imageData.data;
		var k = 0;
		var step = 1.0 / n;
		var minColor = new Color();
		var maxColor = new Color();
		var finalColor = new Color();
		for (i in 1...0) {
			for (j in map.length - 1...0) {
				if (i < map[j][0] && i >= map[j - 1][0]) {
					var min = map[j - 1][0];
					var max = map[j][0];
					minColor.setHex(map[j - 1][1], LinearSRGBColorSpace);
					maxColor.setHex(map[j][1], LinearSRGBColorSpace);
					finalColor.lerpColors(minColor, maxColor, (i - min) / (max - min));
					data[k * 4] = Math.round(finalColor.r * 255);
					data[k * 4 + 1] = Math.round(finalColor.g * 255);
					data[k * 4 + 2] = Math.round(finalColor.b * 255);
					data[k * 4 + 3] = 255;
					k += 1;
				}
			}
		}
		ctx.putImageData(imageData, 0, 0);
		return canvas;
	}
}

class ColorMapKeywords {
	public static var rainbow:Array<Array<Float>> = [[0.0, 0x0000FF], [0.2, 0x00FFFF], [0.5, 0x00FF00], [0.8, 0xFFFF00], [1.0, 0xFF0000]];
	public static var cooltowarm:Array<Array<Float>> = [[0.0, 0x3C4EC2], [0.2, 0x9BBCFF], [0.5, 0xDCDCDC], [0.8, 0xF6A385], [1.0, 0xB40426]];
	public static var blackbody:Array<Array<Float>> = [[0.0, 0x000000], [0.2, 0x780000], [0.5, 0xE63200], [0.8, 0xFFFF00], [1.0, 0xFFFFFF]];
	public static var grayscale:Array<Array<Float>> = [[0.0, 0x000000], [0.2, 0x404040], [0.5, 0x7F7F80], [0.8, 0xBFBFBF], [1.0, 0xFFFFFF]];
}