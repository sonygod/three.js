import three.js.playground.editors.BaseNodeEditor;
import three.js.playground.editors.NodeEditorUtils;

class Vector2Editor extends BaseNodeEditor {

	public function new() {

		var elementAndInputNode = NodeEditorUtils.createElementFromJSON( {
			inputType: 'vec2',
			inputConnection: false
		} );

		var element = elementAndInputNode.element;
		var inputNode = elementAndInputNode.inputNode;

		super('Vector 2', inputNode);

		element.addEventListener('changeInput', function() {
			this.invalidate();
		});

		this.add(element);

	}

}