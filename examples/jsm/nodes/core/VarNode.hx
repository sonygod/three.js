package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.nodes.Node;
import three.js.examples.jsm.shadernode.ShaderNode;

class VarNode extends Node {
    public var node:Dynamic;
    public var name:String;

    public function new(node:Dynamic, ?name:String) {
        super();
        this.node = node;
        this.name = name;
        this.isVarNode = true;
    }

    public function isGlobal():Bool {
        return true;
    }

    public function getHash(builder:Dynamic):String {
        return if (name != null) name else super.getHash(builder);
    }

    public function getNodeType(builder:Dynamic):String {
        return node.getNodeType(builder);
    }

    public function generate(builder:Dynamic):String {
        var nodeVar = builder.getVarFromNode(this, name, builder.getVectorType(getNodeType(builder)));
        var propertyName = builder.getPropertyName(nodeVar);
        var snippet = node.build(builder, nodeVar.type);
        builder.addLineFlowCode('${propertyName} = ${snippet}');
        return propertyName;
    }
}

class VarNodeBuilder {
    static public function temp(?params:Array<Dynamic>):VarNode {
        return new VarNode(null, null).append();
    }

    static public function toVar(?params:Array<Dynamic>):VarNode {
        return temp(params).append();
    }
}

Node.addNodeClass('VarNode', VarNode);
Node.addNodeElement('temp', VarNodeBuilder.temp);
Node.addNodeElement('toVar', VarNodeBuilder.toVar);