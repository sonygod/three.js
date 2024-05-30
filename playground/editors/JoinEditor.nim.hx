import LabelElement from 'flow';
import BaseNodeEditor from '../BaseNodeEditor.js';
import JoinNode, UniformNode, float from 'three/nodes';
import setInputAestheticsFromType from '../DataTypeLib.js';

class NULL_VALUE {
    var value:UniformNode = new UniformNode( 0 );
}

class JoinEditor extends BaseNodeEditor {

    public function new() {

        var node:JoinNode = new JoinNode();

        super('Join', node, 175);

        var update:Void->Void = function() {

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

            var nodes:Array<Dynamic> = [];

            for (i in 0...length) {

                nodes.push(float(values[i] || NULL_VALUE.value));

            }

            node.nodes = nodes;

            this.invalidate();

            this.title.setOutput(length);

        };

        var xElement:LabelElement = setInputAestheticsFromType(new LabelElement('x | r'), 'Number').onConnect(update);
        var yElement:LabelElement = setInputAestheticsFromType(new LabelElement('y | g'), 'Number').onConnect(update);
        var zElement:LabelElement = setInputAestheticsFromType(new LabelElement('z | b'), 'Number').onConnect(update);
        var wElement:LabelElement = setInputAestheticsFromType(new LabelElement('w | a'), 'Number').onConnect(update);

        this.add(xElement)
            .add(yElement)
            .add(zElement)
            .add(wElement);

        update();

    }

}