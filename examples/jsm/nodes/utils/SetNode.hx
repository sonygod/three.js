package three.js.examples.jsm.nodes.utils;

import three.core.Node;
import three.core.TempNode;
import three.core.Constants;

class SetNode extends TempNode {
    public var sourceNode:Node;
    public var components:Array<String>;
    public var targetNode:Node;

    public function new(sourceNode:Node, components:Array<String>, targetNode:Node) {
        super();
        this.sourceNode = sourceNode;
        this.components = components;
        this.targetNode = targetNode;
    }

    public function getNodeType(builder:Dynamic):String {
        return sourceNode.getNodeType(builder);
    }

    public function generate(builder:Dynamic):String {
        var sourceType:String = getNodeType(builder);
        var targetType:String = builder.getTypeFromLength(components.length);
        var targetSnippet:String = targetNode.build(builder, targetType);
        var sourceSnippet:String = sourceNode.build(builder, sourceType);
        var length:Int = builder.getTypeLength(sourceType);
        var snippetValues:Array<String> = [];

        for (i in 0...length) {
            var component:String = Constants.vectorComponents[i];

            if (component == components[0]) {
                snippetValues.push(targetSnippet);
                i += components.length - 1;
            } else {
                snippetValues.push(sourceSnippet + '.' + component);
            }
        }

        return '${builder.getType(sourceType)}(${snippetValues.join(", ")})';
    }
}

@:keep
class SetNodeMeta {
    public static function addNodeClass() {
        three.core.Node.addNodeClass('SetNode', SetNode);
    }
}

SetNodeMeta.addNodeClass();