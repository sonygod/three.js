import MathUtils.haxe_math_MathUtils;
import Spherical.haxe_math_Spherical;
import Vector3.haxe_math_Vector3;

class FirstPersonControls {
    public var object:Dynamic;
    public var domElement:Dynamic;

    public var enabled:Bool = true;
    public var movementSpeed:Float = 1.0;
    public var lookSpeed:Float = 0.005;
    public var lookVertical:Bool = true;
    public var autoForward:Bool = false;
    public var activeLook:Bool = true;
    public var heightSpeed:Bool = false;
    public var heightCoef:Float = 1.0;
    public var heightMin:Float = 0.0;
    public var heightMax:Float = 1.0;
    public var constrainVertical:Bool = false;
    public var verticalMin:Float = 0;
    public var verticalMax:Float = Math.PI;
    public var mouseDragOn:Bool = false;

    public var autoSpeedFactor:Float = 0.0;
    public var pointerX:Int = 0;
    public var pointerY:Int = 0;
    public var moveForward:Bool = false;
    public var moveBackward:Bool = false;
    public var moveLeft:Bool = false;
    public var moveRight:Bool = false;
    public var viewHalfX:Int = 0;
    public var viewHalfY:Int = 0;

    private var lat:Float = 0;
    private var lon:Float = 0;

    private var _lookDirection:Vector3 = new Vector3();
    private var _spherical:Spherical = new Spherical();
    private var _target:Vector3 = new Vector3();

    public function new(object:Dynamic, domElement:Dynamic) {
        this.object = object;
        this.domElement = domElement;

        this.handleResize();
        this.setOrientation();
    }

    public function handleResize() {
        if (this.domElement == js.Browser.document) {
            this.viewHalfX = js.Browser.window.innerWidth / 2;
            this.viewHalfY = js.Browser.window.innerHeight / 2;
        } else {
            this.viewHalfX = this.domElement.offsetWidth / 2;
            this.viewHalfY = this.domElement.offsetHeight / 2;
        }
    }

    public function onPointerDown(event:Dynamic) {
        if (this.domElement != js.Browser.document) {
            this.domElement.focus();
        }

        if (this.activeLook) {
            switch (event.button) {
                case 0: this.moveForward = true; break;
                case 2: this.moveBackward = true; break;
            }
        }

        this.mouseDragOn = true;
    }

    public function onPointerUp(event:Dynamic) {
        if (this.activeLook) {
            switch (event.button) {
                case 0: this.moveForward = false; break;
                case 2: this.moveBackward = false; break;
            }
        }

        this.mouseDragOn = false;
    }

    public function onPointerMove(event:Dynamic) {
        if (this.domElement == js.Browser.document) {
            this.pointerX = event.pageX - this.viewHalfX;
            this.pointerY = event.pageY - this.viewHalfY;
        } else {
            this.pointerX = event.pageX - this.domElement.offsetLeft - this.viewHalfX;
            this.pointerY = event.pageY - this.domElement.offsetTop - this.viewHalfY;
        }
    }

    public function onKeyDown(event:Dynamic) {
        switch (event.code) {
            case 'ArrowUp':
            case 'KeyW': this.moveForward = true; break;
            case 'ArrowLeft':
            case 'KeyA': this.moveLeft = true; break;
            case 'ArrowDown':
            case 'KeyS': this.moveBackward = true; break;
            case 'ArrowRight':
            case 'KeyD': this.moveRight = true; break;
            case 'KeyR': this.moveUp = true; break;
            case 'KeyF': this.moveDown = true; break;
        }
    }

    public function onKeyUp(event:Dynamic) {
        switch (event.code) {
            case 'ArrowUp':
            case 'KeyW': this.moveForward = false; break;
            case 'ArrowLeft':
            case 'KeyA': this.moveLeft = false; break;
            case 'ArrowDown':
            case 'KeyS': this.moveBackward = false; break;
            case 'ArrowRight':
            case 'KeyD': this.moveRight = false; break;
            case 'KeyR': this.moveUp = false; break;
            case 'KeyF': this.moveDown = false; break;
        }
    }

    public function lookAt(x:Dynamic, y:Dynamic, z:Dynamic) {
        if (Type.typeof(x) == Type.typeof(new Vector3())) {
            _target.copy(x);
        } else {
            _target.set(x, y, z);
        }

        this.object.lookAt(_target);
        this.setOrientation();
        return this;
    }

    public function update(delta:Float) {
        if (this.enabled == false) return;

        if (this.heightSpeed) {
            var y = MathUtils.clamp(this.object.position.y, this.heightMin, this.heightMax);
            var heightDelta = y - this.heightMin;
            this.autoSpeedFactor = delta * (heightDelta * this.heightCoef);
        } else {
            this.autoSpeedFactor = 0.0;
        }

        var actualMoveSpeed = delta * this.movementSpeed;

        if (this.moveForward || (this.autoForward && !this.moveBackward)) this.object.translateZ(-(actualMoveSpeed + this.autoSpeedFactor));
        if (this.moveBackward) this.object.translateZ(actualMoveSpeed);

        if (this.moveLeft) this.object.translateX(-actualMoveSpeed);
        if (this.moveRight) this.object.translateX(actualMoveSpeed);

        if (this.moveUp) this.object.translateY(actualMoveSpeed);
        if (this.moveDown) this.object.translateY(-actualMoveSpeed);

        var actualLookSpeed = delta * this.lookSpeed;

        if (!this.activeLook) {
            actualLookSpeed = 0;
        }

        var verticalLookRatio = 1;

        if (this.constrainVertical) {
            verticalLookRatio = Math.PI / (this.verticalMax - this.verticalMin);
        }

        lon -= this.pointerX * actualLookSpeed;
        if (this.lookVertical) lat -= this.pointerY * actualLookSpeed * verticalLookRatio;

        lat = Math.max(-85, Math.min(85, lat));

        var phi = MathUtils.degToRad(90 - lat);
        var theta = MathUtils.degToRad(lon);

        if (this.constrainVertical) {
            phi = MathUtils.mapLinear(phi, 0, Math.PI, this.verticalMin, this.verticalMax);
        }

        var position = this.object.position;
        var targetPosition = new Vector3().setFromSphericalCoords(1, phi, theta).add(position);

        this.object.lookAt(targetPosition);
    }

    public function dispose() {
        this.domElement.removeEventListener('contextmenu', contextmenu);
        this.domElement.removeEventListener('pointerdown', _onPointerDown);
        this.domElement.removeEventListener('pointermove', _onPointerMove);
        this.domElement.removeEventListener('pointerup', _onPointerUp);

        js.Browser.window.removeEventListener('keydown', _onKeyDown);
        js.Browser.window.removeEventListener('keyup', _onKeyUp);
    }

    private function setOrientation() {
        var quaternion = this.object.quaternion;

        _lookDirection.set(0, 0, -1).applyQuaternion(quaternion);
        _spherical.setFromVector3(_lookDirection);

        lat = 90 - MathUtils.radToDeg(_spherical.phi);
        lon = MathUtils.radToDeg(_spherical.theta);
    }

    private function _onPointerMove(event:Dynamic) {
        this.onPointerMove(event);
    }

    private function _onPointerDown(event:Dynamic) {
        this.onPointerDown(event);
    }

    private function _onPointerUp(event:Dynamic) {
        this.onPointerUp(event);
    }

    private function _onKeyDown(event:Dynamic) {
        this.onKeyDown(event);
    }

    private function _onKeyUp(event:Dynamic) {
        this.onKeyUp(event);
    }
}

function contextmenu(event:Dynamic) {
    event.preventDefault();
}