import Node;
import NodeClass;
import VaryingNode;
import ShaderNode;

class IndexNode extends Node {

    public var scope:String;
    public var isInstanceIndexNode:Bool = true;

    public function new(scope:String) {
        super('uint');
        this.scope = scope;
    }

    public function generate(builder:Builder):String {
        var nodeType:String = this.getNodeType(builder);
        var propertyName:String;

        if (this.scope == IndexNode.VERTEX) {
            propertyName = builder.getVertexIndex();
        } else if (this.scope == IndexNode.INSTANCE) {
            propertyName = builder.getInstanceIndex();
        } else {
            throw new Error('IndexNode: Unknown scope: ' + this.scope);
        }

        var output:String;

        if (builder.shaderStage == 'vertex' || builder.shaderStage == 'compute') {
            output = propertyName;
        } else {
            var nodeVarying = new VaryingNode(this);
            output = nodeVarying.build(builder, nodeType);
        }

        return output;
    }
}

static public var VERTEX:String = 'vertex';
static public var INSTANCE:String = 'instance';

static function vertexIndex(scope:String):Node {
    return ShaderNode.nodeImmutable(IndexNode, scope);
}

static function instanceIndex(scope:String):Node {
    return ShaderNode.nodeImmutable(IndexNode, scope);
}

NodeClass.addNodeClass('IndexNode', IndexNode);