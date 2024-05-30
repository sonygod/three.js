import js.Browser.document;
import js.html.Element;
import three.js.editor.js.libs.UIElement;

class Resizer {

    var signals:Dynamic;
    var dom:Element;

    public function new(editor:Dynamic) {
        signals = editor.signals;

        dom = document.createElement('div');
        dom.id = 'resizer';

        dom.addEventListener('pointerdown', onPointerDown);
    }

    function onPointerDown(event:js.html.MouseEvent):Void {
        if (event.isPrimary == false) return;

        dom.ownerDocument.addEventListener('pointermove', onPointerMove);
        dom.ownerDocument.addEventListener('pointerup', onPointerUp);
    }

    function onPointerUp(event:js.html.MouseEvent):Void {
        if (event.isPrimary == false) return;

        dom.ownerDocument.removeEventListener('pointermove', onPointerMove);
        dom.ownerDocument.removeEventListener('pointerup', onPointerUp);
    }

    function onPointerMove(event:js.html.MouseEvent):Void {
        if (event.isPrimary == false) return;

        var offsetWidth = document.body.offsetWidth;
        var clientX = event.clientX;

        var cX = clientX < 0 ? 0 : clientX > offsetWidth ? offsetWidth : clientX;

        var x = Math.max(335, offsetWidth - cX); // .TabbedPanel min-width: 335px

        dom.style.right = x + 'px';

        document.getElementById('sidebar').style.width = x + 'px';
        document.getElementById('player').style.right = x + 'px';
        document.getElementById('script').style.right = x + 'px';
        document.getElementById('viewport').style.right = x + 'px';

        signals.windowResize.dispatch();
    }

    public function getUIElement():UIElement {
        return new UIElement(dom);
    }
}