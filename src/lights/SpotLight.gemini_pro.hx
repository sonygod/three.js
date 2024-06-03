import Light from "./Light";
import SpotLightShadow from "./SpotLightShadow";
import Object3D from "../core/Object3D";

class SpotLight extends Light {

	public var isSpotLight:Bool = true;
	public var type:String = "SpotLight";
	public var target:Object3D;
	public var distance:Float;
	public var angle:Float;
	public var penumbra:Float;
	public var decay:Float;
	public var map:Dynamic;
	public var shadow:SpotLightShadow;

	public function new(color:Dynamic, intensity:Float, distance:Float = 0, angle:Float = Math.PI / 3, penumbra:Float = 0, decay:Float = 2) {
		super(color, intensity);
		this.position.copy(Object3D.DEFAULT_UP);
		this.updateMatrix();
		this.target = new Object3D();
		this.distance = distance;
		this.angle = angle;
		this.penumbra = penumbra;
		this.decay = decay;
		this.shadow = new SpotLightShadow();
	}

	public function get power():Float {
		return this.intensity * Math.PI;
	}

	public function set power(power:Float) {
		this.intensity = power / Math.PI;
	}

	public function dispose() {
		this.shadow.dispose();
	}

	public function copy(source:SpotLight, recursive:Bool = true):SpotLight {
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

export default SpotLight;