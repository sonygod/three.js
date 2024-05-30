import three.math.SphericalHarmonics3;
import three.lights.Light;

class LightProbe extends Light {

    public var isLightProbe:Bool;
    public var sh:SphericalHarmonics3;

    public function new(sh:SphericalHarmonics3 = null, intensity:Float = 1) {
        super(null, intensity);
        this.isLightProbe = true;
        this.sh = if (sh != null) sh else new SphericalHarmonics3();
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

// Assuming Light and SphericalHarmonics3 are defined in respective files
package three.math;
class SphericalHarmonics3 {
    public function new() {}
    public function copy(sh:SphericalHarmonics3):Void {}
    public function fromArray(arr:Array<Float>):Void {}
    public function toArray():Array<Float> { return []; }
}

package three.lights;
class Light {
    public var intensity:Float;
    
    public function new(color:Dynamic, intensity:Float) {
        this.intensity = intensity;
    }
    
    public function copy(source:Light):Light {
        this.intensity = source.intensity;
        return this;
    }
    
    public function toJSON(meta:Dynamic):Dynamic {
        return { intensity: this.intensity };
    }
}