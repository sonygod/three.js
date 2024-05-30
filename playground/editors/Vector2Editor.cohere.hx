import js.NodeEditorUtils.createElementFromJSON;
import js.NodeEditorUtils.BaseNodeEditor;

class Vector2Editor extends BaseNodeEditor {
	public function new() {
		var { element, inputNode } = createElementFromJSON({
			inputType: 'vec2',
			inputConnection: false
		});

		super('Vector 2', inputNode);

		element.addEventListener('changeInput', function() {
			invalidate();
		});

		add(element);
	}
}