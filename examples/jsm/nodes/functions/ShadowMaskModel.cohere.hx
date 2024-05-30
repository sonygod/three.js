import LightingModel from '../core/LightingModel.hx';
import { diffuseColor } from '../core/PropertyNode.hx';
import { FloatNode } from '../shadernode/ShaderNode.hx';

class ShadowMaskModel extends LightingModel {
    public var shadowNode:FloatNode;

    public function new() {
        super();
        shadowNode = FloatNode.create(1).toVar("shadowMask");
    }

    public function direct({ shadowMask }:Dynamic) {
        shadowNode.mulAssign(shadowMask);
    }

    public function finish(context:Dynamic) {
        diffuseColor.a.mulAssign(shadowNode.oneMinus());
        context.outgoingLight.rgb.assign(diffuseColor.rgb);
    }
}

class Export {
    public static function main() {
        return ShadowMaskModel;
    }
}