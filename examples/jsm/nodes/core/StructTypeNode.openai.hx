package three.js.nodes.core;

import three.js.nodes.Node;

class StructTypeNode extends Node {
    public var types:Array<Dynamic>;
    public var isStructTypeNode:Bool = true;

    public function new(types:Array<Dynamic>) {
        super();
        this.types = types;
    }

    public function getMemberTypes():Array<Dynamic> {
        return types;
    }
}

Node.addNodeClass('StructTypeNode', StructTypeNode);