import LightingModel from '../core/LightingModel';
import BRDF_Lambert from './BSDF/BRDF_Lambert';
import { diffuseColor } from '../core/PropertyNode';
import { normalGeometry } from '../accessors/NormalNode';
import { tslFn, float, vec2, vec3 } from '../shadernode/ShaderNode';
import { mix, smoothstep } from '../math/MathNode';
import { materialReference } from '../accessors/MaterialReferenceNode';

class GradientIrradiance {
    public function new() {}

    public static function call(normal: vec3, lightDirection: vec3, builder: Dynamic) {
        var dotNL = normal.dot(lightDirection);
        var coord = vec2(dotNL * 0.5 + 0.5, 0.0);

        if (builder.material.gradientMap != null) {
            var gradientMap = materialReference('gradientMap', 'texture').context({
                getUV: () => coord
            });

            return vec3(gradientMap.r);
        } else {
            var fw = coord.fwidth() * 0.5;

            return mix(vec3(0.7), vec3(1.0), smoothstep(0.7 - fw.x, 0.7 + fw.x, coord.x));
        }
    }
}

class ToonLightingModel extends LightingModel {
    public function direct(params: Dynamic, stack: Dynamic, builder: Dynamic) {
        var irradiance = GradientIrradiance.call(normalGeometry, params.lightDirection, builder).mul(params.lightColor);

        params.reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert({ diffuseColor: diffuseColor.rgb })));
    }

    public function indirectDiffuse(params: Dynamic) {
        params.reflectedLight.indirectDiffuse.addAssign(params.irradiance.mul(BRDF_Lambert({ diffuseColor })));
    }
}