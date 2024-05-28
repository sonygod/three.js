import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;

class Main extends Sprite {
    public function new() {
        super();

        stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
    }

    private function enterFrameHandler(e:Event):Void {
        trace("Enter frame");
    }
}

var stage = Stage.initElement(null);
stage.scaleMode = StageScaleMode.NO_SCALE;
stage.align = StageAlign.TOP_LEFT;
stage.frameRate = 60;
stage.addChild(Main());