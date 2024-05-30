import js.three.EventDispatcher;
import js.three.Quaternion;
import js.three.Vector3;

class FlyControls extends EventDispatcher {

    public var object:Dynamic;
    public var domElement:Dynamic;

    public var enabled:Bool = true;
    public var movementSpeed:Float = 1.0;
    public var rollSpeed:Float = 0.005;
    public var dragToLook:Bool = false;
    public var autoForward:Bool = false;

    private var lastQuaternion:Quaternion = new Quaternion();
    private var lastPosition:Vector3 = new Vector3();
    private var tmpQuaternion:Quaternion = new Quaternion();
    private var status:Int = 0;
    private var moveState:Map<String, Int> = new Map();
    private var moveVector:Vector3 = new Vector3(0, 0, 0);
    private var rotationVector:Vector3 = new Vector3(0, 0, 0);

    public function new(object:Dynamic, domElement:Dynamic) {
        super();
        this.object = object;
        this.domElement = domElement;

        moveState.set("up", 0);
        moveState.set("down", 0);
        moveState.set("left", 0);
        moveState.set("right", 0);
        moveState.set("forward", 0);
        moveState.set("back", 0);
        moveState.set("pitchUp", 0);
        moveState.set("pitchDown", 0);
        moveState.set("yawLeft", 0);
        moveState.set("yawRight", 0);
        moveState.set("rollLeft", 0);
        moveState.set("rollRight", 0);

        var _contextmenu = this.contextMenu.bind(this);
        var _pointermove = this.pointermove.bind(this);
        var _pointerdown = this.pointerdown.bind(this);
        var _pointerup = this.pointerup.bind(this);
        var _pointercancel = this.pointercancel.bind(this);
        var _keydown = this.keydown.bind(this);
        var _keyup = this.keyup.bind(this);

        this.domElement.addEventListener("contextmenu", _contextmenu);
        this.domElement.addEventListener("pointerdown", _pointerdown);
        this.domElement.addEventListener("pointermove", _pointermove);
        this.domElement.addEventListener("pointerup", _pointerup);
        this.domElement.addEventListener("pointercancel", _pointercancel);

        window.addEventListener("keydown", _keydown);
        window.addEventListener("keyup", _keyup);

        this.updateMovementVector();
        this.updateRotationVector();
    }

    private function keydown(event:Dynamic) {
        if (event.altKey || this.enabled == false) {
            return;
        }

        switch (event.code) {
            case "ShiftLeft":
            case "ShiftRight": this.movementSpeedMultiplier = .1; break;
            case "KeyW": this.moveState.set("forward", 1); break;
            case "KeyS": this.moveState.set("back", 1); break;
            case "KeyA": this.moveState.set("left", 1); break;
            case "KeyD": this.moveState.set("right", 1); break;
            case "KeyR": this.moveState.set("up", 1); break;
            case "KeyF": this.moveState.set("down", 1); break;
            case "ArrowUp": this.moveState.set("pitchUp", 1); break;
            case "ArrowDown": this.moveState.set("pitchDown", 1); break;
            case "ArrowLeft": this.moveState.set("yawLeft", 1); break;
            case "ArrowRight": this.moveState.set("yawRight", 1); break;
            case "KeyQ": this.moveState.set("rollLeft", 1); break;
            case "KeyE": this.moveState.set("rollRight", 1); break;
        }

        this.updateMovementVector();
        this.updateRotationVector();
    }

    private function keyup(event:Dynamic) {
        if (this.enabled == false) return;

        switch (event.code) {
            case "ShiftLeft":
            case "ShiftRight": this.movementSpeedMultiplier = 1; break;
            case "KeyW": this.moveState.set("forward", 0); break;
            case "KeyS": this.moveState.set("back", 0); break;
            case "KeyA": this.moveState.set("left", 0); break;
            case "KeyD": this.moveState.set("right", 0); break;
            case "KeyR": this.moveState.set("up", 0); break;
            case "KeyF": this.moveState.set("down", 0); break;
            case "ArrowUp": this.moveState.set("pitchUp", 0); break;
            case "ArrowDown": this.moveState.set("pitchDown", 0); break;
            case "ArrowLeft": this.moveState.set("yawLeft", 0); break;
            case "ArrowRight": this.moveState.set("yawRight", 0); break;
            case "KeyQ": this.moveState.set("rollLeft", 0); break;
            case "KeyE": this.moveState.set("rollRight", 0); break;
        }

        this.updateMovementVector();
        this.updateRotationVector();
    }

