package three.js.examples.jsm.nodes.accessors;

import three.js.examples.jsm.nodes.ReferenceNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class UserDataNode extends ReferenceNode {

    public var userData:Dynamic;

    public function new(property:String, inputType:Dynamic, userData:Dynamic = null) {
        super(property, inputType, userData);
        this.userData = userData;
    }

    override public function update(frame:Dynamic) {
        this.reference = (userData != null) ? userData : frame.object.userData;
        super.update(frame);
    }

}

private function userData(name:String, inputType:Dynamic, userData:Dynamic) {
    return ShaderNode.nodeObject(new UserDataNode(name, inputType, userData));
}

Node.addNodeClass('UserDataNode', UserDataNode);