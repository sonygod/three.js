import flow.LabelElement;
import three.nodes.BaseNodeEditor;
import three.nodes.NodeEditorUtils;
import three.nodes.split;
import three.nodes.float;
import three.nodes.DataTypeLib;

class SwizzleEditor extends BaseNodeEditor {

	public function new() {

		var node = split( float(), 'x' );

		super('Swizzle', node, 175);

		var inputElement = DataTypeLib.setInputAestheticsFromType(new LabelElement('Input'), 'node');
		inputElement.onConnect(function () {

			node.node = inputElement.getLinkedObject() || float();

		});

		this.add(inputElement);

		//

		var componentsElement = NodeEditorUtils.createElementFromJSON({
			inputType: 'String',
			allows: 'xyzwrgba',
			transform: 'lowercase',
			options: [ 'x', 'y', 'z', 'w', 'r', 'g', 'b', 'a' ],
			maxLength: 4
		});

		componentsElement.addEventListener('changeInput', function () {

			var string = componentsElement.value.value;

			node.components = string || 'x';

			this.invalidate();

		});

		this.add(componentsElement);

	}

}