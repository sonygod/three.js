class Fog {
	public var isFog:Bool = true;
	public var name:String;
	public var color:Color;
	public var near:Float;
	public var far:Float;

	public function new(color:Color, near:Float = 1, far:Float = 1000) {
		this.name = '';
		this.color = color;
		this.near = near;
		this.far = far;
	}

	public function clone():Fog {
		return new Fog(this.color, this.near, this.far);
	}

	public function toJSON():HashMap {
		return {
			'type': 'Fog',
			'name': this.name,
			'color': this.color.getHex(),
			'near': this.near,
			'far': this.far
		};
	}
}