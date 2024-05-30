import LabelElement from 'flow';
import BaseNodeEditor from '../BaseNodeEditor.js';
import {createElementFromJSON} from '../NodeEditorUtils.js';
import {split, float} from 'three/nodes';
import {setInputAestheticsFromType} from '../DataTypeLib.js';

class SwizzleEditor extends BaseNodeEditor {

	public function new() {

		var node = split(float(), 'x');

		super('Swizzle', node, 175);

		var inputElement = setInputAestheticsFromType(new LabelElement('Input'), 'node').onConnect(function() {

			node.node = inputElement.getLinkedObject() || float();

		});

		this.add(inputElement);

		//

		var componentsElement = createElementFromJSON({
			inputType: 'String',
			allows: 'xyzwrgba',
			transform: 'lowercase',
			options: ['x', 'y', 'z', 'w', 'r', 'g', 'b', 'a'],
			maxLength: 4
		});

		componentsElement.addEventListener('changeInput', function() {

			var string = componentsElement.value.value;

			node.components = string || 'x';

			this.invalidate();

		});

		this.add(componentsElement);

	}

}