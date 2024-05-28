import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;

class Main extends Sprite {

	public function new() {
		super();

		var sprite = new Sprite();
		sprite.graphics.beginFill(0xFF0000);
		sprite.graphics.drawRect(0, 0, 100, 100);
		sprite.graphics.endFill();

		var blurFilter = new BlurFilter();
		blurFilter.blurX = 4;
		blurFilter.blurY = 4;

		sprite.filters = [blurFilter];

		addChild(sprite);
	}

}

var stage = new Stage(550, 400, 0xFFFFFF, Main);
stage.frameRate = 60;
stage.addEventListener(Event.ENTER_FRAME, stage_enterFrameHandler);
stage.show();

function stage_enterFrameHandler(e:Event):Void {
	stage.setResolution(stage.stageWidth, stage.stageHeight);
}