import BaseNodeEditor.BaseNodeEditor;
import NodeEditorUtils.createElementFromJSON;

class Vector3Editor extends BaseNodeEditor {

	public function new() {

		var {element, inputNode} = createElementFromJSON({
			inputType: 'vec3',
			inputConnection: false
		});

		super('Vector 3', inputNode, 325);

		element.addEventListener('changeInput', function() {
			this.invalidate();
		});

		this.add(element);

	}

}