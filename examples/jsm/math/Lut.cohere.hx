import js.Browser.window;

class Lut {
    public var isLut:Bool = true;
    public var lut:Array<Int>;
    public var map:Array<Float>;
    public var n:Int;
    public var minV:Float;
    public var maxV:Float;
    public var ColorMapKeywords:Array<Float>;

    public function new(colormap:Array<Float>, count:Int = 32) {
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

    public function setColorMap(colormap:Array<Float>, count:Int = 32) {
        map = ColorMapKeywords[colormap] ?? ColorMapKeywords.get("rainbow");
        n = count;
        var step = 1.0 / n;
        var minColor = new js.html.CanvasGradientColor();
        var maxColor = new js.html.CanvasGradientColor();
        lut.length = 0;
        lut.push(new js.html.CanvasGradientColor(map[0][1]));
        for (i in 1...count) {
            var alpha = i * step;
            var j = 0;
            while (j < map.length - 1) {
                if (alpha > map[j][0] && alpha <= map[j + 1][0]) {
                    var min = map[j][0];
                    var max = map[j + 1][0];
                    minColor.setHex(map[j][1], LinearSRGBColorSpace);
                    maxColor.setHex(map[j + 1][1], LinearSRGBColorSpace);
                    var color = new js.html.CanvasGradientColor();
                    color.lerpColors(minColor, maxColor, (alpha - min) / (max - min));
                    lut.push(color);
                    break;
                }
                j++;
            }
        }
        lut.push(new js.html.CanvasGradientColor(map[map.length - 1][1]));
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

    public function getColor(alpha:Float):js.html.CanvasGradientColor {
        alpha = Math.clamp(alpha, minV, maxV);
        alpha = (alpha - minV) / (maxV - minV);
        var colorPosition = cast Int (Math.round(alpha * n));
        return lut[colorPosition];
    }

    public function addColorMap(name:String, arrayOfColors:Array<Float>):Lut {
        ColorMapKeywords.set(name, arrayOfColors);
        return this;
    }

    public function createCanvas():js.html.HTMLCanvasElement {
        var canvas = window.document.createElement("canvas");
        canvas.width = 1;
        canvas.height = n;
        updateCanvas(canvas);
        return canvas;
    }

    public function updateCanvas(canvas:js.html.HTMLCanvasElement):js.html.HTMLCanvasElement {
        var ctx = canvas.getContext2d({ alpha: false });
        var imageData = ctx.getImageData(0, 0, 1, n);
        var data = imageData.data;
        var k = 0;
        var step = 1.0 / n;
        var minColor = new js.html.CanvasGradientColor();
        var maxColor = new js.html.CanvasGradientColor();
        var finalColor = new js.html.CanvasGradientColor();
        for (i in 1...0) {
            var j = map.length - 1;
            while (j >= 0) {
                if (i < map[j][0] && i >= map[j - 1][0]) {
                    var min = map[j - 1][0];
                    var max = map[j][0];
                    minColor.setHex(map[j - 1][1], LinearSRGBColorSpace);
                    maxColor.setHex(map[j][1], LinearSRGBColorSpace);
                    finalColor.lerpColors(minColor, maxColor, (i - min) / (max - min));
                    data[k * 4] = finalColor.r.toInt();
                    data[k * 4 + 1] = finalColor.g.toInt();
                    data[k * 4 + 2] = finalColor.b.toInt();
                    data[k * 4 + 3] = 255;
                    k++;
                    break;
                }
                j--;
            }
        }
        ctx.putImageData(imageData, 0, 0);
        return canvas;
    }
}

var ColorMapKeywords = ["rainbow", [0.0, 0x0000FF], [0.2, 0x00FFFF], [0.5, 0x00FF00], [0.8, 0xFFFF00], [1.0, 0xFF0000]];