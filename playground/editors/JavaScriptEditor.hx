package three.playground.editors;

import js.html.DOMElement;
import js.three.nodes.JsNode;

class JavaScriptEditor extends BaseNodeEditor {
    private var codeNode:JsNode;
    private var editorElement:CodeEditorElement;

    public function new(source:String = '') {
        codeNode = js(source);
        super('JavaScript', codeNode, 500);
        setResizable(true);

        editorElement = new CodeEditorElement(source);
        editorElement.addEventListener('change', function() {
            codeNode.code = editorElement.source;
            invalidate();
            editorElement.focus();
        });
        add(editorElement);
    }

    private function set_source(value:String):Void {
        codeNode.code = value;
    }

    private function get_source():String {
        return codeNode.code;
    }

    private function get_codeNode():JsNode {
        return codeNode;
    }
}