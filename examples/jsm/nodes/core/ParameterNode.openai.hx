package three.js.nodes.core;

import three.js.nodes.Node;
import three.js.shadernode.ShaderNode;

class ParameterNode extends PropertyNode {

    public var isParameterNode:Bool = true;

    public function new(nodeType:String, ?name:String) {
        super(nodeType, name);
    }

    override public function getHash():String {
        return this.uuid;
    }

    override public function generate():String {
        return this.name;
    }

}

private function parameter(type:String, ?name:String):ShaderNode {
    return nodeObject(new ParameterNode(type, name));
}

Node.addNodeClass('ParameterNode', ParameterNode);