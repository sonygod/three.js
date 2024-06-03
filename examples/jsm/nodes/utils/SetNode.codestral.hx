import Node from '../core/Node.hx';
import TempNode from '../core/TempNode.hx';
import Constants from '../core/constants.hx';

class SetNode extends TempNode {
    public var sourceNode: Node;
    public var components: Array<String>;
    public var targetNode: Node;

    public function new(sourceNode: Node, components: Array<String>, targetNode: Node) {
        super();

        this.sourceNode = sourceNode;
        this.components = components;
        this.targetNode = targetNode;
    }

    public function getNodeType(builder: Builder): String {
        return this.sourceNode.getNodeType(builder);
    }

    public function generate(builder: Builder): String {
        var sourceType: String = this.getNodeType(builder);
        var targetType: String = builder.getTypeFromLength(this.components.length);

        var targetSnippet: String = this.targetNode.build(builder, targetType);
        var sourceSnippet: String = this.sourceNode.build(builder, sourceType);

        var length: Int = builder.getTypeLength(sourceType);
        var snippetValues: Array<String> = [];

        for (i in 0...length) {
            var component: String = Constants.vectorComponents[i];

            if (component == this.components[0]) {
                snippetValues.push(targetSnippet);
                i += this.components.length - 1;
            } else {
                snippetValues.push(sourceSnippet + '.' + component);
            }
        }

        return builder.getType(sourceType) + '(' + snippetValues.join(', ') + ')';
    }
}

Node.addNodeClass("SetNode", SetNode);