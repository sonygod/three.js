// Three.js Transpiler
// https://github.com/AcademySoftwareFoundation/MaterialX/blob/main/libraries/stdlib/genglsl/lib/mx_transform_color.glsl

import three.js.examples.jsm.nodes.materialx.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.materialx.math.OperatorNode;
import three.js.examples.jsm.nodes.materialx.math.MathNode;

class MxSrgbTextureToLinRec709 extends ShaderNode {

    public static function mx_srgb_texture_to_lin_rec709(color_immutable:Array<Float>):Array<Float> {

        var color = new vec3(color_immutable);
        var isAbove = new bvec3(OperatorNode.greaterThan(color, new vec3(0.04045)));
        var linSeg = new vec3(color.div(12.92));
        var powSeg = new vec3(MathNode.pow(MathNode.max(color.add(new vec3(0.055)), new vec3(0.0)), new vec3(2.4)));

        return MathNode.mix(linSeg, powSeg, isAbove);

    }

    // layouts

    public static function setLayout():Void {
        var layout = {
            name: 'mx_srgb_texture_to_lin_rec709',
            type: 'vec3',
            inputs: [
                { name: 'color', type: 'vec3' }
            ]
        };
        // Set layout here
    }

}