package;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.DisplayObjectContainer;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.display.Tilesheet;
import openfl.display.Graphics;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.Lib;
import openfl.utils.Assets;

class Main extends Sprite {
	public function new() {
		super();
		Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		Lib.current.stage.addEventListener(Event.RESIZE, onResize);
		Lib.current.stage.scaleMode = "noScale";
		Lib.current.stage.align = "top";

		var ts:Tilesheet = new Tilesheet(Assets.getBitmapData("tilesheet.png"), 16, 16, 0, 0, true);
		var ts2:Tilesheet = new Tilesheet(Assets.getBitmapData("tilesheet2.png"), 16, 16, 0, 0, true);

		var bmd:BitmapData = new BitmapData(16, 16, false, 0xFFFFFFFF);
		bmd.fillRect(bmd.rect, 0xFF0000FF);

		var ts3:Tilesheet = new Tilesheet(bmd, 16, 16, 0, 0, true);

		var shader:Shader = new Shader(Assets.getText("matcap-vertex"), Assets.getText("matcap-fragment"));

		var graphics:Graphics = new Graphics();
		graphics.beginFill(0xFF0000);
		graphics.drawRect(0, 0, 100, 100);
		graphics.endFill();

		var sprite:Sprite = new Sprite();
		sprite.graphics.copyFrom(graphics);
		sprite.x = 100;
		sprite.y = 100;
		sprite.shader = shader;
		addChild(sprite);

		var sprite2:Sprite = new Sprite();
		sprite2.graphics.beginBitmapFill(Assets.getBitmapData("tilesheet.png"), null, true);
		sprite2.graphics.drawRect(0, 0, 100, 100);
		sprite2.graphics.endFill();
		sprite2.x = 200;
		sprite2.y = 100;
		sprite2.shader = shader;
		addChild(sprite2);

		var sprite3:Sprite = new Sprite();
		sprite3.graphics.beginTilesheetFill(ts, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], null, true);
		sprite3.graphics.drawRect(0, 0, 100, 100);
		sprite3.graphics.endFill();
		sprite3.x = 300;
		sprite3.y = 100;
		sprite3.shader = shader;
		addChild(sprite3);

		var sprite4:Sprite = new Sprite();
		sprite4.graphics.beginTilesheetFill(ts2, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], null, true);
		sprite4.graphics.drawRect(0, 0, 100, 100);
		sprite4.graphicsMultiplier = 2;
		sprite4.graphics.endFill();
		sprite4.x = 400;
		sprite4.y = 100;
		sprite4.shader = shader;
		addChild(sprite4);

		var sprite5:Sprite = new Sprite();
		sprite5.graphics.beginTilesheetFill(ts3, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], null, true);
		sprite5.graphics.drawRect(0, 0, 100, 100);
		sprite5.graphics.endFill();
		sprite5.x = 500;
		sprite5.y = 100;
		sprite5.shader = shader;
		addChild(sprite5);
	}

	function onEnterFrame(e:Event):Void {
		var sprite:Sprite = getChildAt(0) as Sprite;
		var sprite2:Sprite = getChildAt(1) as Sprite;
		var sprite3:Sprite = getChildAt(2) as Sprite;
		var sprite4:Sprite = getChildAt(3) as Sprite;
		var sprite5:Sprite = getChildAt(4) as Sprite;

		sprite.rotation += 1;
		sprite2.rotation += 1;
		sprite3.rotation += 1;
		sprite4.rotation += 1;
		sprite5.rotation += 1;
	}

	function onResize(e:Event):Void {
		var bounds:openfl.geom.Rectangle = Lib.current.stage.stage3Ds[0].viewPort;
		var width:Int = bounds.width;
		var height:Int = bounds.height;
		var ratio:Float = width / height;
		var scaleX:Float = width / 640;
		var scaleY:Float = height / 480;
		var scale:Float = Math.max(scaleX, scaleY);
		var x:Float = (width - 640 * scale) / 2;
		var y:Float = (height - 480 * scale) / 2;
		scaleMode = "noScale";
		align = "top";
		scaleX = scale;
		scaleY = scale;
		x = 0;
		y = 0;
	}
}