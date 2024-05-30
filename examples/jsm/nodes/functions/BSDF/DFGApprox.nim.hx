import three.js.examples.jsm.nodes.shadernode.ShaderNode.tslFn;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.vec2;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.vec4;

// Analytical approximation of the DFG LUT, one half of the
// split-sum approximation used in indirect specular lighting.
// via 'environmentBRDF' from "Physically Based Shading on Mobile"
// https://www.unrealengine.com/blog/physically-based-shading-on-mobile
var DFGApprox = tslFn(function(data) {
	var roughness = data.roughness;
	var dotNV = data.dotNV;

	var c0 = vec4(-1, -0.0275, -0.572, 0.022);
	var c1 = vec4(1, 0.0425, 1.04, -0.04);

	var r = roughness.mul(c0).add(c1);

	var a004 = r.x.mul(r.x).min(dotNV.mul(-9.28).exp2()).mul(r.x).add(r.y);

	var fab = vec2(-1.04, 1.04).mul(a004).add(r.zw);

	return fab;
}).setLayout({
	name: 'DFGApprox',
	type: 'vec2',
	inputs: [
		{ name: 'roughness', type: 'float' },
		{ name: 'dotNV', type: 'vec3' }
	]
});

export default DFGApprox;