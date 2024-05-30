import BaseNodeEditor.BaseNodeEditor;
import NodeEditorUtils.createElementFromJSON;

class Vector2Editor extends BaseNodeEditor {

	public function new() {

		var {element, inputNode} = createElementFromJSON({
			inputType: 'vec2',
			inputConnection: false
		});

		super('Vector 2', inputNode);

		element.addEventListener('changeInput', function() {
			this.invalidate();
		});

		this.add(element);

	}

}