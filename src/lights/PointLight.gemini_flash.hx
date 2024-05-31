import three.lights.Light;
import three.lights.PointLightShadow;

class PointLight extends Light {
	public var isPointLight:Bool = true;
	public var type:String = "PointLight";
	public var distance:Float;
	public var decay:Float;
	public var shadow:PointLightShadow;

	public function new(color:Dynamic, intensity:Float, distance:Float = 0, decay:Float = 2) {
		super(color, intensity);
		this.distance = distance;
		this.decay = decay;
		this.shadow = new PointLightShadow();
	}

	public function get_power():Float {
		return intensity * 4 * Math.PI;
	}

	public function set_power(power:Float):Float {
		intensity = power / (4 * Math.PI);
		return power;
	}

	public function dispose() {
		shadow.dispose();
	}

	public function copy(source:PointLight, recursive:Bool = true):PointLight {
		super.copy(source, recursive);
		distance = source.distance;
		decay = source.decay;
		shadow = source.shadow.clone();
		return this;
	}
}