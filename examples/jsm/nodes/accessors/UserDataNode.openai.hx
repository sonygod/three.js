package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class UserDataNode extends ReferenceNode {
    
    public var userData:Dynamic;

    public function new(property:String, inputType:String, userData:Dynamic = null) {
        super(property, inputType, userData);
        this.userData = userData;
    }

    override public function update(frame:Dynamic) {
        this.reference = (userData != null) ? userData : frame.object.userData;
        super.update(frame);
    }
}

extern class Node {
    static function addNodeClass(className:String, nodeClass:Class<Dynamic>):Void;
}

extern class ShaderNode {
    static function nodeObject(node:Dynamic):Dynamic;
}

// Export the UserDataNode class
@:nativeGen
class UserDataNodeExport {
    static public function userData(name:String, inputType:String, userData:Dynamic):Dynamic {
        return ShaderNode.nodeObject(new UserDataNode(name, inputType, userData));
    }
}

// Register the node class
Node.addNodeClass("UserDataNode", UserDataNode);