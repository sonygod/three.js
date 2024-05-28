import js.SphericalHarmonics3;
import js.Light;

class LightProbe extends Light {
	public var sh:SphericalHarmonics3;
	public var isLightProbe:Bool;

	public function new(sh:SphericalHarmonics3 = SphericalHarmonics3(), intensity:Float = 1.0) {
		super(null, intensity);
		this.isLightProbe = true;
		this.sh = sh;
	}

	public function copy(source:LightProbe):LightProbe {
		super.copy(source);
		sh.copy(source.sh);
		return this;
	}

	public function fromJSON(json:Dynamic):LightProbe {
		intensity = json.intensity;
		sh.fromArray(json.sh);
		return this;
	}

	public function toJSON():Dynamic {
		var data = super.toJSON();
		data.sh = sh.toArray();
		return data;
	}
}