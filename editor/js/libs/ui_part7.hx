package three.js.editor.js.libs;

import js.html.InputElement;

class UIInput extends UIElement {
    public var dom:InputElement;

    public function new(text:String) {
        super(new InputElement("input"));

        dom.className = 'Input';
        dom.style.padding = '2px';
        dom.style.border = '1px solid transparent';

        dom.setAttribute('autocomplete', 'off');

        dom.addEventListener('keydown', function(event) {
            event.stopPropagation();
        });

        setValue(text);
    }

    public function getValue():String {
        return dom.value;
    }

    public function setValue(value:String):UIInput {
        dom.value = value;
        return this;
    }
}