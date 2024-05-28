package three.js.src.lights;

import three.js.src.core.Object3D;
import three.js.src.lights.Light;
import three.js.src.lights.SpotLightShadow;

class SpotLight extends Light {

    public var isSpotLight:Bool = true;
    public var type:String = 'SpotLight';
    public var position:Array<Float> = [0, 0, 0]; // assume default up direction
    public var target:Object3D;
    public var distance:Float;
    public var angle:Float;
    public var penumbra:Float;
    public var decay:Float;
    public var map:Dynamic;
    public var shadow:SpotLightShadow;

    public function new(color:Int, intensity:Float, distance:Float = 0, angle:Float = Math.PI / 3, penumbra:Float = 0, decay:Float = 2) {
        super(color, intensity);
        this.target = new Object3D();
        this.distance = distance;
        this.angle = angle;
        this.penumbra = penumbra;
        this.decay = decay;
        this.shadow = new SpotLightShadow();
    }

    public function get_power():Float {
        return this.intensity * Math.PI;
    }

    public function set_power(power:Float):Void {
        this.intensity = power / Math.PI;
    }

    public function dispose():Void {
        this.shadow.dispose();
    }

    public function copy(source:SpotLight, recursive:Bool = false):SpotLight {
        super.copy(source, recursive);
        this.distance = source.distance;
        this.angle = source.angle;
        this.penumbra = source.penumbra;
        this.decay = source.decay;
        this.target = source.target.clone();
        this.shadow = source.shadow.clone();
        return this;
    }
}