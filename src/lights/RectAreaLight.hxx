import three.js.src.lights.Light;

class RectAreaLight extends Light {

	public function new(color:Int, intensity:Float, width:Float = 10, height:Float = 10) {
		super(color, intensity);

		this.isRectAreaLight = true;
		this.type = 'RectAreaLight';
		this.width = width;
		this.height = height;
	}

	public inline function get_power():Float {
		return this.intensity * this.width * this.height * Math.PI;
	}

	public inline function set_power(power:Float):Void {
		this.intensity = power / (this.width * this.height * Math.PI);
	}

	public function copy(source:RectAreaLight):RectAreaLight {
		super.copy(source);

		this.width = source.width;
		this.height = source.height;

		return this;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var data = super.toJSON(meta);

		data.object.width = this.width;
		data.object.height = this.height;

		return data;
	}
}