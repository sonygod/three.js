package three.js.editor.js.libs;

import js.html_DIVElement;
import js.Browser;

class UIDiv extends UIElement {

    public function new() {
        super(Browser.document.createElement("div"));
    }

}