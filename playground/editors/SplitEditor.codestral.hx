import flow.LabelElement;
import BaseNodeEditor from '../BaseNodeEditor';
import three.nodes.nodeObject;
import three.nodes.float;
import DataTypeLib.setInputAestheticsFromType;
import DataTypeLib.setOutputAestheticsFromType;

class SplitEditor extends BaseNodeEditor {

	public function new() {
		super('Split', null, 175);

		var node:Dynamic = null;

		var inputElement = setInputAestheticsFromType(new LabelElement('Input'), 'node').onConnect(() -> {

			node = inputElement.getLinkedObject();

			if (node != null) {
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

		var xElement = setOutputAestheticsFromType(new LabelElement('x | r'), 'Number').setObject(float());
		var yElement = setOutputAestheticsFromType(new LabelElement('y | g'), 'Number').setObject(float());
		var zElement = setOutputAestheticsFromType(new LabelElement('z | b'), 'Number').setObject(float());
		var wElement = setOutputAestheticsFromType(new LabelElement('w | a'), 'Number').setObject(float());

		this.add(inputElement)
			.add(xElement)
			.add(yElement)
			.add(zElement)
			.add(wElement);
	}
}