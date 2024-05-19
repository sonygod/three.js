package three.js.playground.libs;

import js.html.DOMElement;
import js.Browser;

class DraggableElement extends Element {
    public var draggable:Bool;

    public function new(draggable:Bool = true) {
        super(true);
        this.draggable = draggable;

        var onDrag = function(e:js.html.MouseEvent) {
            e.preventDefault();
            if (this.draggable) {
                draggableDOM(this.node.dom, null, { className: 'dragging node' });
            }
        };

        var dom:DOMElement = this.dom;
        dom.addEventListener('mousedown', onDrag, true);
        dom.addEventListener('touchstart', onDrag, true);
    }
}