import haxe.ui.Matrix4;
import haxe.ui.PerspectiveCamera;
import haxe.ui.math.MathUtils;

class StereoCamera {

	public var type:String = "StereoCamera";
	public var aspect:Float = 1;
	public var eyeSep:Float = 0.064;

	public var cameraL:PerspectiveCamera;
	public var cameraR:PerspectiveCamera;

	private var _cache: {
		focus:Float,
		fov:Float,
		aspect:Float,
		near:Float,
		far:Float,
		zoom:Float,
		eyeSep:Float
	};

	public function new() {
		this.cameraL = new PerspectiveCamera();
		this.cameraL.layers.enable(1);
		this.cameraL.matrixAutoUpdate = false;

		this.cameraR = new PerspectiveCamera();
		this.cameraR.layers.enable(2);
		this.cameraR.matrixAutoUpdate = false;

		this._cache = {
			focus: null,
			fov: null,
			aspect: null,
			near: null,
			far: null,
			zoom: null,
			eyeSep: null
		};
	}

	public function update(camera:PerspectiveCamera) {
		var cache = this._cache;

		var needsUpdate = cache.focus != camera.focus || cache.fov != camera.fov ||
			cache.aspect != camera.aspect * this.aspect || cache.near != camera.near ||
			cache.far != camera.far || cache.zoom != camera.zoom || cache.eyeSep != this.eyeSep;

		if (needsUpdate) {
			cache.focus = camera.focus;
			cache.fov = camera.fov;
			cache.aspect = camera.aspect * this.aspect;
			cache.near = camera.near;
			cache.far = camera.far;
			cache.zoom = camera.zoom;
			cache.eyeSep = this.eyeSep;

			// Off-axis stereoscopic effect based on
			// http://paulbourke.net/stereographics/stereorender/

			var _projectionMatrix = new Matrix4();
			_projectionMatrix.copy(camera.projectionMatrix);
			var eyeSepHalf = cache.eyeSep / 2;
			var eyeSepOnProjection = eyeSepHalf * cache.near / cache.focus;
			var ymax = (cache.near * Math.tan(MathUtils.DEG2RAD * cache.fov * 0.5)) / cache.zoom;
			var xmin:Float, xmax:Float;

			// translate xOffset

			var _eyeLeft = new Matrix4();
			var _eyeRight = new Matrix4();
			_eyeLeft.elements[12] = -eyeSepHalf;
			_eyeRight.elements[12] = eyeSepHalf;

			// for left eye

			xmin = -ymax * cache.aspect + eyeSepOnProjection;
			xmax = ymax * cache.aspect + eyeSepOnProjection;

			_projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
			_projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);

			this.cameraL.projectionMatrix.copy(_projectionMatrix);

			// for right eye

			xmin = -ymax * cache.aspect - eyeSepOnProjection;
			xmax = ymax * cache.aspect - eyeSepOnProjection;

			_projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
			_projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);

			this.cameraR.projectionMatrix.copy(_projectionMatrix);
		}

		this.cameraL.matrixWorld.copy(camera.matrixWorld).multiply(_eyeLeft);
		this.cameraR.matrixWorld.copy(camera.matrixWorld).multiply(_eyeRight);
	}

}