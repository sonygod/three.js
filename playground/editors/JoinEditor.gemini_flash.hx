import flow.LabelElement;
import three.nodes.JoinNode;
import three.nodes.UniformNode;
import three.nodes.float;
import BaseNodeEditor;
import DataTypeLib;

class JoinEditor extends BaseNodeEditor {

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
                nodes.push(float(values[i] != null ? values[i] : NULL_VALUE));
            }

            node.nodes = nodes;
            this.invalidate();
            this.title.setOutput(length);
        };

        var NULL_VALUE = new UniformNode(0);

        var xElement = DataTypeLib.setInputAestheticsFromType(new LabelElement('x | r'), 'Number').onConnect(update);
        var yElement = DataTypeLib.setInputAestheticsFromType(new LabelElement('y | g'), 'Number').onConnect(update);
        var zElement = DataTypeLib.setInputAestheticsFromType(new LabelElement('z | b'), 'Number').onConnect(update);
        var wElement = DataTypeLib.setInputAestheticsFromType(new LabelElement('w | a'), 'Number').onConnect(update);

        this.add(xElement)
            .add(yElement)
            .add(zElement)
            .add(wElement);

        update();
    }
}