import three.Color;
import three.LinearSRGBColorSpace;
import three.MathUtils;

class Lut {
  public var isLut:Bool = true;

  public var lut:Array<Color> = [];
  public var map:Array<Array<Float>> = [];
  public var n:Int = 0;
  public var minV:Float = 0;
  public var maxV:Float = 1;

  public function new(colormap:String, count:Int = 32) {
    this.setColorMap(colormap, count);
  }

  public function set(value:Lut):Lut {
    if (value.isLut) {
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
    this.map = ColorMapKeywords.get(colormap) != null ? ColorMapKeywords.get(colormap) : ColorMapKeywords.get("rainbow");
    this.n = count;

    var step:Float = 1.0 / this.n;
    var minColor:Color = new Color();
    var maxColor:Color = new Color();

    this.lut = [];

    // sample at 0
    this.lut.push(new Color(this.map[0][1]));

    // sample at 1/n, ..., (n-1)/n
    for (i in 1...count) {
      var alpha:Float = i * step;

      for (j in 0...this.map.length - 1) {
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

    // sample at 1
    this.lut.push(new Color(this.map[this.map.length - 1][1]));

    return this;
  }

  public function copy(lut:Lut):Lut {
    this.lut = lut.lut.copy();
    this.map = lut.map.copy();
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

  public function addColorMap(name:String, arrayOfColors:Array<Array<Float>>):Lut {
    ColorMapKeywords.set(name, arrayOfColors);
    return this;
  }

  // The following methods are not directly translated due to the lack of DOM manipulation in Haxe.
  // You'll need to implement them using your chosen Haxe UI library or by using a different approach.
  // public function createCanvas():HtmlElement {
  //   // ...
  // }

  // public function updateCanvas(canvas:HtmlElement):HtmlElement {
  //   // ...
  // }
}

private var ColorMapKeywords:Map<String, Array<Array<Float>>> = new Map<String, Array<Array<Float>>>([
  ("rainbow", [[0.0, 0x0000FF], [0.2, 0x00FFFF], [0.5, 0x00FF00], [0.8, 0xFFFF00], [1.0, 0xFF0000]]),
  ("cooltowarm", [[0.0, 0x3C4EC2], [0.2, 0x9BBCFF], [0.5, 0xDCDCDC], [0.8, 0xF6A385], [1.0, 0xB40426]]),
  ("blackbody", [[0.0, 0x000000], [0.2, 0x780000], [0.5, 0xE63200], [0.8, 0xFFFF00], [1.0, 0xFFFFFF]]),
  ("grayscale", [[0.0, 0x000000], [0.2, 0x404040], [0.5, 0x7F7F80], [0.8, 0xBFBFBF], [1.0, 0xFFFFFF]])
]);

class LutHaxe {
  public static function main() {
    // ... Use the Lut class and its methods here ...
  }
}