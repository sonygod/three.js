import three.js.playground.editors.BaseNodeEditor;
import three.js.playground.editors.NodeEditorUtils;

class Vector4Editor extends BaseNodeEditor {

	public function new() {

		var elementAndInputNode = NodeEditorUtils.createElementFromJSON({
			inputType: 'vec4',
			inputConnection: false
		});

		var element = elementAndInputNode.element;
		var inputNode = elementAndInputNode.inputNode;

		super('Vector 4', inputNode, 350);

		element.addEventListener('changeInput', function() {
			this.invalidate();
		});

		this.add(element);

	}

}