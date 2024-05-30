import Light from './Light.js';
import PointLightShadow from './PointLightShadow.js';

class PointLight extends Light {

	public var isPointLight:Bool = true;
	public var type:String = 'PointLight';
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
		// compute the light's luminous power (in lumens) from its intensity (in candela)
		// for an isotropic light source, luminous power (lm) = 4 π luminous intensity (cd)
		return this.intensity * 4 * Math.PI;
	}

	public function set_power(power:Float):Void {
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

export default PointLight;