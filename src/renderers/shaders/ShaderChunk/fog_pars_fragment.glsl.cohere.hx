import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.EventDispatcher;

class MyClass {
    public static function main() {
        var stage = Stage.getInstance();
        stage.frameRate = 60;
        stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
        var sprite = new Sprite();
        sprite.graphics.beginFill(0xFFFFFF);
        sprite.graphics.drawRect(0, 0, 100, 100);
        sprite.graphics.endFill();
        stage.addChild(sprite);
        var fogColor:Float = fogColor;
        var vFogDepth:Float = vFogDepth;
        var fogDensity:Float = fogDensity;
        var fogNear:Float = fogNear;
        var fogFar:Float = fogFar;
        var useFog:Bool = useFog;
        var fogExp2:Bool = fogExp2;
        stage.update();
    }

    static function enterFrameHandler(e:Event) {
        // Code for enter frame event
    }
}