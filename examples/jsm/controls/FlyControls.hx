package three.js.examples.jsm.controls;

import three.js.EventDispatcher;
import three.js.Quaternion;
import three.js.Vector3;

class FlyControls extends EventDispatcher {
    private var object:Object3D;
    private var domElement:HtmlDom;
    private var enabled:Bool = true;
    private var movementSpeed:Float = 1.0;
    private var rollSpeed:Float = 0.005;
    private var dragToLook:Bool = false;
    private var autoForward:Bool = false;
    private var EPS:Float = 0.000001;
    private var lastQuaternion:Quaternion;
    private var lastPosition:Vector3;
    private var tmpQuaternion:Quaternion;
    private var status:Int = 0;
    private var moveState:Dynamic = {
        up: 0, down: 0, left: 0, right: 0, forward: 0, back: 0, pitchUp: 0, pitchDown: 0, yawLeft: 0, yawRight: 0, rollLeft: 0, rollRight: 0
    };
    private var moveVector:Vector3;
    private var rotationVector:Vector3;

    public function new(object:Object3D, domElement:HtmlDom) {
        super();
        this.object = object;
        this.domElement = domElement;
        lastQuaternion = new Quaternion();
        lastPosition = new Vector3();
        tmpQuaternion = new Quaternion();
        moveVector = new Vector3(0, 0, 0);
        rotationVector = new Vector3(0, 0, 0);

        domElement.addEventListener('contextmenu', contextMenu);
        domElement.addEventListener('pointerdown', pointerDown);
        domElement.addEventListener('pointermove', pointerMove);
        domElement.addEventListener('pointerup', pointerUp);
        domElement.addEventListener('pointercancel', pointerCancel);

        js.Browser.window.addEventListener('keydown', keyDown);
        js.Browser.window.addEventListener('keyup', keyUp);

        updateMovementVector();
        updateRotationVector();
    }

    private function keyDown(event:js.html.KeyboardEvent) {
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

    private function keyUp(event:js.html.KeyboardEvent) {
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

    private function pointerDown(event:js.html.PointerEvent) {
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

    private function pointerMove(event:js.html.PointerEvent) {
        if (!enabled) return;
        if (!dragToLook || status > 0) {
            var container = getContainerDimensions();
            var halfWidth = container.size[0] / 2;
            var halfHeight = container.size[1] / 2;
            moveState.yawLeft = -((event.pageX - container.offset[0]) - halfWidth) / halfWidth;
            moveState.pitchDown = ((event.pageY - container.offset[1]) - halfHeight) / halfHeight;
            updateRotationVector();
        }
    }

    private function pointerUp(event:js.html.PointerEvent) {
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

    private function pointerCancel() {
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

    private function contextMenu(event:js.html.MouseEvent) {
        if (!enabled) return;
        event.preventDefault();
    }

    private function update(delta:Float) {
        if (!enabled) return;
        var moveMult = delta * movementSpeed;
        var rotMult = delta * rollSpeed;
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

    private function updateMovementVector() {
        var forward = (moveState.forward || (autoForward && !moveState.back)) ? 1 : 0;
        moveVector.x = -moveState.left + moveState.right;
        moveVector.y = -moveState.down + moveState.up;
        moveVector.z = -forward + moveState.back;
    }

    private function updateRotationVector() {
        rotationVector.x = -moveState.pitchDown + moveState.pitchUp;
        rotationVector.y = -moveState.yawRight + moveState.yawLeft;
        rotationVector.z = -moveState.rollRight + moveState.rollLeft;
    }

    private function getContainerDimensions():{ size:Array<Float>, offset:Array<Float> } {
        if (domElement != js.Browser.document) {
            return {
                size: [domElement.offsetWidth, domElement.offsetHeight],
                offset: [domElement.offsetLeft, domElement.offsetTop]
            };
        } else {
            return {
                size: [js.Browser.window.innerWidth, js.Browser.window.innerHeight],
                offset: [0, 0]
            };
        }
    }

    private function dispose() {
        domElement.removeEventListener('contextmenu', contextMenu);
        domElement.removeEventListener('pointerdown', pointerDown);
        domElement.removeEventListener('pointermove', pointerMove);
        domElement.removeEventListener('pointerup', pointerUp);
        domElement.removeEventListener('pointercancel', pointerCancel);

        js.Browser.window.removeEventListener('keydown', keyDown);
        js.Browser.window.removeEventListener('keyup', keyUp);
    }
}