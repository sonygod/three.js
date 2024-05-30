import js.Browser.PointerEvent;
import js.Browser.Document;
import js.Browser.Event;

class Resizer {
    static function new(editor:Editor) {
        var signals = editor.signals;
        var dom = Document.createElement('div');
        dom.id = 'resizer';

        function onPointerDown(event:PointerEvent) {
            if (!event.isPrimary) return;
            dom.ownerDocument.addEventListener('pointermove', onPointerMove);
            dom.ownerDocument.addEventListener('pointerup', onPointerUp);
        }

        function onPointerUp(event:PointerEvent) {
            if (!event.isPrimary) return;
            dom.ownerDocument.removeEventListener('pointermove', onPointerMove);
            dom.ownerDocument.removeEventListener('pointerup', onPointerUp);
        }

        function onPointerMove(event:PointerEvent) {
            var offsetWidth = Document.body.offsetWidth;
            var clientX = event.clientX;
            var cX = if (clientX < 0) 0 else if (clientX > offsetWidth) offsetWidth else clientX;
            var x = Math.max(335, offsetWidth - cX); // .TabbedPanel min-width: 335px
            dom.style.right = x + 'px';
            Document.getElementById('sidebar').style.width = x + 'px';
            Document.getElementById('player').style.right = x + 'px';
            Document.getElementById('script').style.right = x + 'px';
            Document.getElementById('viewport').style.right = x + 'px';
            signals.windowResize.dispatch();
        }

        dom.addEventListener('pointerdown', onPointerDown);
        return UIElement.new(dom);
    }
}

class UIElement {
    static function new(dom:Dynamic) -> UIElement {
        throw null; // TODO: Implement
    }
}

class Editor {
    var signals:Dynamic;
}