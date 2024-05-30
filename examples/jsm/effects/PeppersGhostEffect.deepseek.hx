import three.PerspectiveCamera;
import three.Quaternion;
import three.Vector3;

/**
 * peppers ghost effect based on http://www.instructables.com/id/Reflective-Prism/?ALLSTEPS
 */

class PeppersGhostEffect {

	var cameraDistance:Float = 15;
	var reflectFromAbove:Bool = false;

	var _halfWidth:Float;
	var _width:Float;
	var _height:Float;

	var _cameraF:PerspectiveCamera; //front
	var _cameraB:PerspectiveCamera; //back
	var _cameraL:PerspectiveCamera; //left
	var _cameraR:PerspectiveCamera; //right

	var _position:Vector3;
	var _quaternion:Quaternion;
	var _scale:Vector3;

	public function new(renderer:Renderer) {

		renderer.autoClear = false;

		_cameraF = new PerspectiveCamera(); //front
		_cameraB = new PerspectiveCamera(); //back
		_cameraL = new PerspectiveCamera(); //left
		_cameraR = new PerspectiveCamera(); //right

		_position = new Vector3();
		_quaternion = new Quaternion();
		_scale = new Vector3();

	}

	public function setSize(width:Float, height:Float) {

		_halfWidth = width / 2;
		if (width < height) {

			_width = width / 3;
			_height = width / 3;

		} else {

			_width = height / 3;
			_height = height / 3;

		}

		renderer.setSize(width, height);

	}

	public function render(scene:Scene, camera:Camera) {

		if (scene.matrixWorldAutoUpdate == true) scene.updateMatrixWorld();

		if (camera.parent == null && camera.matrixWorldAutoUpdate == true) camera.updateMatrixWorld();

		camera.matrixWorld.decompose(_position, _quaternion, _scale);

		// front
		_cameraF.position.copy(_position);
		_cameraF.quaternion.copy(_quaternion);
		_cameraF.translateZ(cameraDistance);
		_cameraF.lookAt(scene.position);

		// back
		_cameraB.position.copy(_position);
		_cameraB.quaternion.copy(_quaternion);
		_cameraB.translateZ(-(cameraDistance));
		_cameraB.lookAt(scene.position);
		_cameraB.rotation.z += 180 * (Math.PI / 180);

		// left
		_cameraL.position.copy(_position);
		_cameraL.quaternion.copy(_quaternion);
		_cameraL.translateX(-(cameraDistance));
		_cameraL.lookAt(scene.position);
		_cameraL.rotation.x += 90 * (Math.PI / 180);

		// right
		_cameraR.position.copy(_position);
		_cameraR.quaternion.copy(_quaternion);
		_cameraR.translateX(cameraDistance);
		_cameraR.lookAt(scene.position);
		_cameraR.rotation.x += 90 * (Math.PI / 180);


		renderer.clear();
		renderer.setScissorTest(true);

		renderer.setScissor(_halfWidth - (_width / 2), (_height * 2), _width, _height);
		renderer.setViewport(_halfWidth - (_width / 2), (_height * 2), _width, _height);

		if (reflectFromAbove) {

			renderer.render(scene, _cameraB);

		} else {

			renderer.render(scene, _cameraF);

		}

		renderer.setScissor(_halfWidth - (_width / 2), 0, _width, _height);
		renderer.setViewport(_halfWidth - (_width / 2), 0, _width, _height);

		if (reflectFromAbove) {

			renderer.render(scene, _cameraF);

		} else {

			renderer.render(scene, _cameraB);

		}

		renderer.setScissor(_halfWidth - (_width / 2) - _width, _height, _width, _height);
		renderer.setViewport(_halfWidth - (_width / 2) - _width, _height, _width, _height);

		if (reflectFromAbove) {

			renderer.render(scene, _cameraR);

		} else {

			renderer.render(scene, _cameraL);

		}

		renderer.setScissor(_halfWidth + (_width / 2), _height, _width, _height);
		renderer.setViewport(_halfWidth + (_width / 2), _height, _width, _height);

		if (reflectFromAbove) {

			renderer.render(scene, _cameraL);

		} else {

			renderer.render(scene, _cameraR);

		}

		renderer.setScissorTest(false);

	}

}