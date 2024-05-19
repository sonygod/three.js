package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.core.Node;
import three.js.examples.jsm.core.TempNode;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.core.constants;

class AssignNode extends TempNode {
    public var targetNode:Node;
    public var sourceNode:Node;

    public function new(targetNode:Node, sourceNode:Node) {
        super();
        this.targetNode = targetNode;
        this.sourceNode = sourceNode;
    }

    public function hasDependencies():Bool {
        return false;
    }

    public function getNodeType(builder:Dynamic, output:String):String {
        return if (output != 'void') targetNode.getNodeType(builder) else 'void';
    }

    public function needsSplitAssign(builder:Dynamic):Bool {
        var targetNode = this.targetNode;
        if (!builder.isAvailable('swizzleAssign') && targetNode.isSplitNode && targetNode.components.length > 1) {
            var targetLength = builder.getTypeLength(targetNode.getNodeType(builder));
            var assignDifferentVector = vectorComponents.join('').slice(0, targetLength) != targetNode.components;
            return assignDifferentVector;
        }
        return false;
    }

    public function generate(builder:Dynamic, output:String):String {
        var targetNode = this.targetNode;
        var sourceNode = this.sourceNode;

        var needsSplitAssign = this.needsSplitAssign(builder);

        var targetType = targetNode.getNodeType(builder);

        var target = targetNode.context({ assign: true }).build(builder);
        var source = sourceNode.build(builder, targetType);

        var sourceType = sourceNode.getNodeType(builder);

        var nodeData = builder.getDataFromNode(this);

        var snippet:String;

        if (nodeData.initialized) {
            if (output != 'void') {
                snippet = target;
            }
        } else if (needsSplitAssign) {
            var sourceVar = builder.getVarFromNode(this, null, targetType);
            var sourceProperty = builder.getPropertyName(sourceVar);

            builder.addLineFlowCode('${sourceProperty} = ${source}');

            var targetRoot = targetNode.node.context({ assign: true }).build(builder);

            for (i in 0...targetNode.components.length) {
                var component = targetNode.components[i];

                builder.addLineFlowCode('${targetRoot}.${component} = ${sourceProperty}[${i}]');
            }

            if (output != 'void') {
                snippet = target;
            }
        } else {
            snippet = '${target} = ${source}';

            if (output == 'void' || sourceType == 'void') {
                builder.addLineFlowCode(snippet);

                if (output != 'void') {
                    snippet = target;
                }
            }
        }

        nodeData.initialized = true;

        return builder.format(snippet, targetType, output);
    }
}

@:keep
@:expose
extern class AssignNode {
    static public function addNodeClass():Void {
        Node.addNodeClass('AssignNode', AssignNode);
    }

    static public function addNodeElement():Void {
        ShaderNode.addNodeElement('assign', ShaderNode.nodeProxy(AssignNode));
    }
}