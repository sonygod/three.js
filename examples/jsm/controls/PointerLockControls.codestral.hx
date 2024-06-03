import three.Euler;
import three.EventDispatcher;
import three.Vector3;

class PointerLockControls extends EventDispatcher {
    private var _euler:Euler = new Euler(0, 0, 0, 'YXZ');
    private var _vector:Vector3 = new Vector3();
    private var _changeEvent:Dynamic = { type: 'change' };
    private var _lockEvent:Dynamic = { type: 'lock' };
    private var _unlockEvent:Dynamic = { type: 'unlock' };
    private var _PI_2:Float = Math.PI / 2;

    public var camera:three.Camera;
    public var domElement:js.html.Element;
    public var isLocked:Bool;
    public var minPolarAngle:Float;
    public var maxPolarAngle:Float;
    public var pointerSpeed:Float;

    public function new(camera:three.Camera, domElement:js.html.Element) {
        super();
        this.camera = camera;
        this.domElement = domElement;
        this.isLocked = false;
        this.minPolarAngle = 0;
        this.maxPolarAngle = Math.PI;
        this.pointerSpeed = 1.0;
        this.connect();
    }

    public function connect():Void {
        this.domElement.ownerDocument.addEventListener('mousemove', this._onMouseMove.bind(this));
        this.domElement.ownerDocument.addEventListener('pointerlockchange', this._onPointerlockChange.bind(this));
        this.domElement.ownerDocument.addEventListener('pointerlockerror', this._onPointerlockError.bind(this));
    }

    public function disconnect():Void {
        this.domElement.ownerDocument.removeEventListener('mousemove', this._onMouseMove.bind(this));
        this.domElement.ownerDocument.removeEventListener('pointerlockchange', this._onPointerlockChange.bind(this));
        this.domElement.ownerDocument.removeEventListener('pointerlockerror', this._onPointerlockError.bind(this));
    }

    public function dispose():Void {
        this.disconnect();
    }

    public function getObject():three.Camera {
        return this.camera;
    }

    public function getDirection(v:Vector3):Vector3 {
        return v.set(0, 0, -1).applyQuaternion(this.camera.quaternion);
    }

    public function moveForward(distance:Float):Void {
        _vector.setFromMatrixColumn(this.camera.matrix, 0);
        _vector.crossVectors(this.camera.up, _vector);
        this.camera.position.addScaledVector(_vector, distance);
    }

    public function moveRight(distance:Float):Void {
        _vector.setFromMatrixColumn(this.camera.matrix, 0);
        this.camera.position.addScaledVector(_vector, distance);
    }

    public function lock():Void {
        this.domElement.requestPointerLock();
    }

    public function unlock():Void {
        this.domElement.ownerDocument.exitPointerLock();
    }

    private function _onMouseMove(event:Dynamic):Void {
        if (this.isLocked === false) return;

        var movementX = event.movementX || event.mozMovementX || event.webkitMovementX || 0;
        var movementY = event.movementY || event.mozMovementY || event.webkitMovementY || 0;

        _euler.setFromQuaternion(this.camera.quaternion);
        _euler.y -= movementX * 0.002 * this.pointerSpeed;
        _euler.x -= movementY * 0.002 * this.pointerSpeed;
        _euler.x = Math.max(_PI_2 - this.maxPolarAngle, Math.min(_PI_2 - this.minPolarAngle, _euler.x));
        this.camera.quaternion.setFromEuler(_euler);
        this.dispatchEvent(_changeEvent);
    }

    private function _onPointerlockChange():Void {
        if (this.domElement.ownerDocument.pointerLockElement === this.domElement) {
            this.dispatchEvent(_lockEvent);
            this.isLocked = true;
        } else {
            this.dispatchEvent(_unlockEvent);
            this.isLocked = false;
        }
    }

    private function _onPointerlockError():Void {
        js.Browser.console.error('THREE.PointerLockControls: Unable to use Pointer Lock API');
    }
}