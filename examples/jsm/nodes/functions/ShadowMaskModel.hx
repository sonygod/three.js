package three.js.examples.javascript.nodes.functions;

import three.js.core.LightingModel;
import three.js.core.PropertyNode.DiffuseColor;
import three.js.shadernode.ShaderNode.FloatNode;

class ShadowMaskModel extends LightingModel {

    public var shadowNode:FloatNode;

    public function new() {
        super();
        shadowNode = new FloatNode(1.0).toVar('shadowMask');
    }

    public function direct(shadowMask:Float) {
        shadowNode.mulAssign(shadowMask);
    }

    public function finish(context:Dynamic) {
        DiffuseColor.a.mulAssign(1.0 - shadowNode.getValue());
        context.outgoingLight.rgb.assign(DiffuseColor.rgb); // TODO: Optimize LightsNode to avoid this assignment
    }
}

typedef ShadowMaskModelDef = ShadowMaskModel;