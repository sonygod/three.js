package three.js.examples.controls;

import three.EventDispatcher;
import three.Quaternion;
import three.Vector3;

class FlyControls extends EventDispatcher {
    public var object:Dynamic;
    public var domElement:Dynamic;

    public var enabled:Bool = true;
    public var movementSpeed:Float = 1.0;
    public var rollSpeed:Float = 0.005;
    public var dragToLook:Bool = false;
    public var autoForward:Bool = false;

    private var EPS:Float = 0.000001;

    private var lastQuaternion:Quaternion;
    private var lastPosition:Vector3;

    private var tmpQuaternion:Quaternion;
    private var moveState:Dynamic = {};
    private var moveVector:Vector3;
    private var rotationVector:Vector3;
    private var status:Int = 0;

    public function new(object:Dynamic, domElement:Dynamic) {
        super();

        this.object = object;
        this.domElement = domElement;

        lastQuaternion = new Quaternion();
        lastPosition = new Vector3();

        tmpQuaternion = new Quaternion();
        moveVector = new Vector3(0, 0, 0);
        rotationVector = new Vector3(0, 0, 0);

        moveState = {
            up: 0,
            down: 0,
            left: 0,
            right: 0,
            forward: 0,
            back: 0,
            pitchUp: 0,
            pitchDown: 0,
            yawLeft: 0,
            yawRight: 0,
            rollLeft: 0,
            rollRight: 0
        };

        _keydown = keydown.bind(this);
        _keyup = keyup.bind(this);
        _pointerdown = pointerdown.bind(this);
        _pointermove = pointermove.bind(this);
        _pointerup = pointerup.bind(this);
        _pointercancel = pointercancel.bind(this);
        _contextmenu = contextMenu.bind(this);

        domElement.addEventListener('contextmenu', _contextmenu);
        domElement.addEventListener('pointerdown', _pointerdown);
        domElement.addEventListener('pointermove', _pointermove);
        domElement.addEventListener('pointerup', _pointerup);
        domElement.addEventListener('pointercancel', _pointercancel);

        window.addEventListener('keydown', _keydown);
        window.addEventListener('keyup', _keyup);

        updateMovementVector();
        updateRotationVector();
    }

    private function keydown(event:Dynamic):Void {
        if (event.altKey || !enabled) return;

        switch (event.code) {
            case 'ShiftLeft', 'ShiftRight':
                movementSpeedMultiplier = 0.1;
                break;
            case 'KeyW':
                moveState.forward = 1;
                break;
            case 'KeyS':
                moveState.back = 1;
                break;
            case 'KeyA':
                moveState.left = 1;
                break;
            case 'KeyD':
                moveState.right = 1;
                break;
            case 'KeyR':
                moveState.up = 1;
                break;
            case 'KeyF':
                moveState.down = 1;
                break;
            case 'ArrowUp':
                moveState.pitchUp = 1;
                break;
            case 'ArrowDown':
                moveState.pitchDown = 1;
                break;
            case 'ArrowLeft':
                moveState.yawLeft = 1;
                break;
            case 'ArrowRight':
                moveState.yawRight = 1;
                break;
            case 'KeyQ':
                moveState.rollLeft = 1;
                break;
            case 'KeyE':
                moveState.rollRight = 1;
                break;
        }

        updateMovementVector();
        updateRotationVector();
    }

    private function keyup(event:Dynamic):Void {
        if (!enabled) return;

        switch (event.code) {
            case 'ShiftLeft', 'ShiftRight':
                movementSpeedMultiplier = 1;
                break;
            case 'KeyW':
                moveState.forward = 0;
                break;
            case 'KeyS':
                moveState.back = 0;
                break;
            case 'KeyA':
                moveState.left = 0;
                break;
            case 'KeyD':
                moveState.right = 0;
                break;
            case 'KeyR':
                moveState.up = 0;
                break;
            case 'KeyF':
                moveState.down = 0;
                break;
            case 'ArrowUp':
                moveState.pitchUp = 0;
                break;
            case 'ArrowDown':
                moveState.pitchDown = 0;
                break;
            case 'ArrowLeft':
                moveState.yawLeft = 0;
                break;
            case 'ArrowRight':
                moveState.yawRight = 0;
                break;
            case 'KeyQ':
                moveState.rollLeft = 0;
                break;
            case 'KeyE':
                moveState.rollRight = 0;
                break;
        }

        updateMovementVector();
        updateRotationVector();
    }

