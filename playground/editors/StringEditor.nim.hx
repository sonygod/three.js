import BaseNodeEditor.BaseNodeEditor;
import NodeEditorUtils.createElementFromJSON;

class StringEditor extends BaseNodeEditor {

	public function new() {

		var {element, inputNode} = createElementFromJSON({
			inputType: 'string',
			inputConnection: false
		});

		super('String', inputNode, 350);

		element.addEventListener('changeInput', function() {
			this.invalidate();
		});

		this.add(element);

	}

	public function get_stringNode() {

		return this.value;

	}

	public function getURL() {

		return this.stringNode.value;

	}

}