package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.nodes.Node;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.PropertyNode;

class ParameterNode extends PropertyNode {
    public var isParameterNode:Bool = true;

    public function new(nodeType:String, ?name:String) {
        super(nodeType, name);
    }

    public function getHash():String {
        return uuid;
    }

    public function generate():String {
        return name;
    }
}

class ParameterNodeBuilder {
    public static function parameter(type:String, name:String):ShaderNode {
        return nodeObject(new ParameterNode(type, name));
    }
}

Node.addNodeClass('ParameterNode', ParameterNode);