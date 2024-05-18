package three.js.examples.jsm.controls;

import three.MathUtils;
import three.Spherical;
import three.Vector3;

class FirstPersonControls {
    private var object:Dynamic;
    private var domElement:Dynamic;

    private var _lookDirection:Vector3;
    private var _spherical:Spherical;
    private var _target:Vector3;

    public var enabled:Bool;
    public var movementSpeed:Float;
    public var lookSpeed:Float;

    public var lookVertical:Bool;
    public var autoForward:Bool;

    public var activeLook:Bool;

    public var heightSpeed:Bool;
    public var heightCoef:Float;
    public var heightMin:Float;
    public var heightMax:Float;

    public var constrainVertical:Bool;
    public var verticalMin:Float;
    public var verticalMax:Float;

    public var mouseDragOn:Bool;

    private var autoSpeedFactor:Float;
    private var pointerX:Float;
    private var pointerY:Float;

    private var moveForward:Bool;
    private var moveBackward:Bool;
    private var moveLeft:Bool;
    private var moveRight:Bool;
    private var moveUp:Bool;
    private var moveDown:Bool;

    private var viewHalfX:Float;
    private var viewHalfY:Float;

    private var lat:Float;
    private var lon:Float;

    public function new(object:Dynamic, domElement:Dynamic) {
        this.object = object;
        this.domElement = domElement;

        _lookDirection = new Vector3();
        _spherical = new Spherical();
        _target = new Vector3();

        enabled = true;

        movementSpeed = 1.0;
        lookSpeed = 0.005;

        lookVertical = true;
        autoForward = false;

        activeLook = true;

        heightSpeed = false;
        heightCoef = 1.0;
        heightMin = 0.0;
        heightMax = 1.0;

        constrainVertical = false;
        verticalMin = 0;
        verticalMax = Math.PI;

        mouseDragOn = false;

        autoSpeedFactor = 0.0;

        pointerX = 0;
        pointerY = 0;

        moveForward = false;
        moveBackward = false;
        moveLeft = false;
        moveRight = false;
        moveUp = false;
        moveDown = false;

        viewHalfX = 0;
        viewHalfY = 0;

        lat = 0;
        lon = 0;

        handleResize();

        domElement.addEventListener("contextmenu", contextmenu);
        domElement.addEventListener("pointerdown", onPointerDown);
        domElement.addEventListener("pointermove", onPointerMove);
        domElement.addEventListener("pointerup", onPointerUp);

        js.Browser.window.addEventListener("keydown", onKeyDown);
        js.Browser.window.addEventListener("keyup", onKeyUp);

        setOrientation(this);
    }

    private function handleResize() {
        if (domElement == js.Browser.document) {
            viewHalfX = js.Browser.window.innerWidth / 2;
            viewHalfY = js.Browser.window.innerHeight / 2;
        } else {
            viewHalfX = domElement.offsetWidth / 2;
            viewHalfY = domElement.offsetHeight / 2;
        }
    }

    private function onPointerDown(event:Dynamic) {
        if (domElement != js.Browser.document) {
            domElement.focus();
        }
        if (activeLook) {
            switch (event.button) {
                case 0: moveForward = true; break;
                case 2: moveBackward = true; break;
            }
        }
        mouseDragOn = true;
    }

    private function onPointerUp(event:Dynamic) {
        if (activeLook) {
            switch (event.button) {
                case 0: moveForward = false; break;
                case 2: moveBackward = false; break;
            }
        }
        mouseDragOn = false;
    }

    private function onPointerMove(event:Dynamic) {
        if (domElement == js.Browser.document) {
            pointerX = event.pageX - viewHalfX;
            pointerY = event.pageY - viewHalfY;
        } else {
            pointerX = event.pageX - domElement.offsetLeft - viewHalfX;
            pointerY = event.pageY - domElement.offsetTop - viewHalfY;
        }
    }

