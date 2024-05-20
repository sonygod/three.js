import three.math.Color;

class FogExp2 {

	public var isFogExp2:Bool;
	public var name:String;
	public var color:Color;
	public var density:Float;

	public function new(color:Dynamic, density:Float = 0.00025) {
		this.isFogExp2 = true;
		this.name = '';
		this.color = new Color(color);
		this.density = density;
	}

	public function clone():FogExp2 {
		return new FogExp2(this.color, this.density);
	}

	public function toJSON(meta:Dynamic = null):Dynamic {
		return {
			type: 'FogExp2',
			name: this.name,
			color: this.color.getHex(),
			density: this.density
		};
	}

}