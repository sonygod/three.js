import three.math.Matrix4;
import three.math.MathUtils;
import three.cameras.PerspectiveCamera;

class StereoCamera {
	public var type:String = "StereoCamera";
	public var aspect:Float = 1;
	public var eyeSep:Float = 0.064;
	public var cameraL:PerspectiveCamera = new PerspectiveCamera();
	public var cameraR:PerspectiveCamera = new PerspectiveCamera();
	private var _cache:Dynamic = {
		focus: null,
		fov: null,
		aspect: null,
		near: null,
		far: null,
		zoom: null,
		eyeSep: null
	};

	public function new() {
		cameraL.layers.enable(1);
		cameraL.matrixAutoUpdate = false;
		cameraR.layers.enable(2);
		cameraR.matrixAutoUpdate = false;
	}

	public function update(camera:PerspectiveCamera):Void {
		var cache = _cache;
		var needsUpdate = cache.focus != camera.focus || cache.fov != camera.fov ||
			cache.aspect != camera.aspect * aspect || cache.near != camera.near ||
			cache.far != camera.far || cache.zoom != camera.zoom || cache.eyeSep != eyeSep;

		if (needsUpdate) {
			cache.focus = camera.focus;
			cache.fov = camera.fov;
			cache.aspect = camera.aspect * aspect;
			cache.near = camera.near;
			cache.far = camera.far;
			cache.zoom = camera.zoom;
			cache.eyeSep = eyeSep;

			// Off-axis stereoscopic effect based on
			// http://paulbourke.net/stereographics/stereorender/

			var _projectionMatrix = new Matrix4().copy(camera.projectionMatrix);
			var eyeSepHalf = cache.eyeSep / 2;
			var eyeSepOnProjection = eyeSepHalf * cache.near / cache.focus;
			var ymax = (cache.near * Math.tan(MathUtils.DEG2RAD * cache.fov * 0.5)) / cache.zoom;
			var xmin:Float, xmax:Float;

			// translate xOffset

			var _eyeLeft = new Matrix4();
			_eyeLeft.elements[12] = -eyeSepHalf;

			var _eyeRight = new Matrix4();
			_eyeRight.elements[12] = eyeSepHalf;

			// for left eye

			xmin = -ymax * cache.aspect + eyeSepOnProjection;
			xmax = ymax * cache.aspect + eyeSepOnProjection;

			_projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
			_projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);

			cameraL.projectionMatrix.copy(_projectionMatrix);

			// for right eye

			xmin = -ymax * cache.aspect - eyeSepOnProjection;
			xmax = ymax * cache.aspect - eyeSepOnProjection;

			_projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
			_projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);

			cameraR.projectionMatrix.copy(_projectionMatrix);
		}

		cameraL.matrixWorld.copy(camera.matrixWorld).multiply(_eyeLeft);
		cameraR.matrixWorld.copy(camera.matrixWorld).multiply(_eyeRight);
	}
}