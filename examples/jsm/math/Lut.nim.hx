import three.math.Color;
import three.math.MathUtils;
import three.math.LinearSRGBColorSpace;

class Lut {

  public var isLut:Bool = true;
  public var lut:Array<Color>;
  public var map:Array<Dynamic>;
  public var n:Int;
  public var minV:Float;
  public var maxV:Float;

  public function new(colormap:String, count:Int = 32) {

    this.lut = [];
    this.map = [];
    this.n = 0;
    this.minV = 0;
    this.maxV = 1;

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

    this.map = ColorMapKeywords[colormap] || ColorMapKeywords.rainbow;
    this.n = count;

    var step:Float = 1.0 / this.n;
    var minColor:Color = new Color();
    var maxColor:Color = new Color();

    this.lut.length = 0;

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

  public function createCanvas():CanvasRenderingContext2D {

    var canvas:CanvasRenderingContext2D = js.Browser.document.createElement('canvas');
    canvas.width = 1;
    canvas.height = this.n;

    this.updateCanvas(canvas);

    return canvas;

  }

  public function updateCanvas(canvas:CanvasRenderingContext2D):CanvasRenderingContext2D {

    var ctx:CanvasRenderingContext2D = canvas.getContext('2d', { alpha: false });

    var imageData:ImageData = ctx.getImageData(0, 0, 1, this.n);

    var data:Uint8ClampedArray = imageData.data;

    var k:Int = 0;

    var step:Float = 1.0 / this.n;

    var minColor:Color = new Color();
    var maxColor:Color = new Color();
    var finalColor:Color = new Color();

    for (i in 1...0...step) {

      for (j in this.map.length - 1...0) {

        if (i < this.map[j][0] && i >= this.map[j - 1][0]) {

          var min:Float = this.map[j - 1][0];
          var max:Float = this.map[j][0];

          minColor.setHex(this.map[j - 1][1], LinearSRGBColorSpace);
          maxColor.setHex(this.map[j][1], LinearSRGBColorSpace);

          finalColor.lerpColors(minColor, maxColor, (i - min) / (max - min));

          data[k * 4] = Math.round(finalColor.r * 255);
          data[k * 4 + 1] = Math.round(finalColor.g * 255);
          data[k * 4 + 2] = Math.round(finalColor.b * 255);
          data[k * 4 + 3] = 255;

          k++;

        }

      }

    }

    ctx.putImageData(imageData, 0, 0);

    return canvas;

  }

}

class ColorMapKeywords {

  public static var rainbow:Array<Dynamic> = [[0.0, 0x0000FF], [0.2, 0x00FFFF], [0.5, 0x00FF00], [0.8, 0xFFFF00], [1.0, 0xFF0000]];
  public static var cooltowarm:Array<Dynamic> = [[0.0, 0x3C4EC2], [0.2, 0x9BBCFF], [0.5, 0xDCDCDC], [0.8, 0xF6A385], [1.0, 0xB40426]];
  public static var blackbody:Array<Dynamic> = [[0.0, 0x000000], [0.2, 0x780000], [0.5, 0xE63200], [0.8, 0xFFFF00], [1.0, 0xFFFFFF]];
  public static var grayscale:Array<Dynamic> = [[0.0, 0x000000], [0.2, 0x404040], [0.5, 0x7F7F80], [0.8, 0xBFBFBF], [1.0, 0xFFFFFF]];

}