package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.nodes.Node;

class BypassNode extends Node {
    public var isBypassNode:Bool = true;
    public var outputNode:Node;
    public var callNode:Node;

    public function new(returnNode:Node, callNode:Node) {
        super();
        this.outputNode = returnNode;
        this.callNode = callNode;
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return outputNode.getNodeType(builder);
    }

    public function generate(builder:Dynamic):Void {
        var snippet:String = callNode.build(builder, 'void');
        if (snippet != '') {
            builder.addLineFlowCode(snippet);
        }
        outputNode.build(builder);
    }
}

// Export the class
extern class BypassNode extends Node {}

// Create a node proxy
var bypass:Node = nodeProxy(BypassNode);

// Add the node element
NodeElements.addNodeElement('bypass', bypass);

// Add the node class
Node.addNodeClass('BypassNode', BypassNode);