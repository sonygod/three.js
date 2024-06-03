import flow.LabelElement;
import BaseNodeEditor;
import three.nodes.JoinNode;
import three.nodes.UniformNode;
import three.nodes.float;
import DataTypeLib.setInputAestheticsFromType;

class JoinEditor extends BaseNodeEditor {

    private var node:JoinNode;
    private var xElement:LabelElement;
    private var yElement:LabelElement;
    private var zElement:LabelElement;
    private var wElement:LabelElement;
    private static var NULL_VALUE:UniformNode = new UniformNode(0);

    public function new() {
        this.node = new JoinNode();
        super('Join', this.node, 175);
        this.init();
    }

    private function init():Void {
        this.xElement = setInputAestheticsFromType(new LabelElement('x | r'), 'Number').onConnect(this.update);
        this.yElement = setInputAestheticsFromType(new LabelElement('y | g'), 'Number').onConnect(this.update);
        this.zElement = setInputAestheticsFromType(new LabelElement('z | b'), 'Number').onConnect(this.update);
        this.wElement = setInputAestheticsFromType(new LabelElement('w | a'), 'Number').onConnect(this.update);

        this.add(this.xElement)
            .add(this.yElement)
            .add(this.zElement)
            .add(this.wElement);

        this.update();
    }

    private function update():Void {
        var values = [
            this.xElement.getLinkedObject(),
            this.yElement.getLinkedObject(),
            this.zElement.getLinkedObject(),
            this.wElement.getLinkedObject()
        ];

        var length = 1;

        if (values[3] != null) length = 4;
        else if (values[2] != null) length = 3;
        else if (values[1] != null) length = 2;

        var nodes = [];

        for (var i = 0; i < length; i++) {
            nodes.push(float(values[i] != null ? values[i] : JoinEditor.NULL_VALUE));
        }

        this.node.nodes = nodes;

        this.invalidate();

        this.title.setOutput(length);
    }
}