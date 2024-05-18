package three.js.examples.jsm.controls;

import three.Euler;
import three.EventDispatcher;
import three.Vector3;

class PointerLockControls extends EventDispatcher {
    private var camera:three.Camera;
    private var domElement:js.html.Element;
    private var isLocked:Bool;
    private var minPolarAngle:Float;
    private var maxPolarAngle:Float;
    private var pointerSpeed:Float;
    private var _onMouseMove:(e:js.html.MouseEvent)->Void;
    private var _onPointerlockChange:(e:js.html.Event)->Void;
    private var _onPointerlockError:(e:js.html.Event)->Void;
    private var _euler:Euler;
    private var _vector:Vector3;
    private var _changeEvent:{type:String};
    private var _lockEvent:{type:String};
    private var _unlockEvent:{type:String};
    private var _PI_2:Float;

    public function new(camera:three.Camera, domElement:js.html.Element) {
        super();
        this.camera = camera;
        this.domElement = domElement;
        this.isLocked = false;
        this.minPolarAngle = 0; // radians
        this.maxPolarAngle = Math.PI; // radians
        this.pointerSpeed = 1.0;
        this._euler = new Euler(0, 0, 0, 'YXZ');
        this._vector = new Vector3();
        this._changeEvent = {type: 'change'};
        this._lockEvent = {type: 'lock'};
        this._unlockEvent = {type: 'unlock'};
        this._PI_2 = Math.PI / 2;
        this._onMouseMove = onMouseMove.bind(this);
        this._onPointerlockChange = onPointerlockChange.bind(this);
        this._onPointerlockError = onPointerlockError.bind(this);
        this.connect();
    }

    private function connect():Void {
        domElement.ownerDocument.addEventListener('mousemove', _onMouseMove);
        domElement.ownerDocument.addEventListener('pointerlockchange', _onPointerlockChange);
        domElement.ownerDocument.addEventListener('pointerlockerror', _onPointerlockError);
    }

    private function disconnect():Void {
        domElement.ownerDocument.removeEventListener('mousemove', _onMouseMove);
        domElement.ownerDocument.removeEventListener('pointerlockchange', _onPointerlockChange);
        domElement.ownerDocument.removeEventListener('pointerlockerror', _onPointerlockError);
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
        var _vector:Vector3 = new Vector3();
        _vector.setFromMatrixColumn(camera.matrix, 0);
        _vector.crossVectors(camera.up, _vector);
        camera.position.addScaledVector(_vector, distance);
    }

    public function moveRight(distance:Float):Void {
        var _vector:Vector3 = new Vector3();
        _vector.setFromMatrixColumn(camera.matrix, 0);
        camera.position.addScaledVector(_vector, distance);
    }

    public function lock():Void {
        domElement.requestPointerLock();
    }

    public function unlock():Void {
        domElement.ownerDocument.exitPointerLock();
    }

    private function onMouseMove(event:js.html.MouseEvent):Void {
        if (!isLocked) return;
        var movementX:Float = event.movementX || event.mozMovementX || event.webkitMovementX || 0;
        var movementY:Float = event.movementY || event.mozMovementY || event.webkitMovementY || 0;
        _euler.setFromQuaternion(camera.quaternion);
        _euler.y -= movementX * 0.002 * pointerSpeed;
        _euler.x -= movementY * 0.002 * pointerSpeed;
        _euler.x = Math.max(_PI_2 - maxPolarAngle, Math.min(_PI_2 - minPolarAngle, _euler.x));
        camera.quaternion.setFromEuler(_euler);
        dispatchEvent(_changeEvent);
    }

    private function onPointerlockChange(event:js.html.Event):Void {
        if (domElement.ownerDocument.pointerLockElement == domElement) {
            dispatchEvent(_lockEvent);
            isLocked = true;
        } else {
            dispatchEvent(_unlockEvent);
            isLocked = false;
        }
    }

    private function onPointerlockError(event:js.html.Event):Void {
        js.Lib.debug('THREE.PointerLockControls: Unable to use Pointer Lock API');
    }
}