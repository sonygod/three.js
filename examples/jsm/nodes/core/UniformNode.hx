package three.js.examples.jm.nodes.core;

import three.js.examples.jm.nodes.core.InputNode;
import three.js.examples.jm.nodes.core.UniformGroupNode;
import three.js.examples.jm.nodes.Node;
import three.js.examples.jm.shadernode.ShaderNode;

class UniformNode extends InputNode {

    public var isUniformNode:Bool = true;

    public var groupNode:UniformGroupNode;

    public function new(value:Dynamic, nodeType:Null<Int> = null) {
        super(value, nodeType);
        this.groupNode = UniformGroupNode.objectGroup;
    }

    public function setGroup(group:UniformGroupNode):UniformNode {
        this.groupNode = group;
        return this;
    }

    public function getGroup():UniformGroupNode {
        return this.groupNode;
    }

    public function getUniformHash(builder:Dynamic):String {
        return this.getHash(builder);
    }

    public function onUpdate(callback:Dynamic, updateType:Dynamic):Void {
        var self:UniformNode = this.getSelf();
        callback = Reflect.bind(callback, self);
        super.onUpdate(function(frame:Dynamic) {
            var value:Dynamic = callback(frame, self);
            if (value != null) {
                this.value = value;
            }
        }, updateType);
    }

    public function generate(builder:Dynamic, output:Dynamic):String {
        var type:Int = this.getNodeType(builder);
        var hash:String = this.getUniformHash(builder);
        var sharedNode:UniformNode = builder.getNodeFromHash(hash);
        if (sharedNode == null) {
            builder.setHashNode(this, hash);
            sharedNode = this;
        }
        var sharedNodeType:Int = sharedNode.getInputType(builder);
        var nodeUniform:Dynamic = builder.getUniformFromNode(sharedNode, sharedNodeType, builder.shaderStage, builder.context.label);
        var propertyName:String = builder.getPropertyName(nodeUniform);
        if (builder.context.label != null) delete builder.context.label;
        return builder.format(propertyName, type, output);
    }

    public static function uniform(arg1:Dynamic, ?arg2:Dynamic):UniformNode {
        var nodeType:Int = ShaderNode.getConstNodeType(arg2 != null ? arg2 : arg1);
        // @TODO: get ConstNode from .traverse() in the future
        var value:Dynamic = (arg1 != null && arg1.isNode == true) ? (arg1.node != null ? arg1.node.value : arg1.value) : arg1;
        return Node.nodeObject(new UniformNode(value, nodeType));
    }

}

Node.addNodeClass('UniformNode', UniformNode);