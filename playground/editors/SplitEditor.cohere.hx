import js.three.nodes.Node;
import js.three.nodes.NodeObject;
import js.three.nodes.types.Float;

class SplitEditor extends BaseNodeEditor {
    public function new(defaultName:String) {
        super(defaultName, null, 175);

        var node:Node = null;

        var inputElement = setInputAestheticsFromType(new LabelElement("Input"), "node") as LabelElement;
        inputElement.onConnect = function() {
            node = inputElement.getLinkedObject();

            if (node != null) {
                xElement.setObject(NodeObject.x(node));
                yElement.setObject(NodeObject.y(node));
                zElement.setObject(NodeObject.z(node));
                wElement.setObject(NodeObject.w(node));
            } else {
                xElement.setObject(new Float());
                yElement.setObject(new Float());
                zElement.setObject(new Float());
                wElement.setObject(new Float());
            }
        };

        var xElement = setOutputAestheticsFromType(new LabelElement("x | r"), "Number") as LabelElement;
        xElement.setObject(new Float());

        var yElement = setOutputAestheticsFromType(new LabelElement("y | g"), "Number") as LabelElement;
        yElement.setObject(new Float());

        var zElement = setOutputAestheticsFromType(new LabelElement("z | b"), "Number") as LabelElement;
        zElement.setObject(new Float());

        var wElement = setOutputAestheticsFromType(new LabelElement("w | a"), "Number") as LabelElement;
        wElement.setObject(new Float());

        this.add(inputElement);
        this.add(xElement);
        this.add(yElement);
        this.add(zElement);
        this.add(wElement);
    }
}