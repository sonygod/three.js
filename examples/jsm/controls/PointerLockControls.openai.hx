package three.js.examples.jsm.controls;

import three.Euler;
import three.EventDispatcher;
import three.Vector3;
import Math.PI;

class PointerLockControls extends EventDispatcher {
    var camera:three.Camera;
    var domElement:js.html.Element;

    var isLocked:Bool = false;

    var minPolarAngle:Float = 0; // radians
    var maxPolarAngle:Float = Math.PI; // radians

    var pointerSpeed:Float = 1.0;

    var _euler:Euler = new Euler(0, 0, 0, 'YXZ');
    var _vector:Vector3 = new Vector3();

    var _changeEvent:{type:String} = { type: 'change' };
    var _lockEvent:{type:String} = { type: 'lock' };
    var _unlockEvent:{type:String} = { type: 'unlock' };

    var _PI_2:Float = Math.PI / 2;

    public function new(camera:three.Camera, domElement:js.html.Element) {
        super();
        this.camera = camera;
        this.domElement = domElement;

        this.connect();
    }

    function connect() {
        domElement.ownerDocument.addEventListener('mousemove', onMouseMove);
        domElement.ownerDocument.addEventListener('pointerlockchange', onPointerlockChange);
        domElement.ownerDocument.addEventListener('pointerlockerror', onPointerlockError);
    }

    function disconnect() {
        domElement.ownerDocument.removeEventListener('mousemove', onMouseMove);
        domElement.ownerDocument.removeEventListener('pointerlockchange', onPointerlockChange);
        domElement.ownerDocument.removeEventListener('pointerlockerror', onPointerlockError);
    }

    function dispose() {
        disconnect();
    }

    function getObject():three.Camera {
        return camera;
    }

    function getDirection(v:Vector3):Vector3 {
        return v.set(0, 0, -1).applyQuaternion(camera.quaternion);
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

    function onMouseMove(event:js.html.MouseEvent) {
        if (!isLocked) return;

        var movementX:Int = event.movementX != null ? event.movementX : event.mozMovementX != null ? event.mozMovementX : event.webkitMovementX != null ? event.webkitMovementX : 0;
        var movementY:Int = event.movementY != null ? event.movementY : event.mozMovementY != null ? event.mozMovementY : event.webkitMovementY != null ? event.webkitMovementY : 0;

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
        js.Lib.debug('THREE.PointerLockControls: Unable to use Pointer Lock API');
    }
}