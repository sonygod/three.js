import three.js.nodes.JsNode;
import playground.editors.BaseNodeEditor;
import playground.elements.CodeEditorElement;

class JavaScriptEditor extends BaseNodeEditor {

    public var editorElement:CodeEditorElement;
    private var _codeNode:JsNode;

    public function new(source:String = '') {

        var codeNode = js(source);

        super('JavaScript', codeNode, 500);

        this.setResizable(true);

        this.editorElement = new CodeEditorElement(source);
        this.editorElement.addEventListener('change', function() {

            codeNode.code = this.editorElement.source;

            this.invalidate();

            this.editorElement.focus();

        });

        this.add(this.editorElement);
    }

    public function set_source(value:String):Void {
        this._codeNode.code = value;
    }

    public function get_source():String {
        return this._codeNode.code;
    }

    public function get_codeNode():JsNode {
        return this.value;
    }

}