    private function onKeyDown(event:Dynamic) {
        switch (event.code) {
            case "ArrowUp":
            case "KeyW": moveForward = true; break;
            case "ArrowLeft":
            case "KeyA": moveLeft = true; break;
            case "ArrowDown":
            case "KeyS": moveBackward = true; break;
            case "ArrowRight":
            case "KeyD": moveRight = true; break;
            case "KeyR": moveUp = true; break;
            case "KeyF": moveDown = true; break;
        }
    }

    private function onKeyUp(event:Dynamic) {
        switch (event.code) {
            case "ArrowUp":
            case "KeyW": moveForward = false; break;
            case "ArrowLeft":
            case "KeyA": moveLeft = false; break;
            case "ArrowDown":
            case "KeyS": moveBackward = false; break;
            case "ArrowRight":
            case "KeyD": moveRight = false; break;
            case "KeyR": moveUp = false; break;
            case "KeyF": moveDown = false; break;
        }
    }

    public function lookAt(x:Dynamic, y:Float, z:Float) {
        if (x.isVector3) {
            _target.copy(x);
        } else {
            _target.set(x, y, z);
        }
        object.lookAt(_target);
        setOrientation(this);
        return this;
    }

    public function update() {
        var targetPosition = new Vector3();
        return function update(delta:Float) {
            if (!enabled) return;
            if (heightSpeed) {
                var y = MathUtils.clamp(object.position.y, heightMin, heightMax);
                var heightDelta = y - heightMin;
                autoSpeedFactor = delta * (heightDelta * heightCoef);
            } else {
                autoSpeedFactor = 0.0;
            }
            var actualMoveSpeed = delta * movementSpeed;

            if (moveForward || (autoForward && !moveBackward)) object.translateZ(-(actualMoveSpeed + autoSpeedFactor));
            if (moveBackward) object.translateZ(actualMoveSpeed);

            if (moveLeft) object.translateX(-actualMoveSpeed);
            if (moveRight) object.translateX(actualMoveSpeed);

            if (moveUp) object.translateY(actualMoveSpeed);
            if (moveDown) object.translateY(-actualMoveSpeed);

            var actualLookSpeed = delta * lookSpeed;
            if (!activeLook) {
                actualLookSpeed = 0;
            }

            var verticalLookRatio = 1;
            if (constrainVertical) {
                verticalLookRatio = Math.PI / (verticalMax - verticalMin);
            }

            lon -= pointerX * actualLookSpeed;
            if (lookVertical) lat -= pointerY * actualLookSpeed * verticalLookRatio;

            lat = Math.max(-85, Math.min(85, lat));

            var phi = MathUtils.degToRad(90 - lat);
            var theta = MathUtils.degToRad(lon);

            if (constrainVertical) {
                phi = MathUtils.mapLinear(phi, 0, Math.PI, verticalMin, verticalMax);
            }

            targetPosition.setFromSphericalCoords(1, phi, theta).add(object.position);

            object.lookAt(targetPosition);
        };
    }

    public function dispose() {
        domElement.removeEventListener("contextmenu", contextmenu);
        domElement.removeEventListener("pointerdown", onPointerDown);
        domElement.removeEventListener("pointermove", onPointerMove);
        domElement.removeEventListener("pointerup", onPointerUp);

        js.Browser.window.removeEventListener("keydown", onKeyDown);
        js.Browser.window.removeEventListener("keyup", onKeyUp);
    }

    private function setOrientation(controls:FirstPersonControls) {
        var quaternion = controls.object.quaternion;

        _lookDirection.set(0, 0, -1).applyQuaternion(quaternion);
        _spherical.setFromVector3(_lookDirection);

        lat = 90 - MathUtils.radToDeg(_spherical.phi);
        lon = MathUtils.radToDeg(_spherical.theta);
    }

    private function contextmenu(event:Dynamic) {
        event.preventDefault();
    }
}