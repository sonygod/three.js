package three.js.editor.js.libs;

import js.html.Element;
import js.Browser;

class UITab extends UIText {
    public var parent:Dynamic;

    public function new(text:String, parent:Dynamic) {
        super(text);

        this.dom.className = 'Tab';

        this.parent = parent;

        this.dom.addEventListener('click', function(event) {
            parent.select(dom.id);
        });
    }
}