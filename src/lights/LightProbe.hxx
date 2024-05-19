import three.js.src.math.SphericalHarmonics3;
import three.js.src.lights.Light;

class LightProbe extends Light {

	public function new(sh:SphericalHarmonics3 = new SphericalHarmonics3(), intensity:Float = 1) {
		super(null, intensity);
		this.isLightProbe = true;
		this.sh = sh;
	}

	public function copy(source:LightProbe):LightProbe {
		super.copy(source);
		this.sh.copy(source.sh);
		return this;
	}

	public function fromJSON(json:Dynamic):LightProbe {
		this.intensity = json.intensity; // TODO: Move this bit to Light.fromJSON();
		this.sh.fromArray(json.sh);
		return this;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var data = super.toJSON(meta);
		data.object.sh = this.sh.toArray();
		return data;
	}
}