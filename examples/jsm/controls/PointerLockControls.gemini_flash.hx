import three.Euler;
import three.Vector3;
import three.events.EventDispatcher;

class PointerLockControls extends EventDispatcher {

	public var camera(get, never):three.Camera;
	public var domElement:js.html.Element;
	public var isLocked(get, never):Bool;
	public var minPolarAngle:Float;
	public var maxPolarAngle:Float;
	public var pointerSpeed:Float;

	static var _euler = new Euler(0, 0, 0, "YXZ");
	static var _vector = new Vector3();

	static var _changeEvent = { type: "change" };
	static var _lockEvent = { type: "lock" };
	static var _unlockEvent = { type: "unlock" };

	static var _PI_2 = Math.PI / 2;

	var _onMouseMove:Void->Void;
	var _onPointerlockChange:Void->Void;
	var _onPointerlockError:Void->Void;

	public function new(camera:three.Camera, domElement:js.html.Element) {
		super();

		this.camera = camera;
		this.domElement = domElement;

		this.isLocked = false;

		this.minPolarAngle = 0;
		this.maxPolarAngle = Math.PI;

		this.pointerSpeed = 1.0;

		this._onMouseMove = onMouseMove.bind(this);
		this._onPointerlockChange = onPointerlockChange.bind(this);
		this._onPointerlockError = onPointerlockError.bind(this);

		connect();
	}

	function get_camera():three.Camera {
		return cast camera;
	}

	function get_isLocked():Bool {
		return isLocked;
	}

	public function connect():Void {
		domElement.ownerDocument.addEventListener("mousemove", _onMouseMove);
		domElement.ownerDocument.addEventListener("pointerlockchange", _onPointerlockChange);
		domElement.ownerDocument.addEventListener("pointerlockerror", _onPointerlockError);
	}

	public function disconnect():Void {
		domElement.ownerDocument.removeEventListener("mousemove", _onMouseMove);
		domElement.ownerDocument.removeEventListener("pointerlockchange", _onPointerlockChange);
		domElement.ownerDocument.removeEventListener("pointerlockerror", _onPointerlockError);
	}

	public function dispose():Void {
		disconnect();
	}

	public function getObject():three.Camera {
		return camera;
	}

	public function getDirection(v:Vector3):Vector3 {
		return v.set(0, 0, -1).applyQuaternion(camera.quaternion);
	}

	public function moveForward(distance:Float):Void {
		// move forward parallel to the xz-plane
		// assumes camera.up is y-up

		_vector.setFromMatrixColumn(camera.matrix, 0);

		_vector.crossVectors(camera.up, _vector);

		camera.position.addScaledVector(_vector, distance);
	}

	public function moveRight(distance:Float):Void {
		_vector.setFromMatrixColumn(camera.matrix, 0);

		camera.position.addScaledVector(_vector, distance);
	}

	public function lock():Void {
		domElement.requestPointerLock();
	}

	public function unlock():Void {
		domElement.ownerDocument.exitPointerLock();
	}

	function onMouseMove(event:js.html.MouseEvent):Void {
		if (!isLocked)
			return;

		var movementX = event.movementX;
		var movementY = event.movementY;

		_euler.setFromQuaternion(camera.quaternion);

		_euler.y -= movementX * 0.002 * pointerSpeed;
		_euler.x -= movementY * 0.002 * pointerSpeed;

		_euler.x = Math.max(_PI_2 - maxPolarAngle, Math.min(_PI_2 - minPolarAngle, _euler.x));

		camera.quaternion.setFromEuler(_euler);

		dispatchEvent(_changeEvent);
	}

	function onPointerlockChange():Void {
		if (domElement.ownerDocument.pointerLockElement == domElement) {
			dispatchEvent(_lockEvent);

			isLocked = true;
		} else {
			dispatchEvent(_unlockEvent);

			isLocked = false;
		}
	}

	function onPointerlockError():Void {
		js.Lib.console.error("THREE.PointerLockControls: Unable to use Pointer Lock API");
	}
}