import SphericalHarmonics3.SphericalHarmonics3;
import Light.Light;

class LightProbe extends Light {

    public var sh:SphericalHarmonics3;

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

export(LightProbe);