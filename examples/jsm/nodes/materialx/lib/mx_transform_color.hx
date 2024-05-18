package three.js.examples.jm.nodes.materialx.lib;

import three.js.shadernode.ShaderNode;
import three.js.math.OperatorNode;
import three.js.math.MathNode;

class MXTransformColor {
    static var mx_srgb_texture_to_lin_rec709 = new ShaderNode(
        function(color_immutable:Array<Float>) {
            var color = new vec3(color_immutable);
            var isAbove = new bvec3(greaterThan(color, new vec3(0.04045)));
            var linSeg = new vec3(color.div(12.92));
            var powSeg = new vec3(pow(max(color.add(new vec3(0.055)), new vec3(0.0)).div(1.055), new vec3(2.4)));
            return mix(linSeg, powSeg, isAbove);
        }
    );

    public static function main() {
        mx_srgb_texture_to_lin_rec709.setLayout({
            name: 'mx_srgb_texture_to_lin_rec709',
            type: 'vec3',
            inputs: [
                { name: 'color', type: 'vec3' }
            ]
        });
    }
}