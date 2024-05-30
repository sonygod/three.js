// Haxe Transpiler
// https://github.com/AcademySoftwareFoundation/MaterialX/blob/main/libraries/stdlib/genglsl/lib/mx_transform_color.glsl

import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.math.OperatorNode;
import three.js.examples.jsm.nodes.math.MathNode;

class mx_srgb_texture_to_lin_rec709 extends ShaderNode {

	public function new() {
		super();
		this.name = 'mx_srgb_texture_to_lin_rec709';
		this.type = 'vec3';
		this.inputs = [
			{ name: 'color', type: 'vec3' }
		];
	}

	public function compute(color:Vec3) {
		var color_immutable = color;
		var color = color_immutable.toVar();
		var isAbove = OperatorNode.greaterThan(color, new Vec3(0.04045)).toVar();
		var linSeg = color.div(12.92).toVar();
		var powSeg = MathNode.pow(MathNode.max(color.add(new Vec3(0.055)), new Vec3(0.0)).div(1.055), new Vec3(2.4)).toVar();
		return MathNode.mix(linSeg, powSeg, isAbove);
	}
}

export { mx_srgb_texture_to_lin_rec709 };