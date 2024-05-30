package three.js.nodes.fog;

import three.js.nodes.FogNode;
import three.js.math.MathNode;

class FogRangeNode extends FogNode {

    public var isFogRangeNode:Bool = true;

    public var nearNode:Dynamic;
    public var farNode:Dynamic;

    public function new(colorNode:Dynamic, nearNode:Dynamic, farNode:Dynamic) {
        super(colorNode);
        this.nearNode = nearNode;
        this.farNode = farNode;
    }

    public function setup(builder:Dynamic):Dynamic {
        var viewZ:Dynamic = getViewZNode(builder);
        return MathNode.smoothstep(nearNode, farNode, viewZ);
    }

}

// registering the node
@:native("rangeFog")
class RangeFogNodeProxy {}

// registering the node element
@:native("rangeFog")
extern class RangeFogNodeElement {}

@:native("addNodeElement")
extern function addNodeElement(name:String, node:Dynamic):Void;

@:native("addNodeClass")
extern function addNodeClass(name:String, nodeClass:Class<Dynamic>):Void;

addNodeElement('rangeFog', RangeFogNodeElement);
addNodeClass('FogRangeNode', FogRangeNode);