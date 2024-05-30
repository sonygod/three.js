import js.three.nodes.BaseNodeEditor;
import js.three.nodes.CodeEditorElement;
import js.three.nodes.js;

class JavaScriptEditor extends BaseNodeEditor {
	public var editorElement:CodeEditorElement;

	public function new(source:String = "") {
		var codeNode = js(source);
		super("JavaScript", codeNode, 500);
		setResizable(true);
		editorElement = new CodeEditorElement(source);
		editorElement.addEventListener("change", function() {
			codeNode.code = editorElement.source;
			invalidate();
			editorElement.focus();
		});
		add(editorElement);
	}

	public var source:String get {
		return codeNode.code;
	}

	public function set(value:String) {
		codeNode.code = value;
	}

	public function get_codeNode():Dynamic {
		return value;
	}
}