package three.js.playground.libs;

import js.html.InputElement;
import js.html.Event;

class ToggleInput extends Input {
    public var dom:InputElement;

    public function new(value:Bool = false) {
        dom = js.Browser.document.createElement("input");
        super(dom);

        dom.type = "checkbox";
        dom.className = "toggle";
        dom.checked = value;

        dom.onclick = function(_) {
            this.dispatchEvent(new Event("click"));
        }
        dom.onchange = function(_) {
            this.dispatchEvent(new Event("change"));
        }
    }

    public function setValue(val:Bool):ToggleInput {
        dom.checked = val;
        this.dispatchEvent(new Event("change"));
        return this;
    }

    public function getValue():Bool {
        return dom.checked;
    }
}