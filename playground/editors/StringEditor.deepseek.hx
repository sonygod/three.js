import three.js.playground.editors.BaseNodeEditor;
import three.js.playground.editors.NodeEditorUtils;

class StringEditor extends BaseNodeEditor {

	public function new() {

		var elementAndInputNode = NodeEditorUtils.createElementFromJSON( {
			inputType: 'string',
			inputConnection: false
		} );

		var element = elementAndInputNode.element;
		var inputNode = elementAndInputNode.inputNode;

		super('String', inputNode, 350);

		element.addEventListener('changeInput', function() {
			this.invalidate();
		});

		this.add(element);

	}

	public function get stringNode():Dynamic {

		return this.value;

	}

	public function getURL():String {

		return this.stringNode.value;

	}

}