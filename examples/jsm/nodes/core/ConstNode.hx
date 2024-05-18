package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.nodes.core.InputNode;

class ConstNode extends InputNode {

    public var isConstNode:Bool;

    public function new(value:Dynamic, nodeType:Null<Dynamic> = null) {
        super(value, nodeType);
        this.isConstNode = true;
    }

    public function generateConst(builder:Dynamic):Dynamic {
        return builder.generateConst(getNodeType(builder), value);
    }

    public function generate(builder:Dynamic, output:Dynamic):Dynamic {
        var type = getNodeType(builder);
        return builder.format(generateConst(builder), type, output);
    }

}

addNodeClass('ConstNode', ConstNode);