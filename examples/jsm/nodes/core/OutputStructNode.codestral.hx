import Node from './Node';
import StructTypeNode from './StructTypeNode';
import ShaderNode from '../shadernode/ShaderNode';

class OutputStructNode extends Node {

    public var members: Array<Node>;
    public var isOutputStructNode: Bool = true;

    public function new(...members: Node[]) {
        super();
        this.members = members;
    }

    override public function setup(builder: Builder): Void {
        super.setup(builder);

        var types: Array<NodeType> = [];

        for (i in 0...this.members.length) {
            types.push(this.members[i].getNodeType(builder));
        }

        this.nodeType = builder.getStructTypeFromNode(new StructTypeNode(types)).name;
    }

    override public function generate(builder: Builder, output: Output): String {
        var nodeVar: NodeVar = builder.getVarFromNode(this);
        nodeVar.isOutputStructVar = true;

        var propertyName: String = builder.getPropertyName(nodeVar);

        var structPrefix: String = propertyName !== '' ? propertyName + '.' : '';

        for (i in 0...this.members.length) {
            var snippet: String = this.members[i].build(builder, output);
            builder.addLineFlowCode(structPrefix + 'm' + i + ' = ' + snippet);
        }

        return propertyName;
    }
}

class OutputStruct {
    public static function call(...members: Node[]): Node {
        return ShaderNode.nodeProxy(new OutputStructNode(members));
    }
}

Node.addNodeClass('OutputStructNode', OutputStructNode);