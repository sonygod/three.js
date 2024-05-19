package three.js.editor.js.libs;

import js.html.DivElement;
import js.Browser;

class ListboxItem extends UIDiv {
    private var parent:Dynamic;

    public function new(parent:Dynamic) {
        super();
        this.dom.className = 'ListboxItem';
        this.parent = parent;

        var scope = this;
        var onClick = function(event:js.html.MouseEvent) {
            if (scope.parent != null) {
                scope.parent.setValue(scope.getId());
            }
        };
        this.dom.addEventListener('click', onClick);
    }
}