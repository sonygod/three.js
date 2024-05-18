package three.js.examples.jsm.interactive;

import js.html.DivElement;
import js.html.Document;
import js.html.Event;
import js.html.PointerEvent;
import three.Vector2;

class SelectionHelper {

    private var element:DivElement;
    private var renderer:Dynamic;
    private var startPoint:Vector2;
    private var pointTopLeft:Vector2;
    private var pointBottomRight:Vector2;

    private var isDown:Bool;
    private var enabled:Bool;

    public function new(renderer:Dynamic, cssClassName:String) {
        element = Document.getElementById("root").createElement("div");
        element.classList.add(cssClassName);
        element.style.pointerEvents = 'none';

        this.renderer = renderer;

        startPoint = new Vector2();
        pointTopLeft = new Vector2();
        pointBottomRight = new Vector2();

        isDown = false;
        enabled = true;

        onPointerDown = function(event:PointerEvent) {
            if (!enabled) return;
            isDown = true;
            onSelectStart(event);
        }

        onPointerMove = function(event:PointerEvent) {
            if (!enabled) return;
            if (isDown) {
                onSelectMove(event);
            }
        }

        onPointerUp = function(event:PointerEvent) {
            if (!enabled) return;
            isDown = false;
            onSelectOver();
        }

        renderer.domElement.addEventListener('pointerdown', onPointerDown);
        renderer.domElement.addEventListener('pointermove', onPointerMove);
        renderer.domElement.addEventListener('pointerup', onPointerUp);
    }

    public function dispose() {
        renderer.domElement.removeEventListener('pointerdown', onPointerDown);
        renderer.domElement.removeEventListener('pointermove', onPointerMove);
        renderer.domElement.removeEventListener('pointerup', onPointerUp);
    }

    private function onSelectStart(event:PointerEvent) {
        element.style.display = 'none';

        renderer.domElement.parentElement.appendChild(element);

        element.style.left = event.clientX + 'px';
        element.style.top = event.clientY + 'px';
        element.style.width = '0px';
        element.style.height = '0px';

        startPoint.x = event.clientX;
        startPoint.y = event.clientY;
    }

    private function onSelectMove(event:PointerEvent) {
        element.style.display = 'block';

        pointBottomRight.x = Math.max(startPoint.x, event.clientX);
        pointBottomRight.y = Math.max(startPoint.y, event.clientY);
        pointTopLeft.x = Math.min(startPoint.x, event.clientX);
        pointTopLeft.y = Math.min(startPoint.y, event.clientY);

        element.style.left = pointTopLeft.x + 'px';
        element.style.top = pointTopLeft.y + 'px';
        element.style.width = (pointBottomRight.x - pointTopLeft.x) + 'px';
        element.style.height = (pointBottomRight.y - pointTopLeft.y) + 'px';
    }

    private function onSelectOver() {
        element.parentElement.removeChild(element);
    }
}