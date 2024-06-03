import InputNode;
import UniformGroupNode.objectGroup;
import Node.addNodeClass;
import ShaderNode.nodeObject;
import ShaderNode.getConstNodeType;

class UniformNode extends InputNode {

    public var groupNode:ObjectGroup;

    public function new(value:Dynamic, ?nodeType:NodeType) {
        super(value, nodeType);

        this.isUniformNode = true;

        this.groupNode = objectGroup;
    }

    public function setGroup(group:ObjectGroup):UniformNode {
        this.groupNode = group;

        return this;
    }

    public function getGroup():ObjectGroup {
        return this.groupNode;
    }

    public function getUniformHash(builder:Builder):String {
        return this.getHash(builder);
    }

    public function onUpdate(callback:Dynamic->Dynamic, updateType:String):InputNode {
        var self = this.getSelf();

        callback = callback.bind(self);

        return super.onUpdate(function(frame:Int) {
            var value = callback(frame, self);

            if (value != null) {
                this.value = value;
            }
        }, updateType);
    }

    public function generate(builder:Builder, output:String):String {
        var type = this.getNodeType(builder);

        var hash = this.getUniformHash(builder);

        var sharedNode = builder.getNodeFromHash(hash);

        if (sharedNode == null) {
            builder.setHashNode(this, hash);

            sharedNode = this;
        }

        var sharedNodeType = sharedNode.getInputType(builder);

        var nodeUniform = builder.getUniformFromNode(sharedNode, sharedNodeType, builder.shaderStage, builder.context.label);
        var propertyName = builder.getPropertyName(nodeUniform);

        if (builder.context.label != null) delete builder.context.label;

        return builder.format(propertyName, type, output);
    }
}

function uniform(arg1:Dynamic, arg2:Dynamic):NodeObject {
    var nodeType = getConstNodeType(arg2 || arg1);

    var value = (arg1 is Node && arg1.isNode) ? ((arg1.node && arg1.node.value) || arg1.value) : arg1;

    return nodeObject(new UniformNode(value, nodeType));
}

addNodeClass("UniformNode", UniformNode);