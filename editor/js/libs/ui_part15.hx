package three.js.editor.js.libs;

import js.html.Element;

class UIHorizontalRule extends UIElement {
    public function new() {
        super(Element.createElement('hr'));
        this.dom.className = 'HorizontalRule';
    }
}