package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.nodes.InputNode;
import three.js.examples.jsm.nodes.UniformGroupNode.objectGroup;
import three.js.examples.jsm.nodes.ShaderNode;
import three.js.examples.jsm.nodes.Node;

class UniformNode extends InputNode {
    public var isUniformNode:Bool = true;
    public var groupNode:Dynamic = objectGroup;

    public function new(value:Dynamic, nodeType:Null<Dynamic> = null) {
        super(value, nodeType);
    }

    public function setGroup(group:Dynamic):UniformNode {
        groupNode = group;
        return this;
    }

    public function getGroup():Dynamic {
        return groupNode;
    }

    public function getUniformHash(builder:Dynamic):String {
        return getHash(builder);
    }

    public function onUpdate(callback:Dynamic->Void, updateType:Dynamic):Void {
        var self:UniformNode = getSelf();
        callback = callback.bind(self);
        super.onUpdate(function(frame:Dynamic):Void {
            var value:Dynamic = callback(frame, self);
            if (value != null) {
                this.value = value;
            }
        }, updateType);
    }

    public function generate(builder:Dynamic, output:Dynamic):String {
        var type:Dynamic = getNodeType(builder);
        var hash:String = getUniformHash(builder);
        var sharedNode:Dynamic = builder.getNodeFromHash(hash);
        if (sharedNode == null) {
            builder.setHashNode(this, hash);
            sharedNode = this;
        }
        var sharedNodeType:Dynamic = sharedNode.getInputType(builder);
        var nodeUniform:Dynamic = builder.getUniformFromNode(sharedNode, sharedNodeType, builder.shaderStage, builder.context.label);
        var propertyName:String = builder.getPropertyName(nodeUniform);
        if (builder.context.label != null) builder.context.label = null;
        return builder.format(propertyName, type, output);
    }
}

extern class UniformNode {
    static public function uniform(arg1:Dynamic, arg2:Dynamic = null):UniformNode {
        var nodeType:Dynamic = getConstNodeType(arg2 != null ? arg2 : arg1);
        var value:Dynamic = (arg1 != null && arg1.isNode) ? ((arg1.node != null) ? arg1.node.value : arg1.value) : arg1;
        return new UniformNode(value, nodeType);
    }
}

Node.addNodeClass('UniformNode', UniformNode);