package three.js.editor.js.libs;

import js.html.TextAreaElement;
import js.html.Event;

class UITextArea extends UIElement {
    public function new() {
        super(cast js.Browser.document.createElement('textarea'));
        this.dom.className = 'TextArea';
        this.dom.style.padding = '2px';
        this.dom.spellcheck = false;
        this.dom.setAttribute('autocomplete', 'off');

        this.dom.addEventListener('keydown', function(event:Event) {
            event.stopPropagation();
            if (event.code == 'Tab') {
                event.preventDefault();
                var cursor = this.selectionStart;
                this.value = this.value.substring(0, cursor) + '\t' + this.value.substring(cursor);
                this.selectionStart = cursor + 1;
                this.selectionEnd = this.selectionStart;
            }
        });
    }

    public function getValue():String {
        return this.dom.value;
    }

    public function setValue(value:String):UITextArea {
        this.dom.value = value;
        return this;
    }
}