    private function pointerdown(event:Dynamic):Void {
        if (!enabled) return;

        if (dragToLook) {
            status++;
        } else {
            switch (event.button) {
                case 0:
                    moveState.forward = 1;
                    break;
                case 2:
                    moveState.back = 1;
                    break;
            }

            updateMovementVector();
        }
    }

    private function pointermove(event:Dynamic):Void {
        if (!enabled) return;

        if (!dragToLook || status > 0) {
            var container:Dynamic = getContainerDimensions();
            var halfWidth:Float = container.size[0] / 2;
            var halfHeight:Float = container.size[1] / 2;

            moveState.yawLeft = -((event.pageX - container.offset[0]) - halfWidth) / halfWidth;
            moveState.pitchDown = ((event.pageY - container.offset[1]) - halfHeight) / halfHeight;

            updateRotationVector();
        }
    }

    private function pointerup(event:Dynamic):Void {
        if (!enabled) return;

        if (dragToLook) {
            status--;
            moveState.yawLeft = moveState.pitchDown = 0;
        } else {
            switch (event.button) {
                case 0:
                    moveState.forward = 0;
                    break;
                case 2:
                    moveState.back = 0;
                    break;
            }

            updateMovementVector();
        }

        updateRotationVector();
    }

    private function pointercancel():Void {
        if (!enabled) return;

        if (dragToLook) {
            status = 0;
            moveState.yawLeft = moveState.pitchDown = 0;
        } else {
            moveState.forward = 0;
            moveState.back = 0;
            updateMovementVector();
        }

        updateRotationVector();
    }

    private function contextMenu(event:Dynamic):Void {
        if (!enabled) return;

        event.preventDefault();
    }

    private function update(delta:Float):Void {
        if (!enabled) return;

        var moveMult:Float = delta * movementSpeed;
        var rotMult:Float = delta * rollSpeed;

        object.translateX(moveVector.x * moveMult);
        object.translateY(moveVector.y * moveMult);
        object.translateZ(moveVector.z * moveMult);

        tmpQuaternion.set(rotationVector.x * rotMult, rotationVector.y * rotMult, rotationVector.z * rotMult, 1).normalize();
        object.quaternion.multiply(tmpQuaternion);

        if (lastPosition.distanceToSquared(object.position) > EPS || 8 * (1 - lastQuaternion.dot(object.quaternion)) > EPS) {
            dispatchEvent(_changeEvent);
            lastQuaternion.copy(object.quaternion);
            lastPosition.copy(object.position);
        }
    }

    private function updateMovementVector():Void {
        var forward:Int = (moveState.forward || (autoForward && !moveState.back)) ? 1 : 0;

        moveVector.x = (-moveState.left + moveState.right);
        moveVector.y = (-moveState.down + moveState.up);
        moveVector.z = (-forward + moveState.back);
    }

    private function updateRotationVector():Void {
        rotationVector.x = (-moveState.pitchDown + moveState.pitchUp);
        rotationVector.y = (-moveState.yawRight + moveState.yawLeft);
        rotationVector.z = (-moveState.rollRight + moveState.rollLeft);
    }

    private function getContainerDimensions():Dynamic {
        if (domElement != window.document) {
            return {
                size: [domElement.offsetWidth, domElement.offsetHeight],
                offset: [domElement.offsetLeft, domElement.offsetTop]
            };
        } else {
            return {
                size: [window.innerWidth, window.innerHeight],
                offset: [0, 0]
            };
        }
    }

    private function dispose():Void {
        domElement.removeEventListener('contextmenu', _contextmenu);
        domElement.removeEventListener('pointerdown', _pointerdown);
        domElement.removeEventListener('pointermove', _pointermove);
        domElement.removeEventListener('pointerup', _pointerup);
        domElement.removeEventListener('pointercancel', _pointercancel);

        window.removeEventListener('keydown', _keydown);
        window.removeEventListener('keyup', _keyup);
    }
}