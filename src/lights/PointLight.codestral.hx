import js.Browser.Math;
import Light from './Light';
import PointLightShadow from './PointLightShadow';

class PointLight extends Light {

    public var isPointLight:Bool;
    public var type:String;
    public var distance:Float;
    public var decay:Float;
    public var shadow:PointLightShadow;

    public function new(color:Int, intensity:Float, distance:Float = 0.0, decay:Float = 2.0) {
        super(color, intensity);

        this.isPointLight = true;
        this.type = 'PointLight';
        this.distance = distance;
        this.decay = decay;
        this.shadow = new PointLightShadow();
    }

    public inline function get_power():Float {
        // compute the light's luminous power (in lumens) from its intensity (in candela)
        // for an isotropic light source, luminous power (lm) = 4 π luminous intensity (cd)
        return this.intensity * 4 * Math.PI;
    }

    public inline function set_power(power:Float):Float {
        // set the light's intensity (in candela) from the desired luminous power (in lumens)
        return this.intensity = power / (4 * Math.PI);
    }

    public function dispose() {
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

export PointLight;