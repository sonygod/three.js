import Light from "./Light";
import SpotLightShadow from "./SpotLightShadow";
import Object3D from "../core/Object3D";

class SpotLight extends Light {
    public isSpotLight:Bool = true;
    public type:String = "SpotLight";
    public position:Object3D = new Object3D();
    public target:Object3D;
    public distance:Float;
    public angle:Float;
    public penumbra:Float;
    public decay:Float;
    public map:Null<Dynamic>;
    public shadow:SpotLightShadow;

    public function new(color:Int, intensity:Float, distance:Float = 0, angle:Float = Math.PI / 3, penumbra:Float = 0, decay:Float = 2) {
        super(color, intensity);

        this.updateMatrix();
        this.target = new Object3D();
        this.distance = distance;
        this.angle = angle;
        this.penumbra = penumbra;
        this.decay = decay;
        this.map = null;
        this.shadow = new SpotLightShadow();
    }

    public function get_power():Float {
        return this.intensity * Math.PI;
    }

    public function set_power(power:Float) {
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

export { SpotLight };