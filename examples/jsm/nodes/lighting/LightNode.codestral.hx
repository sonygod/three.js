import Node from '../core/Node';
import addNodeClass from '../core/Node';
import nodeProxy from '../shadernode/ShaderNode';
import objectPosition from '../accessors/Object3DNode';
import cameraViewMatrix from '../accessors/CameraNode';

class LightNode extends Node {

    public var scope:String;
    public var light:Dynamic;

    public function new(scope:String = LightNode.TARGET_DIRECTION, light:Dynamic = null) {
        super();
        this.scope = scope;
        this.light = light;
    }

    public function setup():Dynamic {
        var output:Dynamic = null;
        if (this.scope === LightNode.TARGET_DIRECTION) {
            output = cameraViewMatrix.transformDirection(objectPosition(this.light).sub(objectPosition(this.light.target)));
        }
        return output;
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.scope = this.scope;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.scope = data.scope;
    }

}

class LightNodeExports {
    static public var TARGET_DIRECTION:String = 'targetDirection';
    static public function lightTargetDirection(scope:String, light:Dynamic):Dynamic {
        return nodeProxy(new LightNode(scope, light), LightNodeExports.TARGET_DIRECTION);
    }
}

addNodeClass('LightNode', LightNode);