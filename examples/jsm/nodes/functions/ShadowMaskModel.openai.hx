package three.js.nodes.functions;

import three.js.core.LightingModel;
import three.js.core.PropertyNode;
import three.js.shader.ShaderNode;

class ShadowMaskModel extends LightingModel {

    public var shadowNode:ShaderNode;

    public function new() {
        super();
        shadowNode = ShaderNode.float(1).toVar('shadowMask');
    }

    public function direct(shadowMask:Float) {
        shadowNode.mulAssign(shadowMask);
    }

    public function finish(context:Dynamic) {
       (PropertyNode.diffuseColor.a).mulAssign(1 - shadowNode.getValue());
        context.outgoingLight.rgb.assign(PropertyNode.diffuseColor.rgb); // TODO: Optimize LightsNode to avoid this assignment
    }
}