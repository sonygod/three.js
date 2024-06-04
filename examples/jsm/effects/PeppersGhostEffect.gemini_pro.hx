import three.PerspectiveCamera;
import three.Quaternion;
import three.Vector3;

/**
 * peppers ghost effect based on http://www.instructables.com/id/Reflective-Prism/?ALLSTEPS
 */
class PeppersGhostEffect {
	public var cameraDistance:Float = 15;
	public var reflectFromAbove:Bool = false;

	// Internals
	private var _halfWidth:Float;
	private var _width:Float;
	private var _height:Float;

	private var _cameraF:PerspectiveCamera; //front
	private var _cameraB:PerspectiveCamera; //back
	private var _cameraL:PerspectiveCamera; //left
	private var _cameraR:PerspectiveCamera; //right

	private var _position:Vector3;
	private var _quaternion:Quaternion;
	private var _scale:Vector3;

	public function new(renderer:three.Renderer) {
		this._cameraF = new PerspectiveCamera(); //front
		this._cameraB = new PerspectiveCamera(); //back
		this._cameraL = new PerspectiveCamera(); //left
		this._cameraR = new PerspectiveCamera(); //right

		this._position = new Vector3();
		this._quaternion = new Quaternion();
		this._scale = new Vector3();

		// Initialization
		renderer.autoClear = false;

		this.setSize = function(width:Float, height:Float) {
			this._halfWidth = width / 2;
			if (width < height) {
				this._width = width / 3;
				this._height = width / 3;
			} else {
				this._width = height / 3;
				this._height = height / 3;
			}
			renderer.setSize(width, height);
		};

		this.render = function(scene:three.Scene, camera:PerspectiveCamera) {
			if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
			if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
			camera.matrixWorld.decompose(this._position, this._quaternion, this._scale);

			// front
			this._cameraF.position.copy(this._position);
			this._cameraF.quaternion.copy(this._quaternion);
			this._cameraF.translateZ(this.cameraDistance);
			this._cameraF.lookAt(scene.position);

			// back
			this._cameraB.position.copy(this._position);
			this._cameraB.quaternion.copy(this._quaternion);
			this._cameraB.translateZ(-this.cameraDistance);
			this._cameraB.lookAt(scene.position);
			this._cameraB.rotation.z += 180 * (Math.PI / 180);

			// left
			this._cameraL.position.copy(this._position);
			this._cameraL.quaternion.copy(this._quaternion);
			this._cameraL.translateX(-this.cameraDistance);
			this._cameraL.lookAt(scene.position);
			this._cameraL.rotation.x += 90 * (Math.PI / 180);

			// right
			this._cameraR.position.copy(this._position);
			this._cameraR.quaternion.copy(this._quaternion);
			this._cameraR.translateX(this.cameraDistance);
			this._cameraR.lookAt(scene.position);
			this._cameraR.rotation.x += 90 * (Math.PI / 180);

			renderer.clear();
			renderer.setScissorTest(true);

			renderer.setScissor(this._halfWidth - (this._width / 2), (this._height * 2), this._width, this._height);
			renderer.setViewport(this._halfWidth - (this._width / 2), (this._height * 2), this._width, this._height);

			if (this.reflectFromAbove) {
				renderer.render(scene, this._cameraB);
			} else {
				renderer.render(scene, this._cameraF);
			}

			renderer.setScissor(this._halfWidth - (this._width / 2), 0, this._width, this._height);
			renderer.setViewport(this._halfWidth - (this._width / 2), 0, this._width, this._height);

			if (this.reflectFromAbove) {
				renderer.render(scene, this._cameraF);
			} else {
				renderer.render(scene, this._cameraB);
			}

			renderer.setScissor(this._halfWidth - (this._width / 2) - this._width, this._height, this._width, this._height);
			renderer.setViewport(this._halfWidth - (this._width / 2) - this._width, this._height, this._width, this._height);

			if (this.reflectFromAbove) {
				renderer.render(scene, this._cameraR);
			} else {
				renderer.render(scene, this._cameraL);
			}

			renderer.setScissor(this._halfWidth + (this._width / 2), this._height, this._width, this._height);
			renderer.setViewport(this._halfWidth + (this._width / 2), this._height, this._width, this._height);

			if (this.reflectFromAbove) {
				renderer.render(scene, this._cameraL);
			} else {
				renderer.render(scene, this._cameraR);
			}

			renderer.setScissorTest(false);
		};
	}

	public function setSize(width:Float, height:Float) {
		this._halfWidth = width / 2;
		if (width < height) {
			this._width = width / 3;
			this._height = width / 3;
		} else {
			this._width = height / 3;
			this._height = height / 3;
		}
	}

	public function render(scene:three.Scene, camera:PerspectiveCamera) {
		if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
		if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
		camera.matrixWorld.decompose(this._position, this._quaternion, this._scale);

		// front
		this._cameraF.position.copy(this._position);
		this._cameraF.quaternion.copy(this._quaternion);
		this._cameraF.translateZ(this.cameraDistance);
		this._cameraF.lookAt(scene.position);

		// back
		this._cameraB.position.copy(this._position);
		this._cameraB.quaternion.copy(this._quaternion);
		this._cameraB.translateZ(-this.cameraDistance);
		this._cameraB.lookAt(scene.position);
		this._cameraB.rotation.z += 180 * (Math.PI / 180);

		// left
		this._cameraL.position.copy(this._position);
		this._cameraL.quaternion.copy(this._quaternion);
		this._cameraL.translateX(-this.cameraDistance);
		this._cameraL.lookAt(scene.position);
		this._cameraL.rotation.x += 90 * (Math.PI / 180);

		// right
		this._cameraR.position.copy(this._position);
		this._cameraR.quaternion.copy(this._quaternion);
		this._cameraR.translateX(this.cameraDistance);
		this._cameraR.lookAt(scene.position);
		this._cameraR.rotation.x += 90 * (Math.PI / 180);
	}
}