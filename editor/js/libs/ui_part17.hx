package three.js.editor.js.libs;

import js.html.ProgressElement;

class UIProgress extends UIElement {
    public var dom:ProgressElement;

    public function new(value:Float) {
        super(cast js.Browser.document.createElement('progress'));
        this.dom.value = value;
    }

    public function setValue(value:Float) {
        this.dom.value = value;
    }
}