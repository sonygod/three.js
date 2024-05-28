import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.filters.BitmapFilter;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class Main extends Sprite {
    public function new() {
        super();

        var bitmap:Bitmap = new Bitmap(new BitmapData(100, 100, false, 0x00000000));
        bitmap.filters = [new GlowFilter(0xFF0000, 0.5, 1, 1, 2, 2)];
        addChild(bitmap);
    }
}

class GlowFilter extends BitmapFilter {
    public var color:Int;
    public var alpha:Float;
    public var blurX:Float;
    public var blurY:Float;
    public var strength:Float;
    public var quality:Int;
    public var inner:Bool;
    public var knockout:Bool;

    public function new(color:Int, alpha:Float, blurX:Float, blurY:Float, strength:Float, quality:Int, inner:Bool = false, knockout:Bool = false) {
        super();
        this.color = color;
        this.alpha = alpha;
        this.blurX = blurX;
        blurY = blurY;
        strength = strength;
        this.quality = quality;
        this.inner = inner;
        this.knockout = knockout;
    }

    override public function applyFilter(filterRect:Rectangle, inputBitmapData:BitmapData, outputBitmapData:BitmapData) {
        var tempData:BitmapData = new BitmapData(inputBitmapData.width, inputBitmapData.height, true, 0xFFFFFFFF);
        tempData.draw(inputBitmapData);
        tempData.applyFilter(new BlurFilter(blurX, blurY, quality), filterRect, tempData, Point.zero());

        if (inner) {
            tempData.copyChannel(inputBitmapData, tempData, tempData.rect, new Point(0, 0), tempData.rect, BitmapDataChannel.RED);
            tempData.copyChannel(inputBitmapData, tempData, tempData.rect, new Point(0, 0), tempData.rect, BitmapDataChannel.GREEN);
            tempData.copyChannel(inputBitmapData, tempData, tempData.rect, new Point(0, 0), tempData.rect, BitmapDataChannel.BLUE);
        }

        if (knockout) {
            outputBitmapData.copyPixels(inputBitmapData, filterRect, new Point(0, 0));
        }

        var color:Int = (color >> 16) & 0xFF;
        var r:Float = (color / 255) * alpha;
        var g:Float = ((color >> 8) & 0xFF) / 255;
        var b:Float = (color & 0xFF) / 255;
        outputBitmapData.copyChannel(tempData, outputBitmapData, filterRect, new Point(0, 0), filterRect, BitmapDataChannel.ALPHA);
        outputBitmapData.fillRect(filterRect, ((r * strength) + g) * 255);
    }
}

class BlurFilter extends BitmapFilter {
    public var blurX:Float;
    public var blurY:Float;
    public var quality:Int;

    public function new(blurX:Float, blurY:Float, quality:Int) {
        super();
        this.blurX = blurX;
        this.blurY = blurY;
        this.quality = quality;
    }

    override public function applyFilter(filterRect:Rectangle, inputBitmapData:BitmapData, outputBitmapData:BitmapData) {
        var amount:Float = 1 / (quality + 1);
        var offset:Float = amount / 2;
        var weights:Array<Float> = [];
        var i:Int;

        for (i = 0; i <= quality; i++) {
            weights.push(Math.exp(-(i * i) / (2 * amount * amount)));
        }

        var tempData:BitmapData = new BitmapData(inputBitmapData.width, inputBitmapData.height, true, 0xFFFFFFFF);
        tempData.draw(inputBitmapData);

        var direction:Int;

        for (direction = 0; direction < 2; direction++) {
            var weightIndex:Int = 0;
            var weightTotal:Float = 0;
            var xMult:Int = (if (direction == 0) 1 else 0);
            var yMult:Int = (if (direction == 0) 0 else 1);

            for (i = -quality; i <= quality; i++) {
                weightTotal += weights[weightIndex];
                weightIndex++;
            }

            var previousLine:BitmapData = new BitmapData(inputBitmapData.width, 1, true, 0xFFFFFFFF);
            var previousLineData:ByteArray = previousLine.getPixels(new Rectangle(0, 0, inputBitmapData.width, 1));

            for (var y:Int = 0; y < inputBitmapData.height; y++) {
                var currentLineData:ByteArray = tempData.getPixels(new Rectangle(0, y * xMult, inputBitmapData.width, 1));
                var currentPixel:Int;
                var previousPixel:Int;
                var weightedPixel:Int;
                var weightedTotal:Float;
                var weightedR:Float;
                var weightedG:Float;
                var weightedB:Float;
                var weightedA:Float;
                var x:Int;

                for (x = 0; x < inputBitmapData.width; x++) {
                    currentPixel = currentLineData.readInt32();
                    weightedTotal = 0;
                    weightedR = 0;
                    weightedG = 0;
                    weightedB = 0;
                    weightedA = 0;

                    for (i = -quality; i <= quality; i++) {
                        previousPixel = previousLineData.readInt32();
                        weightedPixel = previousPixel;
                        weightedTotal += weights[weightIndex];
                        weightIndex++;

                        weightedR += ((weightedPixel >> 16) & 0xFF) * weights[weightIndex];
                        weightedG += ((weightedPixel >> 8) & 0xFF) * weights[weightIndex];
                        weightedB += (weightedPixel & 0xFF) * weights[weightIndex];
                        weightedA += ((weightedPixel >> 24) & 0xFF) * weights[weightIndex];
                    }

                    outputBitmapData.setPixel32(x, y * yMult, ((currentPixel & 0xFF000000) >> 24) << 24 |
                                                        ((((weightedR / weightedTotal) * 255) << 16) & 0xFF0000) |
                                                        ((((weightedG / weightedTotal) * 255) << 8) & 0xFF00) |
                                                         ((weightedB / weightedTotal) * 255));
                    previousLineData.position = i * 4;
                    previousLineData.writeInt32(currentPixel);
                }
            }

            tempData.draw(outputBitmapData);
        }
    }
}