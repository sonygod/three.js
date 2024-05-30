import three.examples.jsm.nodes.accessors.NormalNode;
import three.examples.jsm.nodes.accessors.PositionNode;
import three.examples.jsm.nodes.core.PropertyNode;
import three.examples.jsm.nodes.shadernode.ShaderNode;

// https://github.com/google/filament/blob/master/shaders/src/brdf.fs
var D_Charlie = ShaderNode.tslFn(function(data) {
	var roughness = data.roughness;
	var dotNH = data.dotNH;

	var alpha = roughness.pow2();

	// Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
	var invAlpha = 1.0 / alpha;
	var cos2h = dotNH.pow2();
	var sin2h = cos2h.oneMinus().max(0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16

	return (2.0 + invAlpha) * sin2h.pow(invAlpha * 0.5) / (2.0 * Math.PI);
}).setLayout({
	name: 'D_Charlie',
	type: 'float',
	inputs: [
		{ name: 'roughness', type: 'float' },
		{ name: 'dotNH', type: 'float' }
	]
});

// https://github.com/google/filament/blob/master/shaders/src/brdf.fs
var V_Neubelt = ShaderNode.tslFn(function(data) {
	var dotNV = data.dotNV;
	var dotNL = data.dotNL;

	// Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
	return 1.0 / (4.0 * (dotNL + dotNV - dotNL * dotNV));
}).setLayout({
	name: 'V_Neubelt',
	type: 'float',
	inputs: [
		{ name: 'dotNV', type: 'float' },
		{ name: 'dotNL', type: 'float' }
	]
});

var BRDF_Sheen = ShaderNode.tslFn(function(data) {
	var lightDirection = data.lightDirection;

	var halfDir = lightDirection.add(PositionNode.positionViewDirection).normalize();

	var dotNL = NormalNode.transformedNormalView.dot(lightDirection).clamp();
	var dotNV = NormalNode.transformedNormalView.dot(PositionNode.positionViewDirection).clamp();
	var dotNH = NormalNode.transformedNormalView.dot(halfDir).clamp();

	var D = D_Charlie({roughness: PropertyNode.sheenRoughness, dotNH: dotNH});
	var V = V_Neubelt({dotNV: dotNV, dotNL: dotNL});

	return PropertyNode.sheen.mul(D).mul(V);
}).setLayout({
	name: 'BRDF_Sheen',
	type: 'float',
	inputs: [
		{ name: 'lightDirection', type: 'float3' }
	]
});

export default BRDF_Sheen;