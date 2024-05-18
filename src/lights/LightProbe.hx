package three.lights;;

import three.math.SphericalHarmonics3;
import three.lights.Light;

class LightProbe extends Light {

    public var isLightProbe:Bool = true;

    public var sh:SphericalHarmonics3;

    public function new(sh:SphericalHarmonics3 = new SphericalHarmonics3(), intensity:Float = 1) {
        super(undefined, intensity);
        this.sh = sh;
    }

    public function copy(source:LightProbe):LightProbe {
        super.copy(source);
        sh.copy(source.sh);
        return this;
    }

    public function fromJSON(json:Dynamic):LightProbe {
        intensity = json.intensity; // TODO: Move this bit to Light.fromJSON();
        sh.fromArray(json.sh);
        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);
        data.object.sh = sh.toArray();
        return data;
    }
}