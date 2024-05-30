import three.Euler;
import three.EventDispatcher;
import three.Vector3;

class PointerLockControls extends EventDispatcher {

    var camera:Camera;
    var domElement:Dynamic;
    var isLocked:Bool = false;
    var minPolarAngle:Float = 0;
    var maxPolarAngle:Float = Math.PI;
    var pointerSpeed:Float = 1.0;
    var _euler:Euler = new Euler(0, 0, 0, 'YXZ');
    var _vector:Vector3 = new Vector3();
    var _changeEvent:Dynamic = { type: 'change' };
    var _lockEvent:Dynamic = { type: 'lock' };
    var _unlockEvent:Dynamic = { type: 'unlock' };
    var _PI_2:Float = Math.PI / 2;
    var _onMouseMove:Dynamic;
    var _onPointerlockChange:Dynamic;
    var _onPointerlockError:Dynamic;

    public function new(camera:Camera, domElement:Dynamic) {
        super();
        this.camera = camera;
        this.domElement = domElement;
        this._onMouseMove = onMouseMove.bind(this);
        this._onPointerlockChange = onPointerlockChange.bind(this);
        this._onPointerlockError = onPointerlockError.bind(this);
        this.connect();
    }

    public function connect() {
        this.domElement.ownerDocument.addEventListener('mousemove', this._onMouseMove);
        this.domElement.ownerDocument.addEventListener('pointerlockchange', this._onPointerlockChange);
        this.domElement.ownerDocument.addEventListener('pointerlockerror', this._onPointerlockError);
    }

    public function disconnect() {
        this.domElement.ownerDocument.removeEventListener('mousemove', this._onMouseMove);
        this.domElement.ownerDocument.removeEventListener('pointerlockchange', this._onPointerlockChange);
        this.domElement.ownerDocument.removeEventListener('pointerlockerror', this._onPointerlockError);
    }

    public function dispose() {
        this.disconnect();
    }

    public function getObject():Camera {
        return this.camera;
    }

    public function getDirection(v:Vector3):Vector3 {
        return v.set(0, 0, -1).applyQuaternion(this.camera.quaternion);
    }

    public function moveForward(distance:Float) {
        var camera = this.camera;
        _vector.setFromMatrixColumn(camera.matrix, 0).crossVectors(camera.up, _vector).addScaledVector(_vector, distance);
    }

    public function moveRight(distance:Float) {
        var camera = this.camera;
        _vector.setFromMatrixColumn(camera.matrix, 0).addScaledVector(_vector, distance);
    }

    public function lock() {
        this.domElement.requestPointerLock();
    }

    public function unlock() {
        this.domElement.ownerDocument.exitPointerLock();
    }

    function onMouseMove(event:Dynamic) {
        if (this.isLocked == false) return;
        var movementX = event.movementX || event.mozMovementX || event.webkitMovementX || 0;
        var movementY = event.movementY || event.mozMovementY || event.webkitMovementY || 0;
        var camera = this.camera;
        _euler.setFromQuaternion(camera.quaternion);
        _euler.y -= movementX * 0.002 * this.pointerSpeed;
        _euler.x -= movementY * 0.002 * this.pointerSpeed;
        _euler.x = Math.max(_PI_2 - this.maxPolarAngle, Math.min(_PI_2 - this.minPolarAngle, _euler.x));
        camera.quaternion.setFromEuler(_euler);
        this.dispatchEvent(_changeEvent);
    }

    function onPointerlockChange() {
        if (this.domElement.ownerDocument.pointerLockElement == this.domElement) {
            this.dispatchEvent(_lockEvent);
            this.isLocked = true;
        } else {
            this.dispatchEvent(_unlockEvent);
            this.isLocked = false;
        }
    }

    function onPointerlockError() {
        trace('THREE.PointerLockControls: Unable to use Pointer Lock API');
    }
}