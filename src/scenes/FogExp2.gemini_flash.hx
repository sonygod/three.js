package ;

import three.math.Color;

class FogExp2 {

	public var isFogExp2(default, null) : Bool;
	public var name : String;
	public var color : Color;
	public var density : Float;

	public function new(color : Int, density : Float = 0.00025) {

		this.isFogExp2 = true;

		this.name = '';

		this.color = new Color(color);
		this.density = density;

	}

	public function clone() : FogExp2 {

		return new FogExp2(this.color.getHex(), this.density);

	}

	public function toJSON(/* meta */) : Dynamic {

		return {
			'type': 'FogExp2',
			'name': this.name,
			'color': this.color.getHex(),
			'density': this.density
		};

	}

}

#if (!macro)
@:expose
class FogExp2_ {
	inline public static function create(color : Int, density : Float = 0.00025) : FogExp2 {
		return new FogExp2(color, density);
	}
}
#end