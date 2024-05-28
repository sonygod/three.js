import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.EventDispatcher;

class Main extends Sprite {
    public function new() {
        super();

        var stage: Stage = Stage.createNativeStage(null, null, null);
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);

        var sprite: Sprite = new Sprite();
        sprite.graphics.beginFill(0xFFFFFF);
        sprite.graphics.drawRect(0, 0, 100, 100);
        sprite.graphics.endFill();
        sprite.x = 100;
        sprite.y = 100;

        addChild(sprite);
    }

    private function enterFrameHandler(e: Event): Void {
        trace("Enter frame");
    }
}

var main: Main = new Main();