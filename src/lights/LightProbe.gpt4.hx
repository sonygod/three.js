import three.math.SphericalHarmonics3;
import three.lights.Light;

class LightProbe extends Light {
    public var isLightProbe:Bool;
    public var sh:SphericalHarmonics3;

    public function new(?sh:SphericalHarmonics3 = null, ?intensity:Float = 1) {
        super(null, intensity);
        this.isLightProbe = true;
        this.sh = if (sh == null) new SphericalHarmonics3() else sh;
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