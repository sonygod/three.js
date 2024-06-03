import ReferenceNode from './ReferenceNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { nodeObject } from '../shadernode/ShaderNode.hx';

class UserDataNode extends ReferenceNode {

    public var userData:Dynamic;

    public function new(property:String, inputType:String, userData:Dynamic = null) {
        super(property, inputType, userData);
        this.userData = userData;
    }

    public function update(frame:Dynamic) {
        this.reference = (this.userData != null) ? this.userData : frame.object.userData;
        super.update(frame);
    }
}

class UserData {
    public static function call(name:String, inputType:String, userData:Dynamic):Dynamic {
        return nodeObject(new UserDataNode(name, inputType, userData));
    }
}

addNodeClass("UserDataNode", UserDataNode);