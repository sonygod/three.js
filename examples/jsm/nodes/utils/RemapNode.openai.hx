package three.js.nodes.utils;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class RemapNode extends Node {
    public var node:ShaderNode;
    public var inLowNode:ShaderNode;
    public var inHighNode:ShaderNode;
    public var outLowNode:ShaderNode;
    public var outHighNode:ShaderNode;
    public var doClamp:Bool;

    public function new(node:ShaderNode, inLowNode:ShaderNode, inHighNode:ShaderNode, ?outLowNode:ShaderNode, ?outHighNode:ShaderNode) {
        super();
        this.node = node;
        this.inLowNode = inLowNode;
        this.inHighNode = inHighNode;
        this.outLowNode = outLowNode != null ? outLowNode : new FLOAT(0);
        this.outHighNode = outHighNode != null ? outHighNode : new FLOAT(1);
        this.doClamp = true;
    }

    public function setup():ShaderNode {
        var t = node.subtract(inLowNode).divide(inHighNode.subtract(inLowNode));
        if (doClamp) t = t.clamp();
        return t.multiply(outHighNode.subtract(outLowNode)).add(outLowNode);
    }
}

// Export
#if js
extern class RemapNode {}
#else
extern class RemapNode extends Node {}
#end

// Create node proxies
var remap = ShaderNode.nodeProxy(RemapNode, null, null, { doClamp: false });
var remapClamp = ShaderNode.nodeProxy(RemapNode);

// Register node elements
ShaderNode.addNodeElement('remap', remap);
ShaderNode.addNodeElement('remapClamp', remapClamp);

// Register node class
ShaderNode.addNodeClass('RemapNode', RemapNode);