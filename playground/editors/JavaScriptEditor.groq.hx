Here is the equivalent Haxe code:
```
package three.playground.editors;

import three.nodes.js.Js;
import js.html.Element;

class JavaScriptEditor extends BaseNodeEditor {
    
    private var codeNode:Js;
    private var editorElement:CodeEditorElement;

    public function new(?source:String = '') {
        codeNode = Js.create(source);
        super('JavaScript', codeNode, 500);
        setResizable(true);

        editorElement = new CodeEditorElement(source);
        editorElement.addEventListener('change', onChange);
        add(editorElement);
    }

    private function onChange(_) {
        codeNode.code = editorElement.source;
        invalidate();
        editorElement.focus();
    }

    private function set_source(value:String) {
        codeNode.code = value;
    }

    private function get_source():String {
        return codeNode.code;
    }

    private function get_codeNode():Js {
        return codeNode;
    }
}
```
Note that I've assumed that the `BaseNodeEditor` class, `CodeEditorElement` class, and `Js` class are already defined in your Haxe project.

Also, I've used the `js.html.Element` type for the `editorElement` variable, assuming that it's an HTML element. If that's not the case, you may need to adjust the type accordingly.

I've also used the `create` method to create a new `Js` object, assuming that it's the equivalent of the `js` function in the original JavaScript code.

Let me know if you have any questions or need further assistance!