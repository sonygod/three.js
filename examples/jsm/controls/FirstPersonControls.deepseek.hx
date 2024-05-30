import three.MathUtils;
import three.Spherical;
import three.Vector3;

class FirstPersonControls {

    var object:Dynamic;
    var domElement:Dynamic;

    var enabled:Bool = true;
    var movementSpeed:Float = 1.0;
    var lookSpeed:Float = 0.005;
    var lookVertical:Bool = true;
    var autoForward:Bool = false;
    var activeLook:Bool = true;
    var heightSpeed:Bool = false;
    var heightCoef:Float = 1.0;
    var heightMin:Float = 0.0;
    var heightMax:Float = 1.0;
    var constrainVertical:Bool = false;
    var verticalMin:Float = 0;
    var verticalMax:Float = Math.PI;
    var mouseDragOn:Bool = false;
    var autoSpeedFactor:Float = 0.0;
    var pointerX:Int = 0;
    var pointerY:Int = 0;
    var moveForward:Bool = false;
    var moveBackward:Bool = false;
    var moveLeft:Bool = false;
    var moveRight:Bool = false;
    var viewHalfX:Int = 0;
    var viewHalfY:Int = 0;
    var lat:Float = 0;
    var lon:Float = 0;

    var _lookDirection:Vector3 = new Vector3();
    var _spherical:Spherical = new Spherical();
    var _target:Vector3 = new Vector3();

    public function new(object:Dynamic, domElement:Dynamic) {
        this.object = object;
        this.domElement = domElement;

        var _onPointerMove = this.onPointerMove.bind(this);
        var _onPointerDown = this.onPointerDown.bind(this);
        var _onPointerUp = this.onPointerUp.bind(this);
        var _onKeyDown = this.onKeyDown.bind(this);
        var _onKeyUp = this.onKeyUp.bind(this);

        this.domElement.addEventListener('contextmenu', contextmenu);
        this.domElement.addEventListener('pointerdown', _onPointerDown);
        this.domElement.addEventListener('pointermove', _onPointerMove);
        this.domElement.addEventListener('pointerup', _onPointerUp);

        window.addEventListener('keydown', _onKeyDown);
        window.addEventListener('keyup', _onKeyUp);

        this.handleResize();
        setOrientation(this);
    }

    function handleResize() {
        if (this.domElement === document) {
            this.viewHalfX = window.innerWidth / 2;
            this.viewHalfY = window.innerHeight / 2;
        } else {
            this.viewHalfX = this.domElement.offsetWidth / 2;
            this.viewHalfY = this.domElement.offsetHeight / 2;
        }
    }

    function onPointerDown(event:Dynamic) {
        if (this.domElement !== document) {
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

    function onPointerUp(event:Dynamic) {
        if (this.activeLook) {
            switch (event.button) {
                case 0: this.moveForward = false; break;
                case 2: this.moveBackward = false; break;
            }
        }
        this.mouseDragOn = false;
    }

    function onPointerMove(event:Dynamic) {
        if (this.domElement === document) {
            this.pointerX = event.pageX - this.viewHalfX;
            this.pointerY = event.pageY - this.viewHalfY;
        } else {
            this.pointerX = event.pageX - this.domElement.offsetLeft - this.viewHalfX;
            this.pointerY = event.pageY - this.domElement.offsetTop - this.viewHalfY;
        }
    }

    function onKeyDown(event:Dynamic) {
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

    function onKeyUp(event:Dynamic) {
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

    function lookAt(x:Float, y:Float, z:Float) {
        if (x.isVector3) {
            _target.copy(x);
        } else {
            _target.set(x, y, z);
        }
        this.object.lookAt(_target);
        setOrientation(this);
        return this;
    }

    function update(delta:Float) {
        var targetPosition = new Vector3();
        if (this.enabled === false) return;
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
        targetPosition.setFromSphericalCoords(1, phi, theta).add(position);
        this.object.lookAt(targetPosition);
    }

    function dispose() {
        this.domElement.removeEventListener('contextmenu', contextmenu);
        this.domElement.removeEventListener('pointerdown', _onPointerDown);
        this.domElement.removeEventListener('pointermove', _onPointerMove);
        this.domElement.removeEventListener('pointerup', _onPointerUp);
        window.removeEventListener('keydown', _onKeyDown);
        window.removeEventListener('keyup', _onKeyUp);
    }

    function setOrientation(controls:FirstPersonControls) {
        var quaternion = controls.object.quaternion;
        _lookDirection.set(0, 0, -1).applyQuaternion(quaternion);
        _spherical.setFromVector3(_lookDirection);
        lat = 90 - MathUtils.radToDeg(_spherical.phi);
        lon = MathUtils.radToDeg(_spherical.theta);
    }

    static function contextmenu(event:Dynamic) {
        event.preventDefault();
    }
}