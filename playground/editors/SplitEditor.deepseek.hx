import flow.LabelElement;
import three.nodes.nodeObject;
import three.nodes.float;
import BaseNodeEditor from '../BaseNodeEditor.hx';
import DataTypeLib from '../DataTypeLib.hx';

class SplitEditor extends BaseNodeEditor {

	public function new() {

		super('Split', null, 175);

		var node:Null<Dynamic> = null;

		var inputElement = DataTypeLib.setInputAestheticsFromType(new LabelElement('Input'), 'node').onConnect(function() {

			node = inputElement.getLinkedObject();

			if (node !== null) {

				xElement.setObject(nodeObject(node).x);
				yElement.setObject(nodeObject(node).y);
				zElement.setObject(nodeObject(node).z);
				wElement.setObject(nodeObject(node).w);

			} else {

				xElement.setObject(float());
				yElement.setObject(float());
				zElement.setObject(float());
				wElement.setObject(float());

			}

		});

		var xElement = DataTypeLib.setOutputAestheticsFromType(new LabelElement('x | r'), 'Number').setObject(float());
		var yElement = DataTypeLib.setOutputAestheticsFromType(new LabelElement('y | g'), 'Number').setObject(float());
		var zElement = DataTypeLib.setOutputAestheticsFromType(new LabelElement('z | b'), 'Number').setObject(float());
		var wElement = DataTypeLib.setOutputAestheticsFromType(new LabelElement('w | a'), 'Number').setObject(float());

		this.add(inputElement)
			.add(xElement)
			.add(yElement)
			.add(zElement)
			.add(wElement);

	}

}