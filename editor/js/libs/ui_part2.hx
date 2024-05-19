package three.js.editor.js.libs;

import js.html.SpanElement;

class UISpan extends UIElement {
    public function new() {
        super(cast document.createElement('span'));
    }
}