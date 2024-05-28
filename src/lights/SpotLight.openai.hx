package three.lights;

import three.core.Object3D;
import three.lights.Light;

class SpotLight extends Light {
	public var isSpotLight:Bool = true;
	public var type:String = 'SpotLight';

	public var position:Vector3 = new Vector3(0, 0, 1);
	public var target:Object3D;
	public var distance:Float;
	public var angle:Float;
	public var penumbra:Float;
	public var decay:Float;
	public var map:Texture;
	public var shadow:SpotLightShadow;

	public function new(color:Int, intensity:Float, distance:Float = 0, angle:Float = Math.PI / 3, penumbra:Float = 0, decay:Float = 2) {
		super(color, intensity);
		this.distance = distance;
		this.angle = angle;
		this.penumbra = penumbra;
		this.decay = decay;
		this.target = new Object3D();
		this.shadow = new SpotLightShadow();
	}

	public var power(get, set):Float;

	private function get_power():Float {
		return intensity * Math.PI;
	}

	private function set_power(power:Float):Float {
		intensity = power / Math.PI;
		return power;
	}

	public function dispose():Void {
		shadow.dispose();
	}

	public function copy(source:SpotLight, recursive:Bool):SpotLight {
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