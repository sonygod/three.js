import Node.addNodeClass;
import ShaderNode.nodeObject;
import PropertyNode;

class ParameterNode extends PropertyNode {

    public var isParameterNode:Bool = true;

    public function new(nodeType:String, name:String = null) {
        super(nodeType, name);
    }

    public function getHash():String {
        return this.uuid;
    }

    public function generate():String {
        return this.name;
    }

}

export default ParameterNode;

export function parameter(type:String, name:String):ShaderNode {
    return nodeObject(new ParameterNode(type, name));
}

addNodeClass('ParameterNode', ParameterNode);