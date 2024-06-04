import haxe.macro.Expr;
import haxe.macro.Type;

class V_GGX_SmithCorrelated_Anisotropic {

	static function main() {
		var inputs = [
			{ name: 'alphaT', type: Type.Float, qualifier: 'in' },
			{ name: 'alphaB', type: Type.Float, qualifier: 'in' },
			{ name: 'dotTV', type: Type.Float, qualifier: 'in' },
			{ name: 'dotBV', type: Type.Float, qualifier: 'in' },
			{ name: 'dotTL', type: Type.Float, qualifier: 'in' },
			{ name: 'dotBL', type: Type.Float, qualifier: 'in' },
			{ name: 'dotNV', type: Type.Float, qualifier: 'in' },
			{ name: 'dotNL', type: Type.Float, qualifier: 'in' }
		];

		return Expr.function(
			[],
			[Expr.block(
				[
					Expr.var("gv", Expr.call("mul", [Expr.field("dotNL", null), Expr.call("length", [Expr.call("vec3", [Expr.call("mul", [Expr.field("alphaT", null), Expr.field("dotTV", null)]), Expr.call("mul", [Expr.field("alphaB", null), Expr.field("dotBV", null)]), Expr.field("dotNV", null)])])])),
					Expr.var("gl", Expr.call("mul", [Expr.field("dotNV", null), Expr.call("length", [Expr.call("vec3", [Expr.call("mul", [Expr.field("alphaT", null), Expr.field("dotTL", null)]), Expr.call("mul", [Expr.field("alphaB", null), Expr.field("dotBL", null)]), Expr.field("dotNL", null)])])])),
					Expr.var("v", Expr.call("div", [Expr.constant(0.5), Expr.call("add", [Expr.field("gv", null), Expr.field("gl", null)])])),
					Expr.return(Expr.call("saturate", [Expr.field("v", null)]))
				]
			)],
			"float",
			Expr.string("V_GGX_SmithCorrelated_Anisotropic"),
			inputs
		);
	}
}

class ShaderNode {

	static function tslFn(expr:Expr) {
		return expr;
	}

	static function vec3(x:Expr, y:Expr, z:Expr) {
		return Expr.call("vec3", [x, y, z]);
	}
}

class OperatorNode {

	static function div(a:Expr, b:Expr) {
		return Expr.call("div", [a, b]);
	}
}

class Math {

	static function saturate(x:Expr) {
		return Expr.call("saturate", [x]);
	}
}

var V_GGX_SmithCorrelated_Anisotropic = V_GGX_SmithCorrelated_Anisotropic.main();