package three.js.examples.jsm.nodes.core;

import Node;
import StructTypeNode;
import shadernode.ShaderNode;

class OutputStructNode extends Node {
    public var members:Array<Node>;
    public var isOutputStructNode:Bool;

    public function new(members:Array<Node>) {
        super();
        this.members = members;
        this.isOutputStructNode = true;
    }

    override public function setup(builder:Dynamic) {
        super.setup(builder);
        var members:Array<Node> = this.members;
        var types:Array<String> = [];
        for (i in 0...members.length) {
            types.push(members[i].getNodeType(builder));
        }
        this.nodeType = builder.getStructTypeFromNode(new StructTypeNode(types)).name;
    }

    override public function generate(builder:Dynamic, output:Dynamic):String {
        var nodeVar = builder.getVarFromNode(this);
        nodeVar.isOutputStructVar = true;
        var propertyName = builder.getPropertyName(nodeVar);
        var members:Array<Node> = this.members;
        var structPrefix:String = propertyName != '' ? propertyName + '.' : '';
        for (i in 0...members.length) {
            var snippet = members[i].build(builder, output);
            builder.addLineFlowCode('${structPrefix}m$i = $snippet');
        }
        return propertyName;
    }
}

@:keep class OutputStructNodeProxy extends OutputStructNode {
    public function new(members:Array<Node>) {
        super(members);
    }
}

@:keep extern class ShaderNode {
    public static function nodeProxy<T>(nodeClass:Class<T>):T;
}

@:keep class StructTypeNode {
    public function new(types:Array<String>) {}
    public function getNodeType(builder:Dynamic):String {
        return builder.getStructTypeFromNode(this).name;
    }
}

@:keep class Node {
    public function new() {}
    public function setup(builder:Dynamic):Void {}
    public function generate(builder:Dynamic, output:Dynamic):String {
        return '';
    }
}

@:keep class OutputStructNodeDefault extends OutputStructNodeProxy {
    public function new(members:Array<Node>) {
        super(members);
    }
}

// export default OutputStructNode;
@:keep(var) outputStruct = ShaderNode.nodeProxy(OutputStructNode);
Node.addNodeClass('OutputStructNode', OutputStructNode);