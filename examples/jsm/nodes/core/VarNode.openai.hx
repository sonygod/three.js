package three.js.examples.jsm.nodes.core;

import Node;
import three.js.examples.jsm.shadernode.ShaderNode;

class VarNode extends Node {
    public var node:Node;
    public var name:String;

    public function new(node:Node, ?name:String) {
        super();
        this.node = node;
        this.name = name;
        isVarNode = true;
    }

    public function isGlobal():Bool {
        return true;
    }

    public function getHash(builder:_dynamic):String {
        return if (name != null) name else super.getHash(builder);
    }

    public function getNodeType(builder:dynamic):String {
        return node.getNodeType(builder);
    }

    public function generate(builder:dynamic):String {
        var nodeVar = builder.getVarFromNode(this, name, builder.getVectorType(getNodeType(builder)));
        var propertyName = builder.getPropertyName(nodeVar);
        var snippet = node.build(builder, nodeVar.type);
        builder.addLineFlowCode(propertyName + ' = ' + snippet);
        return propertyName;
    }
}

// Export the class as default
@:nativeGen
class VarNodeJs extends VarNode {}

// Export the class as temp
@:nativeGen
class TempNodeJs extends VarNode {}

@:nativeGen
function temp(...params:Array<Dynamic>):TempNodeJs {
    return new TempNodeJs(...params);
}

@:nativeGen
function toVar(...params:Array<Dynamic>):Void {
    temp(...params).append();
}

// Register the node class
Node.addNodeClass('VarNode', VarNodeJs);
ShaderNode.addNodeElement('temp', temp);
ShaderNode.addNodeElement('toVar', toVar);