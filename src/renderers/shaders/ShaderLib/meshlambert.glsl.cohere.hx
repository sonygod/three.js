package;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.display.Graphics;
import openfl.display.GraphicsShader;
import openfl.display.GraphicsFill;
import openfl.display.GraphicsPath;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

class Main extends Sprite {
    public function new() {
        super();

        var shader:Shader = new Shader(Assets.getText("vertexShader"), Assets.getText("fragmentShader"));

        var graphics:Graphics = new Graphics();
        graphics.beginShaderFill(new GraphicsShader(shader), new Matrix());
        graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
        graphics.endFill();

        addChild(graphics);
    }
}