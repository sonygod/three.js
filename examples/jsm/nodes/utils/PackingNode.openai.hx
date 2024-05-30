package three.js.examples.jsm.nodes.utils;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class PackingNode extends TempNode {
    public var scope:String;
    public var node:Node;

    public function new(scope:String, node:Node) {
        super();
        this.scope = scope;
        this.node = node;
    }

    public function getNodeType(builder:Dynamic):String {
        return node.getNodeType(builder);
    }

    public function setup():Node {
        var result:Node = null;
        if (scope == PackingNode.DIRECTION_TO_COLOR) {
            result = node.mul(0.5).add(0.5);
        } else if (scope == PackingNode.COLOR_TO_DIRECTION) {
            result = node.mul(2.0).sub(1);
        }
        return result;
    }
}

class PackingNode {
    public static inline var DIRECTION_TO_COLOR:String = 'directionToColor';
    public static inline var COLOR_TO_DIRECTION:String = 'colorToDirection';
}

class NodeProxy {
    public static function proxy<T>(nodeClass:Class<T>, scope:String):T {
        return Type.createInstance(nodeClass, [scope, null]);
    }
}

// Register nodes
NodeProxy.proxy(PackingNode, PackingNode.DIRECTION_TO_COLOR);
NodeProxy.proxy(PackingNode, PackingNode.COLOR_TO_DIRECTION);
Node.registerElement('directionToColor', NodeProxy.proxy(PackingNode, PackingNode.DIRECTION_TO_COLOR));
Node.registerElement('colorToDirection', NodeProxy.proxy(PackingNode, PackingNode.COLOR_TO_DIRECTION));
Node.registerClass('PackingNode', PackingNode);