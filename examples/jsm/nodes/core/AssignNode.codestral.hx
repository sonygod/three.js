import js.Browser.document;
import three.nodes.core.Node;
import three.nodes.core.TempNode;
import three.nodes.shadernode.ShaderNode;
import three.nodes.core.constants;

class AssignNode extends TempNode {

    public var targetNode: Node;
    public var sourceNode: Node;

    public function new(targetNode: Node, sourceNode: Node) {
        super();
        this.targetNode = targetNode;
        this.sourceNode = sourceNode;
    }

    public function hasDependencies(): Bool {
        return false;
    }

    public function getNodeType(builder: Builder, output: String): String {
        return output != 'void' ? this.targetNode.getNodeType(builder) : 'void';
    }

    public function needsSplitAssign(builder: Builder): Bool {
        if(!builder.isAvailable('swizzleAssign') && this.targetNode.isSplitNode && this.targetNode.components.length > 1) {
            var targetLength: Int = builder.getTypeLength(this.targetNode.node.getNodeType(builder));
            var assignDifferentVector: Bool = constants.vectorComponents.join('').substring(0, targetLength) != this.targetNode.components;
            return assignDifferentVector;
        }
        return false;
    }

    public function generate(builder: Builder, output: String): String {
        var needsSplitAssign: Bool = this.needsSplitAssign(builder);
        var targetType: String = this.targetNode.getNodeType(builder);
        var target: String = this.targetNode.context({assign: true}).build(builder);
        var source: String = this.sourceNode.build(builder, targetType);
        var sourceType: String = this.sourceNode.getNodeType(builder);
        var nodeData = builder.getDataFromNode(this);

        var snippet: String;

        if(nodeData.initialized) {
            if(output != 'void') {
                snippet = target;
            }
        } else if(needsSplitAssign) {
            var sourceVar: String = builder.getVarFromNode(this, null, targetType);
            var sourceProperty: String = builder.getPropertyName(sourceVar);
            builder.addLineFlowCode("$sourceProperty = $source");

            var targetRoot: String = this.targetNode.node.context({assign: true}).build(builder);

            for(var i in 0...this.targetNode.components.length) {
                var component: String = this.targetNode.components[i];
                builder.addLineFlowCode("$targetRoot.$component = $sourceProperty[$i]");
            }

            if(output != 'void') {
                snippet = target;
            }
        } else {
            snippet = "$target = $source";

            if(output == 'void' || sourceType == 'void') {
                builder.addLineFlowCode(snippet);

                if(output != 'void') {
                    snippet = target;
                }
            }
        }

        nodeData.initialized = true;

        return builder.format(snippet, targetType, output);
    }
}

export function assign(targetNode: Node, sourceNode: Node): Node {
    return new AssignNode(targetNode, sourceNode);
}

Node.addNodeClass('AssignNode', AssignNode);
ShaderNode.addNodeElement('assign', assign);