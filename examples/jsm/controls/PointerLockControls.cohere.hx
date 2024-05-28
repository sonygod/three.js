import js.three.Euler;
import js.three.EventDispatcher;
import js.three.Vector3;

class PointerLockControls extends EventDispatcher {
    var _euler:Euler;
    var _vector:Vector3;
    var _changeEvent:Dynamic;
    var _lockEvent:Dynamic;
    var _unlockEvent:Dynamic;
    var _PI_2:Float;
    var _onMouseMove:Function;
    var _onPointerlockChange:Function;
    var _onPointerlockError:Function;
    var isLocked:Bool;
    var minPolarAngle:Float;
    var maxPolarAngle:Float;
    var pointerSpeed:Float;
    var camera:Dynamic;
    var domElement:Dynamic;

    public function new(camera:Dynamic, domElement:Dynamic) {
        super();
        _euler = new Euler(0., 0., 0., "YXZ");
        _vector = new Vector3();
        _changeEvent = { type: "change" };
        _lockEvent = { type: "lock" };
        _unlockEvent = { type: "unlock" };
        _PI_2 = Std.PI / 2.;
        _onMouseMove = bind(onMouseMove, this);
        _onPointerlockChange = bind(onPointerlockChange, this);
        _onPointerlockError = bind(onPointerlockError, this);
        this.camera = camera;
        this.domElement = domElement;
        isLocked = false;
        minPolarAngle = 0.;
        maxPolarAngle = Std.PI;
        pointerSpeed = 1.;
        connect();
    }

    function connect() {
        domElement.ownerDocument.addEventListener("mousemove", _onMouseMove);
        domElement.ownerDocument.addEventListener("pointerlockchange", _onPointerlockChange);
        domElement.ownerDocument.addEventListener("pointerlockerror", _onPointerlockError);
    }

    function disconnect() {
        domElement.ownerDocument.removeEventListener("mousemove", _onMouseMove);
        domElement.ownerDocument.removeEventListener("pointerlockchange", _onPointerlockChange);
        domElement.ownerDocument.removeEventListener("pointerlockerror", _onPointerlockError);
    }

    function dispose() {
        disconnect();
    }

    function getObject():Dynamic {
        return camera;
    }

    function getDirection(v:Vector3):Vector3 {
        return v.set(0., 0., -1.).applyQuaternion(camera.quaternion);
    }

    function moveForward(distance:Float) {
        var camera = this.camera;
        _vector.setFromMatrixColumn(camera.matrix, 0);
        _vector.crossVectors(camera.up, _vector);
        camera.position.addScaledVector(_vector, distance);
    }

    function moveRight(distance:Float) {
        var camera = this.camera;
        _vector.setFromMatrixColumn(camera.matrix, 0);
        camera.position.addScaledVector(_vector, distance);
    }

    function lock() {
        domElement.requestPointerLock();
    }

    function unlock() {
        domElement.ownerDocument.exitPointerLock();
    }

    function onMouseMove(event:Dynamic) {
        if (!isLocked) return;
        var movementX = event.movementX ?? event.mozMovementX ?? event.webkitMovementX ?? 0.;
        var movementY = event.movementY ?? event.mozMovementY ?? event.webkitMovementY ?? 0.;
        var camera = this.camera;
        _euler.setFromQuaternion(camera.quaternion);
        _euler.y -= movementX * 0.002 * pointerSpeed;
        _euler.x -= movementY * 0.002 * pointerSpeed;
        _euler.x = Math.max(_PI_2 - maxPolarAngle, Math.min(_PI_2 - minPolarAngle, _euler.x));
        camera.quaternion.setFromEuler(_euler);
        dispatchEvent(_changeEvent);
    }

    function onPointerlockChange() {
        if (domElement.ownerDocument.pointerLockElement == domElement) {
            dispatchEvent(_lockEvent);
            isLocked = true;
        } else {
            dispatchEvent(_unlockEvent);
            isLocked = false;
        }
    }

    function onPointerlockError() {
        trace("THREE.PointerLockControls: Unable to use Pointer Lock API");
    }
}