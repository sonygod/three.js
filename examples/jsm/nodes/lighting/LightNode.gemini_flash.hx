import Node from '../core/Node.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';
import Object3DNode from '../accessors/Object3DNode.hx';
import CameraNode from '../accessors/CameraNode.hx';

class LightNode extends Node {
    public var scope:String;
    public var light:Dynamic;

    public function new(scope:String = LightNode.TARGET_DIRECTION, light:Dynamic = null) {
        super();
        this.scope = scope;
        this.light = light;
    }

    public function setup():Dynamic {
        var scope = this.scope;
        var light = this.light;

        var output:Dynamic = null;

        if (scope == LightNode.TARGET_DIRECTION) {
            output = cameraViewMatrix.transformDirection(objectPosition(light).sub(objectPosition(light.target)));
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

LightNode.TARGET_DIRECTION = 'targetDirection';

class LightNodeProxy extends ShaderNode {
    public static function create(scope:String, light:Dynamic):LightNodeProxy {
        var node = new LightNodeProxy();
        node.scope = scope;
        node.light = light;
        return node;
    }
}

var lightTargetDirection = LightNodeProxy.create(LightNode.TARGET_DIRECTION, null);

addNodeClass('LightNode', LightNode);