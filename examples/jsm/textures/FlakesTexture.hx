package three.js.examples.jm.textures;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.geom.Matrix;
import openfl.Lib;

class FlakesTexture {

    public function new(width:Int = 512, height:Int = 512) {
        var bitmapData:BitmapData = new BitmapData(width, height, true, 0x00000000);

        for (i in 0...4000) {
            var x:Float = Math.random() * width;
            var y:Float = Math.random() * height;
            var r:Float = Math.random() * 3 + 3;

            var nx:Float = Math.random() * 2 - 1;
            var ny:Float = Math.random() * 2 - 1;
            var nz:Float = 1.5;

            var l:Float = Math.sqrt(nx * nx + ny * ny + nz * nz);

            nx /= l;
            ny /= l;
            nz /= l;

            var fillColor:Int = 0xFF << 24 | ((nx * 127 + 127) << 16) | ((ny * 127 + 127) << 8) | nz * 255;
            var graphics:Graphics = new Graphics(bitmapData);
            graphics.beginFill(fillColor);
            graphics.drawCircle(x, y, r);
            graphics.endFill();
        }

        var bitmap:Bitmap = new Bitmap(bitmapData);
        return bitmap;
    }
}