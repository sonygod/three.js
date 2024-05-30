package three.js.examples.jvm.nodes.functions;

import three.js.core.LightingModel;
import three.js.nodes.BSDF.BRDF_Lambert;
import three.js.core.PropertyNode;
import three.js.accessors.NormalNode;
import three.js.shader.ShaderNode;
import three.js.math.MathNode;
import three.js.accessors.MaterialReferenceNode;

class ToonLightingModel extends LightingModel {
    public function new() {
        super();
    }

    private static var getGradientIrradiance = ShaderNode.tslFn(({n, ld, bldr}) -> {
        var dotNL = n.dot(ld);
        var coord = new Vec2(dotNL * 0.5 + 0.5, 0.0);
        if (bldr.material.gradientMap != null) {
            var gradientMap = MaterialReferenceNode.materialReference('gradientMap', 'texture').context({getUV: () -> coord});
            return new Vec3(gradientMap.r);
        } else {
            var fw = coord.fwidth() * 0.5;
            return MathNode.mix(new Vec3(0.7), new Vec3(1.0), MathNode.smoothstep(0.7 - fw.x, 0.7 + fw.x, coord.x));
        }
    });

    override public function direct(args:{lightDirection:Vec3, lightColor:Vec3, reflectedLight:Dynamic}, stack:Array<Dynamic>, builder:Dynamic) {
        var irradiance = getGradientIrradiance({normal: NormalNode.normalGeometry, lightDirection: args.lightDirection, builder: builder}).mul(args.lightColor);
        args.reflectedLight.directDiffuse.addAssign(irradiance.mul(BRDF_Lambert.diffuseColor(rgb: PropertyNode.diffuseColor.rgb)));
    }

    override public function indirectDiffuse(args:{irradiance:Vec3, reflectedLight:Dynamic}) {
        args.reflectedLight.indirectDiffuse.addAssign(args.irradiance.mul(BRDF_Lambert.diffuseColor(PropertyNode.diffuseColor)));
    }
}