    private function pointerdown(event:Dynamic) {
        if (this.enabled == false) return;

        if (this.dragToLook) {
            this.status++;
        } else {
            switch (event.button) {
                case 0: this.moveState.set("forward", 1); break;
                case 2: this.moveState.set("back", 1); break;
            }
        }

        this.updateMovementVector();
    }

    private function pointermove(event:Dynamic) {
        if (this.enabled == false) return;

        if (!this.dragToLook || this.status > 0) {
            var container = this.getContainerDimensions();
            var halfWidth = container.size[0] / 2;
            var halfHeight = container.size[1] / 2;

            this.moveState.set("yawLeft", -((event.pageX - container.offset[0]) - halfWidth) / halfWidth);
            this.moveState.set("pitchDown", ((event.pageY - container.offset[1]) - halfHeight) / halfHeight);

            this.updateRotationVector();
        }
    }

    private function pointerup(event:Dynamic) {
        if (this.enabled == false) return;

        if (this.dragToLook) {
            this.status--;

            this.moveState.set("yawLeft", 0);
            this.moveState.set("pitchDown", 0);
        } else {
            switch (event.button) {
                case 0: this.moveState.set("forward", 0); break;
                case 2: this.moveState.set("back", 0); break;
            }
        }

        this.updateMovementVector();
        this.updateRotationVector();
    }

    private function pointercancel() {
        if (this.enabled == false) return;

        if (this.dragToLook) {
            this.status = 0;

            this.moveState.set("yawLeft", 0);
            this.moveState.set("pitchDown", 0);
        } else {
            this.moveState.set("forward", 0);
            this.moveState.set("back", 0);
        }

        this.updateMovementVector();
        this.updateRotationVector();
    }

    private function contextMenu(event:Dynamic) {
        if (this.enabled == false) return;

        event.preventDefault();
    }

    private function update(delta:Float) {
        if (this.enabled == false) return;

        var moveMult = delta * this.movementSpeed;
        var rotMult = delta * this.rollSpeed;

        this.object.translateX(this.moveVector.x * moveMult);
        this.object.translateY(this.moveVector.y * moveMult);
        this.object.translateZ(this.moveVector.z * moveMult);

        this.tmpQuaternion.set(this.rotationVector.x * rotMult, this.rotationVector.y * rotMult, this.rotationVector.z * rotMult, 1).normalize();
        this.object.quaternion.multiply(this.tmpQuaternion);

        if (lastPosition.distanceToSquared(this.object.position) > EPS || 8 * (1 - lastQuaternion.dot(this.object.quaternion)) > EPS) {
            this.dispatchEvent(_changeEvent);
            lastQuaternion.copy(this.object.quaternion);
            lastPosition.copy(this.object.position);
        }
    }

    private function updateMovementVector() {
        var forward = (this.moveState.get("forward") || (this.autoForward && !this.moveState.get("back"))) ? 1 : 0;

        this.moveVector.x = (-this.moveState.get("left") + this.moveState.get("right"));
        this.moveVector.y = (-this.moveState.get("down") + this.moveState.get("up"));
        this.moveVector.z = (-forward + this.moveState.get("back"));

        //console.log('move:', [ this.moveVector.x, this.moveVector.y, this.moveVector.z ]);
    }

    private function updateRotationVector() {
        this.rotationVector.x = (-this.moveState.get("pitchDown") + this.moveState.get("pitchUp"));
        this.rotationVector.y = (-this.moveState.get("yawRight") + this.moveState.get("yawLeft"));
        this.rotationVector.z = (-this.moveState.get("rollRight") + this.moveState.get("rollLeft"));

        //console.log('rotate:', [ this.rotationVector.x, this.rotationVector.y, this.rotationVector.z ]);
    }

    private function getContainerDimensions() {
        if (this.domElement != document) {
            return {
                size: [this.domElement.offsetWidth, this.domElement.offsetHeight],
                offset: [this.domElement.offsetLeft, this.domElement.offsetTop]
            };
        } else {
            return {
                size: [window.innerWidth, window.innerHeight],
                offset: [0, 0]
            };
        }
    }

    public function dispose() {
        this.domElement.removeEventListener("contextmenu", _contextmenu);
        this.domElement.removeEventListener("pointerdown", _pointerdown);
        this.domElement.removeEventListener("pointermove", _pointermove);
        this.domElement.removeEventListener("pointerup", _pointerup);
        this.domElement.removeEventListener("pointercancel", _pointercancel);

        window.removeEventListener("keydown", _keydown);
        window.removeEventListener("keyup", _keyup);
    }

}