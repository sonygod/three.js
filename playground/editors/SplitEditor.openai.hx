package three.js.playground.editors;

import flow.LabelElement;
import BaseNodeEditor;
import three.nodes.nodeObject;
import three.nodes.float;

class SplitEditor extends BaseNodeEditor {

    public function new() {
        super("Split", null, 175);

        var node:Dynamic = null;

        var inputElement = setInputAestheticsFromType(new LabelElement("Input"), "node");
        inputElement.onConnect = function() {
            node = inputElement.getLinkedObject();

            if (node != null) {
                xElement.setObject(nodeObject(node).x);
                yElement.setObject(nodeObject(node).y);
                zElement.setObject(nodeObject(node).z);
                wElement.setObject(nodeObject(node).w);
            } else {
                xElement.setObject(float());
                yElement.setObject(float());
                yElement.setObject(float());
                wElement.setObject(float());
            }
        };

        var xElement = setOutputAestheticsFromType(new LabelElement("x | r"), "Number");
        xElement.setObject(float());

        var yElement = setOutputAestheticsFromType(new LabelElement("y | g"), "Number");
        yElement.setObject(float());

        var zElement = setOutputAestheticsFromType(new LabelElement("z | b"), "Number");
        zElement.setObject(float());

        var wElement = setOutputAestheticsFromType(new LabelElement("w | a"), "Number");
        wElement.setObject(float());

        this.add(inputElement)
            .add(xElement)
            .add(yElement)
            .add(zElement)
            .add(wElement);
    }
}