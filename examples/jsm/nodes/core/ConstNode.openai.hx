package three.js.nodes.core;

import three.js.nodes.InputNode;
import three.js.nodes.Node;

class ConstNode extends InputNode {
    public var isConstNode:Bool = true;

    public function new(value:Dynamic, nodeType:Null<String> = null) {
        super(value, nodeType);
    }

    public function generateConst(builder:Builder):String {
        return builder.generateConst(getNodeType(builder), value);
    }

    public function generate(builder:Builder, output:Dynamic):String {
        var type = getNodeType(builder);
        return builder.format(generateConst(builder), type, output);
    }
}

Node.addNodeClass('ConstNode', ConstNode);