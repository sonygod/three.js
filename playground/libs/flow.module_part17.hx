import js.Browser;
import js.html.InputElement;

class ColorInput extends Input {
    public function new(value:Int = 0x0099ff) {
        var dom:InputElement = Browser.document.createElement("input");
        super(dom);

        dom.type = "color";
        dom.value = numberToHex(value);

        dom.oninput = function() {
            this.dispatchEvent(new Event("change"));
        };
    }

    public function setValue(value:Int, dispatch:Bool = true) {
        return super.setValue(numberToHex(value), dispatch);
    }

    public function getValue():Int {
        return parseInt(super.getValue().substr(1), 16);
    }
}