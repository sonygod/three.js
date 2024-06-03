import three.math.MathUtils;
import three.math.Spherical;
import three.math.Vector3;
import js.html.HtmlElement;
import js.html.MouseEvent;
import js.html.KeyboardEvent;

class FirstPersonControls {

    var _lookDirection:Vector3 = new Vector3();
    var _spherical:Spherical = new Spherical();
    var _target:Vector3 = new Vector3();

    var object:Dynamic;
    var domElement:HtmlElement;

    // API
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

    // internals
    var autoSpeedFactor:Float = 0.0;
    var pointerX:Int = 0;
    var pointerY:Int = 0;
    var moveForward:Bool = false;
    var moveBackward:Bool = false;
    var moveLeft:Bool = false;
    var moveRight:Bool = false;
    var moveUp:Bool = false;
    var moveDown:Bool = false;
    var viewHalfX:Int = 0;
    var viewHalfY:Int = 0;

    // private variables
    var lat:Float = 0;
    var lon:Float = 0;

    public function new(object:Dynamic, domElement:HtmlElement) {
        this.object = object;
        this.domElement = domElement;

        handleResize();
        setOrientation(this);

        this.domElement.addEventListener('contextmenu', contextmenu);
        this.domElement.addEventListener('pointerdown', _onPointerDown);
        this.domElement.addEventListener('pointermove', _onPointerMove);
        this.domElement.addEventListener('pointerup', _onPointerUp);

        js.Browser.document.addEventListener('keydown', _onKeyDown);
        js.Browser.document.addEventListener('keyup', _onKeyUp);
    }

    public function handleResize():Void {
        if (this.domElement == js.Browser.document) {
            this.viewHalfX = js.Browser.window.innerWidth / 2;
            this.viewHalfY = js.Browser.window.innerHeight / 2;
        } else {
            this.viewHalfX = this.domElement.offsetWidth / 2;
            this.viewHalfY = this.domElement.offsetHeight / 2;
        }
    }

    public function onPointerDown(event:MouseEvent):Void {
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

    public function onPointerUp(event:MouseEvent):Void {
        if (this.activeLook) {
            switch (event.button) {
                case 0: this.moveForward = false; break;
                case 2: this.moveBackward = false; break;
            }
        }

        this.mouseDragOn = false;
    }

    public function onPointerMove(event:MouseEvent):Void {
        if (this.domElement == js.Browser.document) {
            this.pointerX = event.pageX - this.viewHalfX;
            this.pointerY = event.pageY - this.viewHalfY;
        } else {
            this.pointerX = event.pageX - this.domElement.offsetLeft - this.viewHalfX;
            this.pointerY = event.pageY - this.domElement.offsetTop - this.viewHalfY;
        }
    }

    public function onKeyDown(event:KeyboardEvent):Void {
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

    public function onKeyUp(event:KeyboardEvent):Void {
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

    public function lookAt(x:Dynamic, y:Dynamic = null, z:Dynamic = null):FirstPersonControls {
        if (Std.is(x, Vector3)) {
            _target.copy(x);
        } else {
            _target.set(x, y, z);
        }

        this.object.lookAt(_target);
        setOrientation(this);

        return this;
    }

    public function update(delta:Float):Void {
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

        var targetPosition = new Vector3();
        targetPosition.setFromSphericalCoords(1, phi, theta).add(position);

        this.object.lookAt(targetPosition);
    }

    public function dispose():Void {
        this.domElement.removeEventListener('contextmenu', contextmenu);
        this.domElement.removeEventListener('pointerdown', _onPointerDown);
        this.domElement.removeEventListener('pointermove', _onPointerMove);
        this.domElement.removeEventListener('pointerup', _onPointerUp);

        js.Browser.document.removeEventListener('keydown', _onKeyDown);
        js.Browser.document.removeEventListener('keyup', _onKeyUp);
    }

    private function setOrientation(controls:FirstPersonControls):Void {
        var quaternion = controls.object.quaternion;

        _lookDirection.set(0, 0, -1).applyQuaternion(quaternion);
        _spherical.setFromVector3(_lookDirection);

        lat = 90 - MathUtils.radToDeg(_spherical.phi);
        lon = MathUtils.radToDeg(_spherical.theta);
    }

    private function _onPointerMove(event:MouseEvent):Void {
        this.onPointerMove(event);
    }

    private function _onPointerDown(event:MouseEvent):Void {
        this.onPointerDown(event);
    }

    private function _onPointerUp(event:MouseEvent):Void {
        this.onPointerUp(event);
    }

    private function _onKeyDown(event:KeyboardEvent):Void {
        this.onKeyDown(event);
    }

    private function _onKeyUp(event:KeyboardEvent):Void {
        this.onKeyUp(event);
    }
}

function contextmenu(event:Event):Void {
    event.preventDefault();
}