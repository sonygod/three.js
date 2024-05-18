package three.js.examples.jsm.nodes.functions;

import three.js.core.LightingModel;
import three.js.nodes.bsdf.BRDF_Lambert;
import three.js.core.PropertyNode;
import three.js.accessors.NormalNode;
import three.js.shadernode.ShaderNode;
import three.js.math.MathNode;
import three.js.accessors.MaterialReferenceNode;

class ToonLightingModel extends LightingModel {

    static var getGradientIrradiance:ShaderNode = ShaderNode.tslFn(function(params:{normal:Vec3, lightDirection:Vec3, builder:Dynamic}) {
        var dotNL:Float = params.normal.dot(params.lightDirection);
        var coord:Vec2 = new Vec2(dotNL * 0.5 + 0.5, 0.0);

        if (params.builder.material.gradientMap != null) {
            var gradientMap:Texture = MaterialReferenceNode.materialReference('gradientMap', 'texture').context({ getUV: function() return coord });
            return new Vec3(gradientMap.r);
        } else {
            var fw:Float = coord.fwidth() * 0.5;
            return MathNode.mix(new Vec3(0.7), new Vec3(1.0), MathNode.smoothstep(0.7 - fw, 0.7 + fw, coord.x));
        }
    });

    public function new() {}

    override public function direct(params:{lightDirection:Vec3, lightColor:Vec3, reflectedLight:Dynamic}, stack:Array<Dynamic>, builder:Dynamic) {
        var irradiance:Vec3 = getGradientIrradiance({ normal: NormalNode.normalGeometry, lightDirection: params.lightDirection, builder: builder }).mul(params.lightColor);
        reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert.diffuseColor(PropertyNode.diffuseColor.rgb)));
    }

    override public function indirectDiffuse(params:{irradiance:Vec3, reflectedLight:Dynamic}) {
        reflectedLight.indirectDiffuse.addAssign(params.irradiance.mul(BRDF_Lambert.diffuseColor(PropertyNode.diffuseColor)));
    }
}