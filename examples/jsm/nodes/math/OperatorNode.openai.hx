package three.js.nodes.math;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class OperatorNode extends TempNode {

    public var op:String;
    public var aNode:Node;
    public var bNode:Node;

    public function new(op:String, aNode:Node, bNode:Node, params:Array<Node>) {
        super();

        this.op = op;

        if (params.length > 0) {
            var finalBNode = bNode;
            for (i in 0...params.length) {
                finalBNode = new OperatorNode(op, finalBNode, params[i]);
            }
            bNode = finalBNode;
        }

        this.aNode = aNode;
        this.bNode = bNode;
    }

    override public function getNodeType(builder:Dynamic, output:Dynamic):String {
        // ... (same logic as JavaScript code)
    }

    override public function generate(builder:Dynamic, output:Dynamic):String {
        // ... (same logic as JavaScript code)
    }

    override public function serialize(data:Dynamic) {
        super.serialize(data);
        data.op = this.op;
    }

    override public function deserialize(data:Dynamic) {
        super.deserialize(data);
        this.op = data.op;
    }
}

// Exporting node proxies
@:native("add")
extern class AddNode extends OperatorNode {
    public function new(aNode:Node, bNode:Node) {
        super('+', aNode, bNode, []);
    }
}

@:native("sub")
extern class SubNode extends OperatorNode {
    public function new(aNode:Node, bNode:Node) {
        super('-', aNode, bNode, []);
    }
}

// ... (similar for other operators)

// Registering node classes
Node.registerClass('add', AddNode);
Node.registerClass('sub', SubNode);
// ... (similar for other operators)