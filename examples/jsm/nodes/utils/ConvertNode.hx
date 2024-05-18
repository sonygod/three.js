package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;

class ConvertNode extends Node {

    public var node:Node;
    public var convertTo:String;

    public function new(node:Node, convertTo:String) {
        super();
        this.node = node;
        this.convertTo = convertTo;
    }

    public function getNodeType(builder:Dynamic):String {
        var requestType:String = node.getNodeType(builder);
        var convertTo:String = null;

        for (overloadingType in convertTo.split("|")) {
            if (convertTo == null || builder.getTypeLength(requestType) == builder.getTypeLength(overloadingType)) {
                convertTo = overloadingType;
            }
        }

        return convertTo;
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.convertTo = this.convertTo;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        this.convertTo = data.convertTo;
    }

    public function generate(builder:Dynamic, output:Dynamic) {
        var node:Node = this.node;
        var type:String = this.getNodeType(builder);

        var snippet = node.build(builder, type);

        return builder.format(snippet, type, output);
    }

}

// Register the node class
three.js.core.addNodeClass('ConvertNode', ConvertNode);