package three.js.examples.jsm.nodes.core;

import Node;
import VaryingNode;
import ShaderNode;

class IndexNode extends Node {

    public var scope:String;

    public var isInstanceIndexNode:Bool = true;

    public function new(scope:String) {
        super('uint');
        this.scope = scope;
    }

    public function generate(builder:Dynamic):Dynamic {
        var nodeType = getNodeType(builder);
        var scope = this.scope;

        var propertyName:String;

        if (scope == IndexNode.VERTEX) {
            propertyName = builder.getVertexIndex();
        } else if (scope == IndexNode.INSTANCE) {
            propertyName = builder.getInstanceIndex();
        } else {
            throw new Error('THREE.IndexNode: Unknown scope: $scope');
        }

        var output:Dynamic;

        if (builder.shaderStage == 'vertex' || builder.shaderStage == 'compute') {
            output = propertyName;
        } else {
            var nodeVarying = VaryingNode.varying(this);
            output = nodeVarying.build(builder, nodeType);
        }

        return output;
    }

    public static inline var VERTEX:String = 'vertex';
    public static inline var INSTANCE:String = 'instance';

}

private static function nodeImmutable(nodeInstance:IndexNode, scope:String):IndexNode {
    return new IndexNode(scope);
}

private static var _vertexIndex:IndexNode = nodeImmutable(new IndexNode(IndexNode.VERTEX));
private static var _instanceIndex:IndexNode = nodeImmutable(new IndexNode(IndexNode.INSTANCE));

Node.addNodeClass('IndexNode', IndexNode);

// exports
import Export.Expose('IndexNode', IndexNode);
import Export.Expose('_vertexIndex', _vertexIndex);
import Export.Expose('_instanceIndex', _instanceIndex);