import js.Browser.document;
import js.html.Element;
import js.html.Event;
import js.html.EventTarget;
import js.html.InputEvent;
import js.html.PointerEvent;
import ui.UIElement;

class Resizer {
    private var editor: Editor; // this is a placeholder for the editor class, you should import the actual class here
    private var dom: Element;
    private var signals: SignalManager; // this is a placeholder for the SignalManager class, you should import the actual class here

    public function new(editor: Editor) {
        this.editor = editor;
        this.signals = editor.signals;

        this.dom = document.createElement('div');
        this.dom.id = 'resizer';

        this.dom.addEventListener('pointerdown', onPointerDown);
    }

    private function onPointerDown(event: Event): Void {
        var pointerEvent = js.html.PointerEvent(event);
        if (pointerEvent.isPrimary === false) return;

        dom.ownerDocument.addEventListener('pointermove', onPointerMove);
        dom.ownerDocument.addEventListener('pointerup', onPointerUp);
    }

    private function onPointerUp(event: Event): Void {
        var pointerEvent = js.html.PointerEvent(event);
        if (pointerEvent.isPrimary === false) return;

        dom.ownerDocument.removeEventListener('pointermove', onPointerMove);
        dom.ownerDocument.removeEventListener('pointerup', onPointerUp);
    }

    private function onPointerMove(event: Event): Void {
        var pointerEvent = js.html.PointerEvent(event);
        if (pointerEvent.isPrimary === false) return;

        var offsetWidth = document.body.offsetWidth;
        var clientX = pointerEvent.clientX;

        var cX = clientX < 0 ? 0 : (clientX > offsetWidth ? offsetWidth : clientX);

        var x = Math.max(335, offsetWidth - cX);

        dom.style.right = x + 'px';

        document.getElementById('sidebar').style.width = x + 'px';
        document.getElementById('player').style.right = x + 'px';
        document.getElementById('script').style.right = x + 'px';
        document.getElementById('viewport').style.right = x + 'px';

        signals.windowResize.dispatch();
    }

    public function getUIElement(): UIElement {
        return new UIElement(dom);
    }
}