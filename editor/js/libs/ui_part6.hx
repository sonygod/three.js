package three.js.editor.js.libs;

import js.html.SpanElement;

class UIText extends UISpan {
    public function new(text:String) {
        super();
        this.dom.className = 'Text';
        this.dom.style.cursor = 'default';
        this.dom.style.display = 'inline-block';
        setValue(text);
    }

    public function getValue():String {
        return this.dom.textContent;
    }

    public function setValue(value:String):UIText {
        if (value != null) {
            this.dom.textContent = value;
        }
        return this;
    }
}