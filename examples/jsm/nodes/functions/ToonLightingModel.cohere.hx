import LightingModel from '../core/LightingModel.hx';
import BRDF_Lambert from './BSDF/BRDF_Lambert.hx';

import { $property } from '../core/PropertyNode.hx';
import { $normal } from '../accessors/NormalNode.hx';
import { ShaderNode, ShaderNodeUtils } from '../shadernode/ShaderNode.hx';
import { MathNode } from '../math/MathNode.hx';
import { $materialReference } from '../accessors/MaterialReferenceNode.hx';

class ToonLightingModel extends LightingModel {
    public function direct({ lightDirection, lightColor, reflectedLight }:LightingModel.DirectParams, stack:ShaderNode.Stack, builder:ShaderNode.Builder) {
        var irradiance = getGradientIrradiance({ normal: $normal('geometry'), lightDirection: lightDirection, builder: builder }).mul(lightColor);
        reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert({ diffuseColor: $property('diffuseColor').rgb })));
    }

    public function indirectDiffuse({ irradiance, reflectedLight }:LightingModel.IndirectDiffuseParams) {
        reflectedLight.indirectDiffuse.addAssign(irradiance.mul(BRDF_Lambert({ diffuseColor: $property('diffuseColor') })));
    }

    inline function getGradientIrradiance({ normal, lightDirection, builder }:ShaderNode.Builder) : ShaderNode.Expression {
        var dotNL = normal.dot(lightDirection);
        var coord = ShaderNodeUtils.vec2(dotNL.mul(0.5).add(0.5), 0.0);

        if (builder.material.gradientMap != null) {
            var gradientMap = $materialReference('gradientMap', 'texture').context({ getUV: function() { return coord; } });
            return ShaderNodeUtils.vec3(gradientMap.r);
        } else {
            var fw = coord.fwidth().mul(0.5);
            return ShaderNodeUtils.mix(ShaderNodeUtils.vec3(0.7), ShaderNodeUtils.vec3(1.0), MathNode.smoothstep(0.7 - fw.x, 0.7 + fw.x, coord.x));
        }
    }
}

export default ToonLightingModel;