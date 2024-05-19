import js.html.Element;
import js.Browser;

class UICheckbox extends UIElement {
    public var dom:Element;

    public function new(booleanValue:Bool) {
        super(Browser.document.createElement("input"));
        dom.className = 'Checkbox';
        dom.type = 'checkbox';

        dom.addEventListener("pointerdown", function(event) {
            event.stopPropagation();
        });

        setValue(booleanValue);
    }

    public function getValue():Bool {
        return dom.checked;
    }

    public function setValue(value:Bool):UICheckbox {
        if (value != null) {
            dom.checked = value;
        }
        return this;
    }
}