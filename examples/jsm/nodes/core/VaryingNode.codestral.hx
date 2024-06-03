import Node from './Node';
import NodeShaderStage from './constants';
import ShaderNode from '../shadernode/ShaderNode';

class VaryingNode extends Node {

    public var node: Node;
    public var name: Null<String>;
    public var isVaryingNode: Bool = true;

    public function new(node: Node, ?name: String) {
        super();

        this.node = node;
        this.name = name;
    }

    public function isGlobal(): Bool {
        return true;
    }

    public function getHash(builder: Dynamic): String {
        return this.name != null ? this.name : super.getHash(builder);
    }

    public function getNodeType(builder: Dynamic): Dynamic {
        return this.node.getNodeType(builder);
    }

    public function setupVarying(builder: Dynamic): Dynamic {
        var properties = builder.getNodeProperties(this);

        var varying = Reflect.field(properties, "varying");

        if (varying == null) {
            var type = this.getNodeType(builder);

            varying = builder.getVaryingFromNode(this, this.name, type);
            Reflect.setField(properties, "varying", varying);
            Reflect.setField(properties, "node", this.node);
        }

        if (!Reflect.hasField(varying, "needsInterpolation")) {
            Reflect.setField(varying, "needsInterpolation", builder.shaderStage == 'fragment');
        }

        return varying;
    }

    public function setup(builder: Dynamic): Void {
        this.setupVarying(builder);
    }

    public function generate(builder: Dynamic): String {
        var type = this.getNodeType(builder);
        var varying = this.setupVarying(builder);

        var propertyName = builder.getPropertyName(varying, NodeShaderStage.VERTEX);

        builder.flowNodeFromShaderStage(NodeShaderStage.VERTEX, this.node, type, propertyName);

        return builder.getPropertyName(varying);
    }
}

// Since Haxe does not have a direct equivalent for JavaScript's export statement,
// we assume that the VaryingNode class is exported as a module.
export VaryingNode;

// Since we don't have the implementation of nodeProxy and addNodeElement functions,
// we are assuming their existence and usage.
var varying = ShaderNode.nodeProxy(VaryingNode);
ShaderNode.addNodeElement('varying', varying);

Node.addNodeClass('VaryingNode', VaryingNode);