package three.js.examples.jm.nodes.core;

import three.js.examples.jm.nodes.Node;
import three.js.examples.jm.nodes.StructTypeNode;
import three.js.examples.jm.shadernode.ShaderNode;

class OutputStructNode extends Node {

    public var members:Array<Node>;

    public function new(?members:Array<Node>) {
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

    override public function generate(builder:Dynamic, output:Dynamic) {
        var nodeVar = builder.getVarFromNode(this);
        nodeVar.isOutputStructVar = true;
        var propertyName:String = builder.getPropertyName(nodeVar);
        var members:Array<Node> = this.members;
        var structPrefix:String = propertyName != '' ? propertyName + '.' : '';
        for (i in 0...members.length) {
            var snippet:String = members[i].build(builder, output);
            builder.addLineFlowCode('${structPrefix}m$i = $snippet');
        }
        return propertyName;
    }
}

@:export(new OutputStructNode())
var outputStruct = ShaderNode.nodeProxy(OutputStructNode);

Node.addNodeClass('OutputStructNode', OutputStructNode);