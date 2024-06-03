import three.lights.Light;
import three.lights.SpotLightShadow;
import three.core.Object3D;

class SpotLight extends Light {

	public var target: Object3D;
	public var map: Dynamic;
	public var shadow: SpotLightShadow;

	public function new(color: Int, intensity: Float, distance: Float = 0, angle: Float = Math.PI / 3, penumbra: Float = 0, decay: Float = 2) {
		super(color, intensity);

		this.isSpotLight = true;
		this.type = 'SpotLight';

		this.position.copy(Object3D.DEFAULT_UP);
		this.updateMatrix();

		this.target = new Object3D();
		this.distance = distance;
		this.angle = angle;
		this.penumbra = penumbra;
		this.decay = decay;

		this.map = null;
		this.shadow = new SpotLightShadow();
	}

	public function get_power(): Float {
		return this.intensity * Math.PI;
	}

	public function set_power(power: Float): Void {
		this.intensity = power / Math.PI;
	}

	public function dispose(): Void {
		this.shadow.dispose();
	}

	public function copy(source: SpotLight, recursive: Bool = true): SpotLight {
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