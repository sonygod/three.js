import three.nodes.BaseNodeEditor;
import three.elements.CodeEditorElement;
import three.nodes.js;

class JavaScriptEditor extends BaseNodeEditor {

	public var editorElement:CodeEditorElement;

	public function new(source:String) {

		var codeNode = js(source);

		super('JavaScript', codeNode, 500);

		this.setResizable(true);

		//

		this.editorElement = new CodeEditorElement(source);
		this.editorElement.addEventListener('change', function() {

			codeNode.code = this.editorElement.source;

			this.invalidate();

			this.editorElement.focus();

		});

		this.add(this.editorElement);

	}

	public function set source(value:String) {

		this.codeNode.code = value;

	}

	public function get source():String {

		return this.codeNode.code;

	}

	public function get codeNode():js {

		return this.value;

	}

}