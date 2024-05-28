package three.js.src.lights;

import three.js.src.lights.Light;
import three.js.src.lights.PointLightShadow;

class PointLight extends Light {

    public var isPointLight:Bool = true;
    public var type:String = 'PointLight';
    public var distance:Float = 0;
    public var decay:Float = 2;
    public var shadow:PointLightShadow;

    public function new(color:Int, intensity:Float, distance:Float = 0, decay:Float = 2) {
        super(color, intensity);
        this.distance = distance;
        this.decay = decay;
        this.shadow = new PointLightShadow();
    }

    public var power(get, set):Float;

    private function get_power():Float {
        return intensity * 4 * Math.PI;
    }

    private function set_power(power:Float):Float {
        intensity = power / (4 * Math.PI);
        return power;
    }

    public function dispose():Void {
        shadow.dispose();
    }

    public function copy(source:PointLight, recursive:Bool):PointLight {
        super.copy(source, recursive);
        distance = source.distance;
        decay = source.decay;
        shadow = source.shadow.clone();
        return this;
    }
}