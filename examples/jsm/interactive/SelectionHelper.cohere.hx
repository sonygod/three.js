import js.html.Document;
import js.html.HTMLElement;
import js.html.PointerEvent;

class SelectionHelper {
    var element:HTMLElement;
    var renderer:js.html.CanvasRenderingContext2D;
    var startPoint:Vector2;
    var pointTopLeft:Vector2;
    var pointBottomRight:Vector2;
    var isDown:Bool;
    var enabled:Bool;
    var onPointerDown:PointerEvent->Void;
    var onPointerMove:PointerEvent->Void;
    var onPointerUp:Void->Void;

    public function new(renderer:js.html.CanvasRenderingContext2D, cssClassName:String) {
        element = Document.createElement("div");
        element.classList.add(cssClassName);
        element.style.pointerEvents = "none";

        this.renderer = renderer;

        startPoint = Vector2.create();
        pointTopLeft = Vector2.create();
        pointBottomRight = Vector2.create();

        isDown = false;
        enabled = true;

        onPointerDown = function(event:PointerEvent) {
            if (!enabled) return;
            isDown = true;
            onSelectStart(event);
        };

        onPointerMove = function(event:PointerEvent) {
            if (!enabled) return;
            if (isDown) {
                onSelectMove(event);
            }
        };

        onPointerUp = function() {
            if (!enabled) return;
            isDown = false;
            onSelectOver();
        };

        renderer.domElement.addEventListener("pointerdown", onPointerDown);
        renderer.domElement.addEventListener("pointermove", onPointerMove);
        renderer.domElement.addEventListener("pointerup", onPointerUp);
    }

    public function dispose() {
        renderer.domElement.removeEventListener("pointerdown", onPointerDown);
        renderer.domElement.removeEventListener("pointermove", onPointerMove);
        renderer.domElement.removeEventListener("pointerup", onPointerUp);
    }

    function onSelectStart(event:PointerEvent) {
        element.style.display = "none";
        renderer.domElement.parentElement?.appendChild(element);
        element.style.left = event.clientX + "px";
        element.style.top = event.clientY + "px";
        element.style.width = "0px";
        element.style.height = "0px";
        startPoint.set(event.clientX, event.clientY);
    }

    function onSelectMove(event:PointerEvent) {
        element.style.display = "block";
        pointBottomRight.set(Math.max(startPoint.x, event.clientX), Math.max(startPoint.y, event.clientY));
        pointTopLeft.set(Math.min(startPoint.x, event.clientX), Math.min(startPoint.y, event.clientY));
        element.style.left = pointTopLeft.x + "px";
        element.style.top = pointTopLeft.y + "px";
        element.style.width = (pointBottomRight.x - pointTopLeft.x) + "px";
        element.style.height = (pointBottomRight.y - pointTopLeft.y) + "px";
    }

    function onSelectOver() {
        element.parentElement?.removeChild(element);
    }
}

class Vector2 {
    public var x:Float;
    public var y:Float;

    public function new(x:Float = 0.0, y:Float = 0.0) {
        this.x = x;
        this.y = y;
    }

    public static function create():Vector2 {
        return Vector2.create(0.0, 0.0);
    }

    public static function create(x:Float, y:Float):Vector2 {
        return Vector2(x, y);
    }

    public function set(x:Float, y:Float):Void {
        this.x = x;
        this.y = y;
    }
}