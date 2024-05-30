package three.js.playground.editors;

import flow.LabelElement;
import three.nodes.JoinNode;
import three.nodes.UniformNode;
import three.nodes.FloatNode;

class JoinEditor extends BaseNodeEditor {
	
	override public function new() {
		var node = new JoinNode();
		super('Join', node, 175);

		var update = function() {
			var values = [
				xElement.getLinkedObject(),
				yElement.getLinkedObject(),
				zElement.getLinkedObject(),
				wElement.getLinkedObject()
			];

			var length = 1;

			if (values[3] != null) length = 4;
			else if (values[2] != null) length = 3;
			else if (values[1] != null) length = 2;

			var nodes = [];

			for (i in 0...length) {
				nodes.push(new FloatNode(values[i] != null ? values[i] : NULL_VALUE));
			}

			node.nodes = nodes;

			invalidate();
			title.setOutput(length);
		};

		xElement = setInputAestheticsFromType(new LabelElement('x | r'), 'Number');
		yElement = setInputAestheticsFromType(new LabelElement('y | g'), 'Number');
		zElement = setInputAestheticsFromType(new LabelElement('z | b'), 'Number');
		wElement = setInputAestheticsFromType(new LabelElement('w | a'), 'Number');

		xElement.onConnect = update;
		yElement.onConnect = update;
		zElement.onConnect = update;
		wElement.onConnect = update;

		add(xElement);
		add(yElement);
		add(zElement);
		add(wElement);

		update();
	}

	static var NULL_VALUE = new UniformNode(0.0);
}