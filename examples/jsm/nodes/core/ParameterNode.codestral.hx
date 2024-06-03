import Node.addNodeClass;
import shadernode.ShaderNode.nodeObject;
import core.PropertyNode;

class ParameterNode extends PropertyNode {

    public function new(nodeType:Dynamic, name:String = null) {
        super(nodeType, name);
        this.isParameterNode = true;
    }

    public function getHash():String {
        return this.uuid;
    }

    public function generate():String {
        return this.name;
    }

}

var parameter = function(type:Dynamic, name:String):Dynamic {
    return nodeObject(new ParameterNode(type, name));
};

addNodeClass("ParameterNode", ParameterNode);