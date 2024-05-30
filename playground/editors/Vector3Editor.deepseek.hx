import three.js.playground.editors.BaseNodeEditor;
import three.js.playground.editors.NodeEditorUtils;

class Vector3Editor extends BaseNodeEditor {

	public function new() {

		var elementAndInputNode = NodeEditorUtils.createElementFromJSON({
			inputType: 'vec3',
			inputConnection: false
		});

		var element = elementAndInputNode.element;
		var inputNode = elementAndInputNode.inputNode;

		super('Vector 3', inputNode, 325);

		element.addEventListener('changeInput', function() {
			this.invalidate();
		});

		this.add(element);

	}

}