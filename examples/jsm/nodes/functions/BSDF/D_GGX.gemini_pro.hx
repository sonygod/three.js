import shadernode.ShaderNode;

// Microfacet Models for Refraction through Rough Surfaces - equation (33)
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
// alpha is "roughness squared" in Disney’s reparameterization
class D_GGX extends ShaderNode {

	static function new(alpha : ShaderNode, dotNH : ShaderNode) : D_GGX {
		var this = new D_GGX();
		this.inputs.push(alpha);
		this.inputs.push(dotNH);
		return this;
	}

	override function evaluate(inputs : Array<Dynamic>) : Float {
		var alpha = inputs[0] as Float;
		var dotNH = inputs[1] as Float;
		var a2 = alpha * alpha;
		var denom = 1 - dotNH * dotNH * (1 - a2);
		return a2 / (denom * denom) * (1 / Math.PI);
	}

	static function get(alpha : ShaderNode, dotNH : ShaderNode) : D_GGX {
		return new D_GGX(alpha, dotNH);
	}

	override function getTypeName() : String {
		return "float";
	}

	override function getName() : String {
		return "D_GGX";
	}

	override function getInputs() : Array<ShaderNode.Input> {
		return [
			{ name : "alpha", type : "float" },
			{ name : "dotNH", type : "float" }
		];
	}
}

class D_GGX_ extends ShaderNode {

	static function new() : D_GGX_ {
		var this = new D_GGX_();
		this.inputs.push(new ShaderNode.Input("alpha", "float"));
		this.inputs.push(new ShaderNode.Input("dotNH", "float"));
		return this;
	}

	override function evaluate(inputs : Array<Dynamic>) : Float {
		var alpha = inputs[0] as Float;
		var dotNH = inputs[1] as Float;
		var a2 = alpha * alpha;
		var denom = 1 - dotNH * dotNH * (1 - a2);
		return a2 / (denom * denom) * (1 / Math.PI);
	}

	static function get() : D_GGX_ {
		return new D_GGX_();
	}

	override function getTypeName() : String {
		return "float";
	}

	override function getName() : String {
		return "D_GGX";
	}

	override function getInputs() : Array<ShaderNode.Input> {
		return [
			{ name : "alpha", type : "float" },
			{ name : "dotNH", type : "float" }
		];
	}
}

var D_GGX : ShaderNode = new D_GGX_();