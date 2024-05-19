package three.js.playground.editors;

import flow.LabelElement;
import three.nodes.JoinNode;
import three.nodes.UniformNode;
import three.nodes.Float;

class JoinEditor extends BaseNodeEditor {
    static var NULL_VALUE = new UniformNode(0);

    public function new() {
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
                nodes.push(Float(values[i] != null ? values[i] : NULL_VALUE));
            }

            node.nodes = nodes;

            invalidate();

            title.setOutput(length);
        };

        var xElement = setInputAestheticsFromType(new LabelElement('x | r'), 'Number').onConnect(update);
        var yElement = setInputAestheticsFromType(new LabelElement('y | g'), 'Number').onConnect(update);
        var zElement = setInputAestheticsFromType(new LabelElement('z | b'), 'Number').onConnect(update);
        var wElement = setInputAestheticsFromType(new LabelElement('w | a'), 'Number').onConnect(update);

        add(xElement).add(yElement).add(zElement).add(wElement);

        update();
    }
}