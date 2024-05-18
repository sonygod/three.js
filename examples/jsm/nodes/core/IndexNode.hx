Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.js.examples.jm.nodes.core;

import Node;
import VaryingNode;
import ShaderNode;

class IndexNode extends Node {

    public var scope:String;

    public var isInstanceIndexNode:Bool;

    public function new(scope:String) {
        super('uint');
        this.scope = scope;
        this.isInstanceIndexNode = true;
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
            throw new Error('THREE.IndexNode: Unknown scope: ' + scope);
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

typedef IndexNodeDef = {
    scope:String,
    isInstanceIndexNode:Bool
}

class IndexNodeBuilder {
    public static function vertexIndex():IndexNode {
        return nodeImmutable(new IndexNode(IndexNode.VERTEX));
    }

    public static function instanceIndex():IndexNode {
        return nodeImmutable(new IndexNode(IndexNode.INSTANCE));
    }
}
```
Note that I've used the Haxe `typedef` keyword to define the `IndexNodeDef` type, which is equivalent to the JavaScript object literal. I've also created a separate `IndexNodeBuilder` class to encapsulate the `vertexIndex` and `instanceIndex` functions, which are equivalent to the exported JavaScript variables.

Also, I've assumed that the `Builder` class is defined elsewhere in the codebase, and that it has methods like `getVertexIndex()` and `getInstanceIndex()`. If this is not the case, please let me know and I can adjust the code accordingly.