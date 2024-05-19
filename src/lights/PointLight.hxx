import three.js.src.lights.Light;
import three.js.src.lights.PointLightShadow;

class PointLight extends Light {

	public function new(color:Int, intensity:Float, distance:Float = 0, decay:Float = 2) {
		super(color, intensity);

		this.isPointLight = true;

		this.type = 'PointLight';

		this.distance = distance;
		this.decay = decay;

		this.shadow = new PointLightShadow();
	}

	public inline function get_power():Float {
		// compute the light's luminous power (in lumens) from its intensity (in candela)
		// for an isotropic light source, luminous power (lm) = 4 π luminous intensity (cd)
		return this.intensity * 4 * Math.PI;
	}

	public inline function set_power(power:Float):Void {
		// set the light's intensity (in candela) from the desired luminous power (in lumens)
		this.intensity = power / ( 4 * Math.PI );
	}

	public function dispose():Void {
		this.shadow.dispose();
	}

	public function copy(source:PointLight, recursive:Bool):PointLight {
		super.copy(source, recursive);

		this.distance = source.distance;
		this.decay = source.decay;

		this.shadow = source.shadow.clone();

		return this;
	}
}