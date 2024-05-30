package three.js.playground.editors;

import flow.LabelElement;
import three.nodes.NodeObject;
import three.nodes.FloatNode;
import BaseNodeEditor;

class SplitEditor extends BaseNodeEditor {
    public function new() {
        super("Split", null, 175);

        var node:NodeObject = null;

        var inputElement = setInputAestheticsFromType(new LabelElement("Input"), "node");
        inputElement.onConnect = function() {
            node = inputElement.getLinkedObject();
            if (node != null) {
                xElement.setObject(node.x);
                yElement.setObject(node.y);
                zElement.setObject(node.z);
                wElement.setObject(node.w);
            } else {
                xElement.setObject(new FloatNode());
                yElement.setObject(new FloatNode());
                zElement.setObject(new FloatNode());
                wElement.setObject(new FloatNode());
            }
        };

        var xElement = setOutputAestheticsFromType(new LabelElement("x | r"), "Number");
        xElement.setObject(new FloatNode());
        var yElement = setOutputAestheticsFromType(new LabelElement("y | g"), "Number");
        yElement.setObject(new FloatNode());
        var zElement = setOutputAestheticsFromType(new LabelElement("z | b"), "Number");
        zElement.setObject(new FloatNode());
        var wElement = setOutputAestheticsFromType(new LabelElement("w | a"), "Number");
        wElement.setObject(new FloatNode());

        this.add(inputElement);
        this.add(xElement);
        this.add(yElement);
        this.add(zElement);
        this.add(wElement);
    }
}