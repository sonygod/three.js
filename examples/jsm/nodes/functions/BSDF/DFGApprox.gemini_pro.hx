import shadernode.ShaderNode;

class DFGApprox extends ShaderNode.TSLFn {

	public function new() {
		super(function({ roughness, dotNV }: { roughness: ShaderNode.Float; dotNV: ShaderNode.Vec3 }) {

			var c0 = ShaderNode.Vec4.fromValues(-1, -0.0275, -0.572, 0.022);

			var c1 = ShaderNode.Vec4.fromValues(1, 0.0425, 1.04, -0.04);

			var r = roughness.mul(c0).add(c1);

			var a004 = r.x.mul(r.x).min(dotNV.mul(-9.28).exp2()).mul(r.x).add(r.y);

			var fab = ShaderNode.Vec2.fromValues(-1.04, 1.04).mul(a004).add(r.zw);

			return fab;

		});
		this.setLayout({
			name: "DFGApprox",
			type: "vec2",
			inputs: [
				{ name: "roughness", type: "float" },
				{ name: "dotNV", type: "vec3" }
			]
		});
	}
}

class DFGApprox {
	static public var DFGApprox:DFGApprox = new DFGApprox();
}