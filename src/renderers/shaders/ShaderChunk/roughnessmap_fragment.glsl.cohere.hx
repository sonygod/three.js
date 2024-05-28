import openfl.display.DisplayObject;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.events.MouseEvent;
import openfl.utils.Assets;
import openfl.Lib;

class Main extends Sprite {

	public function new() {
		super();
		Assets.loadBitmapData("image", "path/to/your/image.png");
		Assets.onComplete(loadHandler);
	}

	public function loadHandler():Void {
		var bitmap:Bitmap = new Bitmap(Assets.getBitmapData("image"));
		addChild(bitmap);
	}
}

Lib.current.addChild(new Main());