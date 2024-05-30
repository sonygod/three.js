import js.flow.LabelElement;
import js.three.nodes.JoinNode;
import js.three.nodes.UniformNode;
import js.three.nodes.float;

class JoinEditor extends BaseNodeEditor {
    static var NULL_VALUE = new UniformNode(0);

    public function new() {
        super('Join', new JoinNode(), 175);

        function update() {
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
                nodes.push(float(Std.isNull(values[i]) ? NULL_VALUE : values[i]));
            }

            node.nodes = nodes;
            invalidate();
            title.setOutput(length);
        }

        var xElement = setInputAestheticsFromType(new LabelElement('x | r'), 'Number').onConnect(update);
        var yElement = setInputAestheticsFromType(new LabelElement('y | g'), 'Number').onConnect(update);
        var zElement = setInputAestheticsFromType(new LabelElement('z | b'), 'Number').onConnect(update);
        var wElement = setInputAestheticsFromType(new LabelElement('w | a'), 'Number').onConnect(update);

        add(xElement);
        add(yElement);
        add(zElement);
        add(wElement);

        update();
    }
}