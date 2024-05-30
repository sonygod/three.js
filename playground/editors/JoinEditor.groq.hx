package three.js.playground.editors;

import flow.LabelElement;
import three.nodes.JoinNode;
import three.nodes.UniformNode;
import three.nodes.FloatNode;

class JoinEditor extends BaseNodeEditor {
    private var NULL_VALUE:UniformNode = new UniformNode(0);

    public function new() {
        var node:JoinNode = new JoinNode();
        super('Join', node, 175);

        var xElement:LabelElement = setInputAestheticsFromType(new LabelElement('x | r'), 'Number');
        var yElement:LabelElement = setInputAestheticsFromType(new LabelElement('y | g'), 'Number');
        var zElement:LabelElement = setInputAestheticsFromType(new LabelElement('z | b'), 'Number');
        var wElement:LabelElement = setInputAestheticsFromType(new LabelElement('w | a'), 'Number');

        xElement.onConnect(update);
        yElement.onConnect(update);
        zElement.onConnect(update);
        wElement.onConnect(update);

        this.add(xElement);
        this.add(yElement);
        this.add(zElement);
        this.add(wElement);

        update();
    }

    private function update():Void {
        var values:Array<Dynamic> = [
            xElement.getLinkedObject(),
            yElement.getLinkedObject(),
            zElement.getLinkedObject(),
            wElement.getLinkedObject()
        ];

        var length:Int = 1;

        if (values[3] != null) length = 4;
        else if (values[2] != null) length = 3;
        else if (values[1] != null) length = 2;

        var nodes:Array<Node> = [];

        for (i in 0...length) {
            nodes.push(float(values[i] != null ? values[i] : NULL_VALUE));
        }

        node.nodes = nodes;

        this.invalidate();

        this.title.setOutput(length);
    }
}