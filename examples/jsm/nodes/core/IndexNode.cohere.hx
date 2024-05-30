import Node from './Node.hx';
import { varying } from './VaryingNode.hx';
import { nodeImmutable } from '../shadernode/ShaderNode.hx';

class IndexNode extends Node {
    public scope:Int;
    public isInstanceIndexNode:Bool;

    public function new(scope:Int) {
        super('uint');
        this.scope = scope;
        this.isInstanceIndexNode = true;
    }

    public function generate(builder:Dynamic) : String {
        var nodeType = this.getNodeType(builder);
        var propertyName:String;

        if (scope == IndexNode.VERTEX) {
            propertyName = builder.getVertexIndex();
        } else if (scope == IndexNode.INSTANCE) {
            propertyName = builder.getInstanceIndex();
        } else {
            throw haxe.Exception.thrown("IndexNode: Unknown scope: " + scope);
        }

        var output:String;

        if (builder.shaderStage == 'vertex' || builder.shaderStage == 'compute') {
            output = propertyName;
        } else {
            var nodeVarying = varying(this);
            output = nodeVarying.build(builder, nodeType);
        }

        return output;
    }

    public static var VERTEX:Int = 0;
    public static var INSTANCE:Int = 1;
}

class IndexNode_pre {
    public static function vertexIndex(scope:Int) : IndexNode {
        return nodeImmutable(IndexNode, scope);
    }

    public static function instanceIndex() : IndexNode {
        return nodeImmutable(IndexNode, IndexNode.INSTANCE);
    }
}