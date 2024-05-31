import three.lights.Light;
import three.lights.PointLightShadow;

class PointLight extends Light {

	public var distance:Float;
	public var decay:Float;
	public var shadow:PointLightShadow;

	public function new(color:Dynamic, intensity:Float, distance:Float = 0, decay:Float = 2) {
		super(color, intensity);
		this.isPointLight = true;
		this.type = 'PointLight';
		this.distance = distance;
		this.decay = decay;
		this.shadow = new PointLightShadow();
	}

	public function get_power():Float {
		// compute the light's luminous power (in lumens) from its intensity (in candela)
		// for an isotropic light source, luminous power (lm) = 4 π luminous intensity (cd)
		return this.intensity * 4 * Math.PI;
	}

	public function set_power(power:Float):Void {
		// set the light's intensity (in candela) from the desired luminous power (in lumens)
		this.intensity = power / (4 * Math.PI);
	}

	public function dispose():Void {
		this.shadow.dispose();
	}

	public override function copy(source:Light, ?recursive:Bool):PointLight {
		super.copy(source, recursive);
		if (Std.is(source, PointLight)) {
			var src:PointLight = cast source;
			this.distance = src.distance;
			this.decay = src.decay;
			this.shadow = src.shadow.clone();
		}
		return this;
	}

}