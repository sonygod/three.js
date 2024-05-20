import three.math.Color;

class Fog {

	public var isFog:Bool;
	public var name:String;
	public var color:Color;
	public var near:Float;
	public var far:Float;

	public function new(color:Dynamic, ?near:Float = 1, ?far:Float = 1000) {
		this.isFog = true;
		this.name = '';
		this.color = new Color(color);
		this.near = near;
		this.far = far;
	}

	public function clone():Fog {
		return new Fog(this.color, this.near, this.far);
	}

	public function toJSON(meta:Dynamic = null):Dynamic {
		return {
			type: 'Fog',
			name: this.name,
			color: this.color.getHex(),
			near: this.near,
			far: this.far
		};
	}
}