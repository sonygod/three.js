import three.PerspectiveCamera;
import three.Quaternion;
import three.Vector3;

/**
 * peppers ghost effect based on http://www.instructables.com/id/Reflective-Prism/?ALLSTEPS
 */
class PeppersGhostEffect {

	public var cameraDistance:Float;
	public var reflectFromAbove:Bool;

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

	public function new(renderer:Dynamic) {

		this.cameraDistance = 15;
		this.reflectFromAbove = false;

		// Internals
		_halfWidth = 0;
		_width = 0;
		_height = 0;

		_cameraF = new PerspectiveCamera(); //front
		_cameraB = new PerspectiveCamera(); //back
		_cameraL = new PerspectiveCamera(); //left
		_cameraR = new PerspectiveCamera(); //right

		_position = new Vector3();
		_quaternion = new Quaternion();
		_scale = new Vector3();

		// Initialization
		js.html.Window.document.getElementById("renderer").style.clear = "none";

		this.setSize = function (width:Float, height:Float) {

			_halfWidth = width / 2;
			if (width < height) {

				_width = width / 3;
				_height = width / 3;

			} else {

				_width = height / 3;
				_height = height / 3;

			}

			renderer.setSize(width, height);

		};

		this.render = function (scene:Dynamic, camera:Dynamic) {

			if (scene.matrixWorldAutoUpdate == true) scene.updateMatrixWorld();

			if (camera.parent == null && camera.matrixWorldAutoUpdate == true) camera.updateMatrixWorld();

			camera.matrixWorld.decompose(_position, _quaternion, _scale);

			// front
			_cameraF.position.copy(_position);
			_cameraF.quaternion.copy(_quaternion);
			_cameraF.translateZ(this.cameraDistance);
			_cameraF.lookAt(scene.position);

			// back
			_cameraB.position.copy(_position);
			_cameraB.quaternion.copy(_quaternion);
			_cameraB.translateZ(-(this.cameraDistance));
			_cameraB.lookAt(scene.position);
			_cameraB.rotation.z += 180 * (Math.PI / 180);

			// left
			_cameraL.position.copy(_position);
			_cameraL.quaternion.copy(_quaternion);
			_cameraL.translateX(-(this.cameraDistance));
			_cameraL.lookAt(scene.position);
			_cameraL.rotation.x += 90 * (Math.PI / 180);

			// right
			_cameraR.position.copy(_position);
			_cameraR.quaternion.copy(_quaternion);
			_cameraR.translateX(this.cameraDistance);
			_cameraR.lookAt(scene.position);
			_cameraR.rotation.x += 90 * (Math.PI / 180);


			renderer.clear();
			renderer.setScissorTest(true);

			renderer.setScissor(_halfWidth - (_width / 2), (_height * 2), _width, _height);
			renderer.setViewport(_halfWidth - (_width / 2), (_height * 2), _width, _height);

			if (this.reflectFromAbove) {

				renderer.render(scene, _cameraB);

			} else {

				renderer.render(scene, _cameraF);

			}

			renderer.setScissor(_halfWidth - (_width / 2), 0, _width, _height);
			renderer.setViewport(_halfWidth - (_width / 2), 0, _width, _height);

			if (this.reflectFromAbove) {

				renderer.render(scene, _cameraF);

			} else {

				renderer.render(scene, _cameraB);

			}

			renderer.setScissor(_halfWidth - (_width / 2) - _width, _height, _width, _height);
			renderer.setViewport(_halfWidth - (_width / 2) - _width, _height, _width, _height);

			if (this.reflectFromAbove) {

				renderer.render(scene, _cameraR);

			} else {

				renderer.render(scene, _cameraL);

			}

			renderer.setScissor(_halfWidth + (_width / 2), _height, _width, _height);
			renderer.setViewport(_halfWidth + (_width / 2), _height, _width, _height);

			if (this.reflectFromAbove) {

				renderer.render(scene, _cameraL);

			} else {

				renderer.render(scene, _cameraR);

			}

			renderer.setScissorTest(false);

		};

	}

}