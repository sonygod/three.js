import js.Math;

class D_GGX {
	public static function get_tslFn() : js.t.Function {
		return js.t.Function.fromFunction(function( { alpha, dotNH } : { alpha : Float, dotNH : Float } ) : Float {
			var a2 = alpha * alpha;
			var denom = (dotNH * dotNH) * (1.0 - a2) + a2; // avoid alpha = 0 with dotNH = 1
			return (a2 / (denom * denom)) * (1.0 / Math.PI);
		});
	}

	public static var layout : Map<String, Dynamic> = {
		'name' : 'D_GGX',
		'type' : 'float',
		'inputs' : [
			{ 'name' : 'alpha', 'type' : 'float' },
			{ 'name' : 'dotNH', 'type' : 'float' }
		]
	};
}

class Export {
	public static var __default : js.t.Function = D_GGX.get_tslFn();
}