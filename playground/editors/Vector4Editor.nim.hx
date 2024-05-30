import BaseNodeEditor.BaseNodeEditor;
import NodeEditorUtils.createElementFromJSON;

class Vector4Editor extends BaseNodeEditor {

	public function new() {

		var {element, inputNode} = createElementFromJSON({
			inputType: 'vec4',
			inputConnection: false
		});

		super('Vector 4', inputNode, 350);

		element.addEventListener('changeInput', function() {
			this.invalidate();
		});

		this.add(element);

	}

}