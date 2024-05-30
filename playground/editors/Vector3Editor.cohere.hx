import js.NodeEditorUtils.createElementFromJSON;
import js.BaseNodeEditor.BaseNodeEditor;

class Vector3Editor extends BaseNodeEditor {
	public function new() {
		var { element, inputNode } = createElementFromJSON({
			inputType: 'vec3',
			inputConnection: false
		});

		super('Vector 3', inputNode, 325);

		element.addEventListener('changeInput', function() {
			invalidate();
		});

		add(element);
	}
}