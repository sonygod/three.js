import three.js.examples.jsm.nodes.core.Node;

class ConvertNode extends Node {

    public var node:Node;
    public var convertTo:String;

    public function new(node:Node, convertTo:String) {
        super();
        this.node = node;
        this.convertTo = convertTo;
    }

    public function getNodeType(builder:Dynamic):String {
        var requestType = this.node.getNodeType(builder);
        var convertTo:String = null;
        var overloadingTypes = this.convertTo.split('|');
        for (overloadingType in overloadingTypes) {
            if (convertTo == null || builder.getTypeLength(requestType) == builder.getTypeLength(overloadingType)) {
                convertTo = overloadingType;
            }
        }
        return convertTo;
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.convertTo = this.convertTo;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.convertTo = data.convertTo;
    }

    public function generate(builder:Dynamic, output:Dynamic):Dynamic {
        var node = this.node;
        var type = this.getNodeType(builder);
        var snippet = node.build(builder, type);
        return builder.format(snippet, type, output);
    }

}

three.js.examples.jsm.nodes.utils.ConvertNode = ConvertNode;

three.js.examples.jsm.nodes.core.Node.addNodeClass('ConvertNode', ConvertNode);