import js.Boot;
import three.math.SphericalHarmonics3;
import three.lights.Light;

class LightProbe extends Light {

    public var sh:SphericalHarmonics3;

    public function new(?sh:SphericalHarmonics3 = null, ?intensity:Float = 1) {
        if (sh == null) sh = new SphericalHarmonics3();
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
        this.intensity = js.Boot.dynamicField(json, "intensity");
        this.sh.fromArray(js.Boot.dynamicField(json, "sh"));
        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);
        js.Boot.dynamicField(data.object, "sh") = this.sh.toArray();
        return data;
    }

}