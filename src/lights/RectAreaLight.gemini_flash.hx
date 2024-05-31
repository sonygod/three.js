import three.lights.Light;

class RectAreaLight extends Light {

	public var isRectAreaLight:Bool;
	public var type:String;
	public var width:Float;
	public var height:Float;

	public function new(color:Dynamic, intensity:Float, width:Float = 10, height:Float = 10) {
		super(color, intensity);

		isRectAreaLight = true;
		type = "RectAreaLight";
		this.width = width;
		this.height = height;
	}

	public function get_power():Float {
		return intensity * width * height * Math.PI;
	}

	public function set_power(power:Float):Void {
		intensity = power / (width * height * Math.PI);
	}

	public function copy(source:RectAreaLight):RectAreaLight {
		super.copy(source);
		width = source.width;
		height = source.height;
		return this;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var data = super.toJSON(meta);
		data.object.width = width;
		data.object.height = height;
		return data;
	}
}