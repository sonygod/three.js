package three.js.src.lights;

import three.js.src.math.SphericalHarmonics3;
import three.js.src.lights.Light;

class LightProbe extends Light {
    public var isLightProbe:Bool = true;
    public var sh:SphericalHarmonics3;

    public function new(sh:SphericalHarmonics3 = new SphericalHarmonics3(), intensity:Float = 1) {
        super(undefined, intensity);
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
        var data:Dynamic = super.toJSON(meta);
        data.object.sh = this.sh.toArray();
        return data;
    }
}