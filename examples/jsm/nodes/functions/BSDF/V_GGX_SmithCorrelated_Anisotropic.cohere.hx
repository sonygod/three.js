import js.Math.*;

@:shim("Math.max(a, b)")
private static function saturate(f:Float) : Float {
	return Math.max(f, 0.0);
}

@:shim("Math.sqrt(a * a + b * b + c * c)")
private static function length(a:Float, b:Float, c:Float) : Float {
	return Math.sqrt(a * a + b * b + c * c);
}

function V_GGX_SmithCorrelated_Anisotropic(alphaT:Float, alphaB:Float, dotTV:Float, dotBV:Float, dotTL:Float, dotBL:Float, dotNV:Float, dotNL:Float) : Float {
	var gv = dotNL * length(alphaT * dotTV, alphaB * dotBV, dotNV);
	var gl = dotNV * length(alphaT * dotTL, alphaB * dotBL, dotNL);
	var v = 0.5 / (gv + gl);
	return saturate(v);
}

class V_GGX_SmithCorrelated_Anisotropic_d {
	public static var name:String = 'V_GGX_SmithCorrelated_Anisotropic';
	public static var type:String = 'Float';
	public static var inputs:Array<Map<String, Dynamic>> = [
		{ name: 'alphaT', type: 'Float' },
		{ name: 'alphaB', type: 'Float' },
		{ name: 'dotTV', type: 'Float' },
		{ name: 'dotBV', type: 'Float' },
		{ name: 'dotTL', type: 'Float' },
		{ name: 'dotBL', type: 'Float' },
		{ name: 'dotNV', type: 'Float' },
		{ name: 'dotNL', type: 'Float' }
	];
}