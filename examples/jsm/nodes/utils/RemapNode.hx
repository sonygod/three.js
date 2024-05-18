package three.js.examples.jvm.nodes.utils;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class RemapNode extends Node {

    public var node:Node;
    public var inLowNode:Node;
    public var inHighNode:Node;
    public var outLowNode:Float;
    public var outHighNode:Float;
    public var doClamp:Bool;

    public function new(node:Node, inLowNode:Node, inHighNode:Node, outLowNode:Float = 0, outHighNode:Float = 1) {
        super();
        this.node = node;
        this.inLowNode = inLowNode;
        this.inHighNode = inHighNode;
        this.outLowNode = outLowNode;
        this.outHighNode = outHighNode;
        this.doClamp = true;
    }

    public function setup():Float {
        var t:Float = (node.value - inLowNode.value) / (inHighNode.value - inLowNode.value);
        if (doClamp) t = Math.min(Math.max(t, 0), 1);
        return t * (outHighNode - outLowNode) + outLowNode;
    }

}

// Exports
@:keep
@:native('remap')
private static var remap:ShaderNode = nodeProxy(RemapNode, null, null, { doClamp: false });

@:keep
@:native('remapClamp')
private static var remapClamp:ShaderNode = nodeProxy(RemapNode);

addNodeElement('remap', remap);
addNodeElement('remapClamp', remapClamp);

addNodeClass('RemapNode', RemapNode);