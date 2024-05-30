package three.js.examples.jvm.nodes.core;

import three.js.examples.jvm.nodes.core.Node;
import three.js.examples.jvm.nodes.core.TempNode;
import three.js.examples.jvm.shadernode.ShaderNode;
import three.js.examples.jvm.core.Constants;

class AssignNode extends TempNode {
    public var targetNode:Node;
    public var sourceNode:Node;

    public function new(targetNode:Node, sourceNode:Node) {
        super();
        this.targetNode = targetNode;
        this.sourceNode = sourceNode;
    }

    override public function hasDependencies():Bool {
        return false;
    }

    override public function getNodeType(builder:Dynamic, output:String):String {
        return output != 'void' ? targetNode.getNodeType(builder) : 'void';
    }

    public function needsSplitAssign(builder:Dynamic):Bool {
        if (!builder.isAvailable('swizzleAssign') && targetNode.isSplitNode && targetNode.components.length > 1) {
            var targetLength = builder.getTypeLength(targetNode.getNodeType(builder));
            var assignDifferentVector = Constants.VECTOR_COMPONENTS.join('').slice(0, targetLength) != targetNode.components;
            return assignDifferentVector;
        }
        return false;
    }

    override public function generate(builder:Dynamic, output:String):String {
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

            var targetRoot = targetNode.context({ assign: true }).build(builder);

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

typedef AssignNodeDef = AssignNode;

@:build(three.js.examples.jvm.shadernode.ShaderNode.nodeProxy(AssignNode))
class AssignNodeProxy {}

@:build(three.js.examples.jvm.nodes.core.addNodeClass('AssignNode', AssignNode))
class AssignNodeClass {}

@:build(three.js.examples.jvm.shadernode.addNodeElement('assign', AssignNodeProxy))
class AssignNodeElement {}