Here is the converted Haxe code:
```
package three.js.playground.editors;

import flow.LabelElement;
import three.nodes.NodeObject;
import three.nodes.Float;

class SplitEditor extends BaseNodeEditor {
    public function new() {
        super("Split", null, 175);

        var node:NodeObject = null;

        var inputElement:LabelElement = setInputAestheticsFromType(new LabelElement("Input"), "node");
        inputElement.onConnect = function() {
            node = inputElement.getLinkedObject();

            if (node != null) {
                xElement.setObject(nodeObject(node).x);
                yElement.setObject(nodeObject(node).y);
                zElement.setObject(nodeObject(node).z);
                wElement.setObject(nodeObject(node).w);
            } else {
                xElement.setObject(Float());
                yElement.setObject(Float());
                zElement.setObject(Float());
                wElement.setObject(Float());
            }
        };

        var xElement:LabelElement = setOutputAestheticsFromType(new LabelElement("x | r"), "Number");
        xElement.setObject(Float());

        var yElement:LabelElement = setOutputAestheticsFromType(new LabelElement("y | g"), "Number");
        yElement.setObject(Float());

        var zElement:LabelElement = setOutputAestheticsFromType(new LabelElement("z | b"), "Number");
        zElement.setObject(Float());

        var wElement:LabelElement = setOutputAestheticsFromType(new LabelElement("w | a"), "Number");
        wElement.setObject(Float());

        this.add(inputElement);
        this.add(xElement);
        this.add(yElement);
        this.add(zElement);
        this.add(wElement);
    }
}
```
Note that I've assumed that the `setInputAestheticsFromType` and `setOutputAestheticsFromType` functions, as well as the `nodeObject` and `float` functions, are defined elsewhere in your codebase. If that's not the case, you'll need to modify the code accordingly. Additionally, I've used the `Float` type from the `three.nodes` package to replace the `float` function calls.