package three.js.src.lights;

import three.js.src.math.SphericalHarmonics3;
import three.js.src.lights.Light;

class LightProbe extends Light {
    public var isLightProbe:Bool = true;
    public var sh:SphericalHarmonics3;

    public function new(sh:SphericalHarmonics3 = null, intensity:Float = 1) {
        if (sh == null) sh = new SphericalHarmonics3();
        super(null, intensity);
        this.sh = sh;
    }

    public function copy(source:LightProbe):LightProbe {
        super.copy(source);
        this.sh.copy(source.sh);
        return this;
    }

    public function fromJSON(json:Dynamic):LightProbe {
        intensity = json.intensity;
        sh.fromArray(json.sh);
        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);
        data.object.sh = sh.toArray();
        return data;
    }
}