package three.js.editor.js;

import js.html.Document;
import js.html.Event;
import js.html.PointerEvent;
import js.html.DivElement;
import js.Browser;

class Resizer {
    private var editor:Dynamic;
    private var signals:Dynamic;
    private var dom:DivElement;

    public function new(editor:Dynamic) {
        this.editor = editor;
        this.signals = editor.signals;

        this.dom = Browser.document.createElement("div");
        this.dom.id = "resizer";

        this.dom.addEventListener("pointerdown", onPointerDown);
    }

    private function onPointerDown(event:PointerEvent) {
        if (!event.isPrimary) return;

        Browser.document.addEventListener("pointermove", onPointerMove);
        Browser.document.addEventListener("pointerup", onPointerUp);
    }

    private function onPointerUp(event:PointerEvent) {
        if (!event.isPrimary) return;

        Browser.document.removeEventListener("pointermove", onPointerMove);
        Browser.document.removeEventListener("pointerup", onPointerUp);
    }

    private function onPointerMove(event:PointerEvent) {
        if (!event.isPrimary) return;

        var offsetWidth:Int = Browser.document.body.offsetWidth;
        var clientX:Int = event.clientX;

        var cX:Int = if (clientX < 0) 0 else if (clientX > offsetWidth) offsetWidth else clientX;

        var x:Int = Math.max(335, offsetWidth - cX); // .TabbedPanel min-width: 335px

        this.dom.style.right = x + 'px';

        Browser.document.getElementById("sidebar").style.width = x + 'px';
        Browser.document.getElementById("player").style.right = x + 'px';
        Browser.document.getElementById("script").style.right = x + 'px';
        Browser.document.getElementById("viewport").style.right = x + 'px';

        this.signals.windowResize.dispatch();
    }
}