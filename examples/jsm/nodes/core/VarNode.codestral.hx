import Node;
import Node.addNodeClass;
import ShaderNode;
import ShaderNode.addNodeElement;
import ShaderNode.nodeProxy;

class VarNode extends Node {
    public var _node: Node;
    public var _name: String;
    public var isVarNode: Bool = true;

    public function new(node: Node, ?name: String) {
        super();
        this._node = node;
        this._name = name != null ? name : null;
    }

    public function isGlobal(): Bool {
        return true;
    }

    public function getHash(builder: Builder): String {
        return this._name != null ? this._name : super.getHash(builder);
    }

    public function getNodeType(builder: Builder): String {
        return this._node.getNodeType(builder);
    }

    public function generate(builder: Builder): String {
        var nodeVar = builder.getVarFromNode(this, this._name, builder.getVectorType(this.getNodeType(builder)));
        var propertyName = builder.getPropertyName(nodeVar);
        var snippet = this._node.build(builder, nodeVar.type);
        builder.addLineFlowCode("${propertyName} = ${snippet}");
        return propertyName;
    }
}

class Main {
    static function main() {
        var temp = nodeProxy(VarNode);
        addNodeElement('temp', temp);
        addNodeElement('toVar', (...params) => temp(params).append());
        addNodeClass('VarNode', VarNode);
    }
}