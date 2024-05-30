import three.js.examples.jsm.shadernode.ShaderNode;

// Microfacet Models for Refraction through Rough Surfaces - equation (33)
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
// alpha is "roughness squared" in Disney’s reparameterization
var D_GGX = ShaderNode.tslFn(function(data) {
    var alpha = data.alpha;
    var dotNH = data.dotNH;

    var a2 = alpha.pow2();

    var denom = dotNH.pow2().mul(a2.oneMinus()).oneMinus(); // avoid alpha = 0 with dotNH = 1

    return a2.div(denom.pow2()).mul(1 / Math.PI);
}).setLayout({
    name: 'D_GGX',
    type: 'float',
    inputs: [
        { name: 'alpha', type: 'float' },
        { name: 'dotNH', type: 'float' }
    ]
}); // validated

export default D_GGX;