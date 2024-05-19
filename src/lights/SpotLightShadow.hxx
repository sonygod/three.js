import three.js.src.lights.LightShadow;
import three.js.src.math.MathUtils;
import three.js.src.cameras.PerspectiveCamera;

class SpotLightShadow extends LightShadow {

	public function new() {

		super(new PerspectiveCamera(50, 1, 0.5, 500));

		this.isSpotLightShadow = true;

		this.focus = 1;

	}

	public function updateMatrices(light:Dynamic) {

		var camera = this.camera;

		var fov = MathUtils.RAD2DEG * 2 * light.angle * this.focus;
		var aspect = this.mapSize.width / this.mapSize.height;
		var far = if (light.distance != null) light.distance else camera.far;

		if (fov != camera.fov || aspect != camera.aspect || far != camera.far) {

			camera.fov = fov;
			camera.aspect = aspect;
			camera.far = far;
			camera.updateProjectionMatrix();

		}

		super.updateMatrices(light);

	}

	public function copy(source:Dynamic) {

		super.copy(source);

		this.focus = source.focus;

		return this;

	}

}