import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.events.KeyboardEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class Main extends Sprite {
    public function new() {
        super();
        if (stage == null) {
            stage = Stage.createElement(null);
        }

        stage.align = StageAlign.TOP_LEFT;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
        stage.frameRate = 60;
        addChild(stage);

        var shape:DisplayObject = createShape();
        stage.addChild(shape);

        var isDown:Bool = false;
        stage.addEventListener(MouseEvent.MOUSE_DOWN, (e:MouseEvent) -> {
            isDown = true;
        });

        stage.addEventListener(MouseEvent.MOUSE_UP, (e:MouseEvent) -> {
            isDown = false;
        });

        stage.addEventListener(MouseEvent.MOUSE_MOVE, (e:MouseEvent) -> {
            if (isDown) {
                shape.x += e.localX - shape.mouseX;
                shape.y += e.localY - shape.mouseY;
                shape.mouseX = e.localX;
                shape.mouseY = e.localY;
            }
        });
    }

    function createShape():Shape {
        var shape:Shape = Shape.createCircle(100, 0x000000, 1);
        shape.mouseX = 0;
        shape.mouseY = 0;
        return shape;
    }

    function enterFrameHandler(e:Event) {
        var shape:DisplayObject = cast stage.getChildAt(0);
        shape.x += 2;
        if (shape.x > stage.stageWidth) {
            shape.x = 0;
        }
    }

    static function main() {
        var app:Main = new Main();
    }
}

class Shape extends DisplayObject {
    public var mouseX:Float;
    public var mouseY:Float;

    public function new() {
        super();
    }
}

class Shape extends DisplayObject {
    public var mouseX:Float;
    public var mouseY:Float;

    public function new() {
        super();
    }
}

class Shape {
    public static inline function createCircle(radius:Float, color:Int, lineWidth:Float = 0):Shape {
        var shape:Shape = Shape.create(color, lineWidth);
        var g:Graphics = shape.graphics;
        g.beginFill(color);
        g.drawCircle(0, 0, radius);
        g.endFill();
        return shape;
    }
}

class Shape extends DisplayObject {
    public var graphics:Graphics;

    override public function set_x(value:Float):Float {
        return super.set_x(value);
    }

    override public function set_y(value:Float):Float {
        return super.set_y(value);
    }

    public function new() {
        super();
        graphics = Graphics.create(this);
    }
}