package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.nodes.Node;
import three.js.examples.jsm.shadernode.ShaderNode;

class BypassNode extends Node {
    public var isBypassNode:Bool = true;

    public var outputNode:Node;
    public var callNode:Node;

    public function new(returnNode:Node, callNode:Node) {
        super();
        this.outputNode = returnNode;
        this.callNode = callNode;
    }

    public function getNodeType(builder:Dynamic):String {
        return outputNode.getNodeType(builder);
    }

    public function generate(builder:Dynamic):String {
        var snippet:String = callNode.build(builder, 'void');
        if (snippet != '') {
            builder.addLineFlowCode(snippet);
        }
        return outputNode.build(builder);
    }
}

// exports
@:keep
@:expose("bypass")
var bypass = nodeProxy(BypassNode);

@:keep
@:expose("BypassNode")
var BypassNode_export = BypassNode;

addNodeElement('bypass', bypass);
addNodeClass('BypassNode', BypassNode_export);