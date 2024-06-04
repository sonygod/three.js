import Color from "../math/Color";

class Fog {
	public var isFog:Bool = true;
	public var name:String = "";
	public var color:Color;
	public var near:Float;
	public var far:Float;

	public function new(color:Dynamic, near:Float = 1, far:Float = 1000) {
		this.color = new Color(color);
		this.near = near;
		this.far = far;
	}

	public function clone():Fog {
		return new Fog(this.color, this.near, this.far);
	}

	public function toJSON():Dynamic {
		return {
			type: "Fog",
			name: this.name,
			color: this.color.getHex(),
			near: this.near,
			far: this.far
		};
	}
}

class Fog {
	public static function main():Void {
		// Example usage
		var fog = new Fog(0xffffff, 10, 100);
		trace(fog.toJSON());
	}
}