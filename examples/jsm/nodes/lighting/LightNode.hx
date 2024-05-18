package three.js.examples.javascript.nodes.lighting;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.accessors.Object3DNode;
import three.js.accessors.CameraNode;

class LightNode extends Node {
    public static inline var TARGET_DIRECTION:String = 'targetDirection';

    public var scope:String;
    public var light:Dynamic;

    public function new(?scope:String = TARGET_DIRECTION, ?light:Dynamic) {
        super();
        this.scope = scope;
        this.light = light;
    }

    public function setup():Null<Float> {
        var scope:String = this.scope;
        var light:Dynamic = this.light;

        var output:Null<Float> = null;

        if (scope == TARGET_DIRECTION) {
            output = cameraViewMatrix.transformDirection(objectPosition(light).sub(objectPosition(light.target)));
        }

        return output;
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);
        data.scope = this.scope;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);
        this.scope = data.scope;
    }
}

class LightNodeProxy extends ShaderNode {
    public function new() {
        super(LightNode, LightNode.TARGET_DIRECTION);
    }
}

Node.addNodeClass('LightNode', LightNode);