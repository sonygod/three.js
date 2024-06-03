import js.three.EventDispatcher;
import js.three.Quaternion;
import js.three.Vector3;

class FlyControls extends EventDispatcher {
    private var _changeEvent:Dynamic = { type: 'change' };

    private var object:Dynamic;
    private var domElement:Dynamic;

    public var enabled:Bool = true;
    public var movementSpeed:Float = 1.0;
    public var rollSpeed:Float = 0.005;
    public var dragToLook:Bool = false;
    public var autoForward:Bool = false;

    private var lastQuaternion:Quaternion = new Quaternion();
    private var lastPosition:Vector3 = new Vector3();
    public var tmpQuaternion:Quaternion = new Quaternion();

    public var status:Int = 0;
    public var moveState:Dynamic = { up: 0, down: 0, left: 0, right: 0, forward: 0, back: 0, pitchUp: 0, pitchDown: 0, yawLeft: 0, yawRight: 0, rollLeft: 0, rollRight: 0 };
    public var moveVector:Vector3 = new Vector3( 0, 0, 0 );
    public var rotationVector:Vector3 = new Vector3( 0, 0, 0 );

    private var movementSpeedMultiplier:Float = 1;

    public function new(object:Dynamic, domElement:Dynamic) {
        super();

        this.object = object;
        this.domElement = domElement;

        const EPS = 0.000001;

        this.domElement.addEventListener('contextmenu', [this, contextMenu]);
        this.domElement.addEventListener('pointerdown', [this, pointerdown]);
        this.domElement.addEventListener('pointermove', [this, pointermove]);
        this.domElement.addEventListener('pointerup', [this, pointerup]);
        this.domElement.addEventListener('pointercancel', [this, pointercancel]);

        js.Browser.window.addEventListener('keydown', [this, keydown]);
        js.Browser.window.addEventListener('keyup', [this, keyup]);

        updateMovementVector();
        updateRotationVector();
    }

    private function keydown(event:KeyboardEvent) {
        if (event.altKey || !this.enabled) return;

        switch (event.code) {
            case 'ShiftLeft':
            case 'ShiftRight':
                this.movementSpeedMultiplier = .1;
                break;
            // ... rest of your cases
        }

        updateMovementVector();
        updateRotationVector();
    }

    private function keyup(event:KeyboardEvent) {
        if (!this.enabled) return;

        switch (event.code) {
            case 'ShiftLeft':
            case 'ShiftRight':
                this.movementSpeedMultiplier = 1;
                break;
            // ... rest of your cases
        }

        updateMovementVector();
        updateRotationVector();
    }

    private function pointerdown(event:PointerEvent) {
        if (!this.enabled) return;

        if (this.dragToLook) {
            this.status++;
        } else {
            switch (event.button) {
                case 0: this.moveState.forward = 1; break;
                case 2: this.moveState.back = 1; break;
            }

            updateMovementVector();
        }
    }

    private function pointermove(event:PointerEvent) {
        if (!this.enabled) return;

        if (!this.dragToLook || this.status > 0) {
            const container = getContainerDimensions();
            const halfWidth = container.size[0] / 2;
            const halfHeight = container.size[1] / 2;

            this.moveState.yawLeft = -((event.pageX - container.offset[0]) - halfWidth) / halfWidth;
            this.moveState.pitchDown = ((event.pageY - container.offset[1]) - halfHeight) / halfHeight;

            updateRotationVector();
        }
    }

    private function pointerup(event:PointerEvent) {
        if (!this.enabled) return;

        if (this.dragToLook) {
            this.status--;
            this.moveState.yawLeft = this.moveState.pitchDown = 0;
        } else {
            switch (event.button) {
                case 0: this.moveState.forward = 0; break;
                case 2: this.moveState.back = 0; break;
            }

            updateMovementVector();
        }

        updateRotationVector();
    }

    private function pointercancel() {
        if (!this.enabled) return;

        if (this.dragToLook) {
            this.status = 0;
            this.moveState.yawLeft = this.moveState.pitchDown = 0;
        } else {
            this.moveState.forward = 0;
            this.moveState.back = 0;
            updateMovementVector();
        }

        updateRotationVector();
    }

    private function contextMenu(event:MouseEvent) {
        if (!this.enabled) return;
        event.preventDefault();
    }

    public function update(delta:Float) {
        if (!this.enabled) return;

        const moveMult = delta * this.movementSpeed;
        const rotMult = delta * this.rollSpeed;

        this.object.translateX(this.moveVector.x * moveMult);
        this.object.translateY(this.moveVector.y * moveMult);
        this.object.translateZ(this.moveVector.z * moveMult);

        this.tmpQuaternion.set(this.rotationVector.x * rotMult, this.rotationVector.y * rotMult, this.rotationVector.z * rotMult, 1).normalize();
        this.object.quaternion.multiply(this.tmpQuaternion);

        if (
            lastPosition.distanceToSquared(this.object.position) > EPS ||
            8 * (1 - lastQuaternion.dot(this.object.quaternion)) > EPS
        ) {
            this.dispatchEvent(_changeEvent);
            lastQuaternion.copy(this.object.quaternion);
            lastPosition.copy(this.object.position);
        }
    }

    private function updateMovementVector() {
        const forward = (this.moveState.forward || (this.autoForward && !this.moveState.back)) ? 1 : 0;

        this.moveVector.x = (-this.moveState.left + this.moveState.right);
        this.moveVector.y = (-this.moveState.down + this.moveState.up);
        this.moveVector.z = (-forward + this.moveState.back);
    }

    private function updateRotationVector() {
        this.rotationVector.x = (-this.moveState.pitchDown + this.moveState.pitchUp);
        this.rotationVector.y = (-this.moveState.yawRight + this.moveState.yawLeft);
        this.rotationVector.z = (-this.moveState.rollRight + this.moveState.rollLeft);
    }

    private function getContainerDimensions():Dynamic {
        if (this.domElement != js.Browser.document) {
            return {
                size: [this.domElement.offsetWidth, this.domElement.offsetHeight],
                offset: [this.domElement.offsetLeft, this.domElement.offsetTop]
            };
        } else {
            return {
                size: [js.Browser.window.innerWidth, js.Browser.window.innerHeight],
                offset: [0, 0]
            };
        }
    }

    public function dispose() {
        this.domElement.removeEventListener('contextmenu', [this, contextMenu]);
        this.domElement.removeEventListener('pointerdown', [this, pointerdown]);
        this.domElement.removeEventListener('pointermove', [this, pointermove]);
        this.domElement.removeEventListener('pointerup', [this, pointerup]);
        this.domElement.removeEventListener('pointercancel', [this, pointercancel]);

        js.Browser.window.removeEventListener('keydown', [this, keydown]);
        js.Browser.window.removeEventListener('keyup', [this, keyup]);
    }
}