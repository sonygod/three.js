import js.three.nodes.Split;
import js.three.nodes.Float;
import js.flow.LabelElement;
import js.DataTypeLib.setInputAestheticsFromType;
import js.NodeEditorUtils.createElementFromJSON;

class SwizzleEditor extends js.BaseNodeEditor {
	public function new() {
		super('Swizzle', Split(Float(), 'x'), 175);

		var inputElement = setInputAestheticsFromType(LabelElement('Input'), 'node');
		inputElement.onConnect = function() {
			node.node = inputElement.getLinkedObject() or Float();
		};
		this.add(inputElement);

		var componentsElement = createElementFromJSON({
			inputType: 'String',
			allows: 'xyzwrgba',
			transform: 'lowercase',
			options: ['x', 'y', 'z', 'w', 'r', 'g', 'b', 'a'],
			maxLength: 4
		});
		componentsElement.addEventListener('changeInput', function() {
			var string = componentsElement.value.value;
			node.components = string or 'x';
			this.invalidate();
		});
		this.add(componentsElement);
	}
}