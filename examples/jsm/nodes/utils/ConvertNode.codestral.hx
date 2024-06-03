import Node from '../core/Node';
import NodeUtils from '../core/NodeUtils';

class ConvertNode extends Node {
    public var node: Node;
    public var convertTo: String;

    public function new(node: Node, convertTo: String) {
        super();
        this.node = node;
        this.convertTo = convertTo;
    }

    public function getNodeType(builder: NodeBuilder): String {
        var requestType = this.node.getNodeType(builder);
        var convertTo: Null<String> = null;

        for (type in this.convertTo.split('|')) {
            if (convertTo == null || builder.getTypeLength(requestType) == builder.getTypeLength(type)) {
                convertTo = type;
            }
        }

        return convertTo;
    }

    public override function serialize(data: Dynamic) {
        super.serialize(data);
        data.convertTo = this.convertTo;
    }

    public override function deserialize(data: Dynamic) {
        super.deserialize(data);
        this.convertTo = data.convertTo;
    }

    public override function generate(builder: NodeBuilder, output: String): String {
        var type = this.getNodeType(builder);
        var snippet = this.node.build(builder, type);
        return builder.format(snippet, type, output);
    }
}

NodeUtils.addNodeClass('ConvertNode', ConvertNode);