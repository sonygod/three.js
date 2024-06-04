import shadernode.ShaderNode;

class D_GGX_Anisotropic extends ShaderNode {

	static var RECIPROCAL_PI:Float = 1 / Math.PI;

	public function new() {
		super("D_GGX_Anisotropic", "float", [
			{ name: "alphaT", type: "float", qualifier: "in" },
			{ name: "alphaB", type: "float", qualifier: "in" },
			{ name: "dotNH", type: "float", qualifier: "in" },
			{ name: "dotTH", type: "float", qualifier: "in" },
			{ name: "dotBH", type: "float", qualifier: "in" }
		]);
	}

	override function generate(inputs:Map<String, ShaderNode>):String {
		var alphaT = inputs.get("alphaT");
		var alphaB = inputs.get("alphaB");
		var dotNH = inputs.get("dotNH");
		var dotTH = inputs.get("dotTH");
		var dotBH = inputs.get("dotBH");

		return "(${RECIPROCAL_PI} * ($alphaT * $alphaB) * pow((($alphaB * $dotTH) * ($alphaT * $dotBH) + ($alphaT * $alphaB) * $dotNH) / (($alphaB * $dotTH) * ($alphaB * $dotTH) + ($alphaT * $dotBH) * ($alphaT * $dotBH) + ($alphaT * $alphaB) * $dotNH * ($alphaT * $alphaB) * $dotNH), 2))";
	}
}