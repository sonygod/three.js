package three.js.editor.js;

import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.PointerEvent;
import js.html.Window;

import UIElement from './libs/UIElement';

class Resizer {
    private var editor:Editor;
    private var signals:Signals;
    private var dom:Element;

    public function new(editor:Editor) {
        signals = editor.signals;
        dom = js.Browser.document.createElement('div');
        dom.id = 'resizer';
        dom.addEventListener('pointerdown', onPointerDown);
    }

    private function onPointerDown(event:PointerEvent) {
        if (!event.isPrimary) return;
        js.Browser.document.addEventListener('pointermove', onPointerMove);
        js.Browser.document.addEventListener('pointerup', onPointerUp);
    }

    private function onPointerUp(event:PointerEvent) {
        if (!event.isPrimary) return;
        js.Browser.document.removeEventListener('pointermove', onPointerMove);
        js.Browser.document.removeEventListener('pointerup', onPointerUp);
    }

    private function onPointerMove(event:PointerEvent) {
        if (!event.isPrimary) return;
        var offsetWidth:Int = js.Browser.document.body.offsetWidth;
        var clientX:Int = event.clientX;
        var cX:Int = clientX < 0 ? 0 : clientX > offsetWidth ? offsetWidth : clientX;
        var x:Int = Math.max(335, offsetWidth - cX);
        dom.style.right = x + 'px';
        js.Browser.document.getElementById('sidebar').style.width = x + 'px';
        js.Browser.document.getElementById('player').style.right = x + 'px';
        js.Browser.document.getElementById('script').style.right = x + 'px';
        js.Browser.document.getElementById('viewport').style.right = x + 'px';
        signals.windowResize.dispatch();
    }

    public function getUIElement():UIElement {
        return new UIElement(dom);
    }
}

// Export the Resizer class
extern class Resizer {
    public function new(editor:Editor);
    public function getUIElement():UIElement;
}