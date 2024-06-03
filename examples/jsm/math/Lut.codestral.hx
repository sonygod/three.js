import three.Color;
import three.LinearSRGBColorSpace;
import three.MathUtils;

class Lut {
    public var isLut:Bool = true;
    public var lut:Array<Color> = [];
    public var map:Array<Dynamic> = [];
    public var n:Int = 0;
    public var minV:Float = 0.0;
    public var maxV:Float = 1.0;

    public function new(colormap:String, count:Int = 32) {
        this.setColorMap(colormap, count);
    }

    public function set(value:Lut):Lut {
        if (value.isLut == true) {
            this.copy(value);
        }
        return this;
    }

    public function setMin(min:Float):Lut {
        this.minV = min;
        return this;
    }

    public function setMax(max:Float):Lut {
        this.maxV = max;
        return this;
    }

    public function setColorMap(colormap:String, count:Int = 32):Lut {
        this.map = Std.mapLookup(ColorMapKeywords, colormap, ColorMapKeywords.get("rainbow"));
        this.n = count;

        var step:Float = 1.0 / this.n;
        var minColor:Color = new Color();
        var maxColor:Color = new Color();

        this.lut = [];

        this.lut.push(new Color(this.map[0][1]));

        for (var i:Int = 1; i < count; i++) {
            var alpha:Float = i * step;

            for (var j:Int = 0; j < this.map.length - 1; j++) {
                if (alpha > this.map[j][0] && alpha <= this.map[j + 1][0]) {
                    var min:Float = this.map[j][0];
                    var max:Float = this.map[j + 1][0];

                    minColor.setHex(this.map[j][1], LinearSRGBColorSpace);
                    maxColor.setHex(this.map[j + 1][1], LinearSRGBColorSpace);

                    var color:Color = new Color().lerpColors(minColor, maxColor, (alpha - min) / (max - min));

                    this.lut.push(color);
                }
            }
        }

        this.lut.push(new Color(this.map[this.map.length - 1][1]));

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
        alpha = MathUtils.clamp(alpha, this.minV, this.maxV);
        alpha = (alpha - this.minV) / (this.maxV - this.minV);

        var colorPosition:Int = Math.round(alpha * this.n);

        return this.lut[colorPosition];
    }

    public function addColorMap(name:String, arrayOfColors:Array<Dynamic>):Lut {
        ColorMapKeywords[name] = arrayOfColors;

        return this;
    }
}

var ColorMapKeywords:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
ColorMapKeywords.set("rainbow", [[0.0, 0x0000FF], [0.2, 0x00FFFF], [0.5, 0x00FF00], [0.8, 0xFFFF00], [1.0, 0xFF0000]]);
ColorMapKeywords.set("cooltowarm", [[0.0, 0x3C4EC2], [0.2, 0x9BBCFF], [0.5, 0xDCDCDC], [0.8, 0xF6A385], [1.0, 0xB40426]]);
ColorMapKeywords.set("blackbody", [[0.0, 0x000000], [0.2, 0x780000], [0.5, 0xE63200], [0.8, 0xFFFF00], [1.0, 0xFFFFFF]]);
ColorMapKeywords.set("grayscale", [[0.0, 0x000000], [0.2, 0x404040], [0.5, 0x7F7F80], [0.8, 0xBFBFBF], [1.0, 0xFFFFFF]]);