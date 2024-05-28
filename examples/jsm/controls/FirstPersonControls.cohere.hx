import js.Browser.window;
import js.html.Document;
import js.html.HTMLElement;
import js.html.HTMLDocument;
import js.html.HTMLCollection;
import js.html.HTMLHtmlElement;
import js.html.HTMLBodyElement;
import js.html.HTMLPointerEvent;
import js.html.PointerEvent;
import js.html.KeyboardEvent;

import js.three.Math as MathUtils;
import js.three.Spherical;
import js.three.Vector3;

class FirstPersonControls {
    var object:Dynamic;
    var domElement:Dynamic;
    var enabled:Bool;
    var movementSpeed:Float;
    var lookSpeed:Float;
    var lookVertical:Bool;
    var autoForward:Bool;
    var activeLook:Bool;
    var heightSpeed:Bool;
    var heightCoef:Float;
    var heightMin:Float;
    var heightMax:Float;
    var constrainVertical:Bool;
    var verticalMin:Float;
    var verticalMax:Float;
    var mouseDragOn:Bool;
    var autoSpeedFactor:Float;
    var pointerX:Int;
    var pointerY:Int;
    var moveForward:Bool;
    var moveBackward:Bool;
    var moveLeft:Bool;
    var moveRight:Bool;
    var moveUp:Bool;
    var moveDown:Bool;
    var viewHalfX:Int;
    var viewHalfY:Int;
    var handleResize:Void->Void;
    var onPointerDown:Void->Void;
    var onPointerUp:Void->Void;
    var onPointerMove:Void->Void;
    var onKeyDown:Void->Void;
    var onKeyUp:Void->Void;
    var lookAt:Dynamic;
    var update:Dynamic;
    var dispose:Void->Void;

    public function new(object:Dynamic, domElement:Dynamic) {
        this.object = object;
        this.domElement = domElement;
        this.enabled = true;
        this.movementSpeed = 1.0;
        this.lookSpeed = 0.005;
        this.lookVertical = true;
        this.autoForward = false;
        this.activeLook = true;
        this.heightSpeed = false;
        this.heightCoef = 1.0;
        this.heightMin = 0.0;
        this.heightMax = 1.0;
        this.constrainVertical = false;
        this.verticalMin = 0;
        this.verticalMax = Math.PI;
        this.mouseDragOn = false;
        this.autoSpeedFactor = 0.0;
        this.pointerX = 0;
        this.pointerY = 0;
        this.moveForward = false;
        this.moveBackward = false;
        this.moveLeft = false;
        this.moveRight = false;
        this.viewHalfX = 0;
        this.viewHalfY = 0;

        var lat = 0;
        var lon = 0;

        this.handleResize = function() {
            if (this.domElement == Document.document) {
                this.viewHalfX = window.innerWidth / 2;
                this.viewHalfY = window.innerHeight / 2;
            } else {
                this.viewHalfX = this.domElement.offsetWidth / 2;
                this.viewHalfY = this.domElement.offsetHeight / 2;
            }
        };

        this.onPointerDown = function(event:Dynamic) {
            if (this.domElement != Document.document) {
                this.domElement.focus();
            }
            if (this.activeLook) {
                switch (event.button) {
                    case 0:
                        this.moveForward = true;
                        break;
                    case 2:
                        this.moveBackward = true;
                        break;
                }
            }
            this.mouseDragOn = true;
        };

        this.onPointerUp = function(event:Dynamic) {
            if (this.activeLook) {
                switch (event.button) {
                    case 0:
                        this.moveForward = false;
                        break;
                    case 2:
                        this.moveBackward = false;
                        break;
                }
            }
            this.mouseDragOn = false;
        };

        this.onPointerMove = function(event:Dynamic) {
            if (this.domElement == Document.document) {
                this.pointerX = event.pageX - this.viewHalfX;
                this.pointerY = event.pageY - this.viewHalfY;
            } else {
                this.pointerX = event.pageX - this.domElement.offsetLeft - this.viewHalfX;
                this.pointerY = event.pageY - this.domElement.offsetTop - this.viewHalfY;
            }
        };

        this.onKeyDown = function(event:Dynamic) {
            switch (event.code) {
                case 'ArrowUp':
                case 'KeyW':
                    this.moveForward = true;
                    break;
                case 'ArrowLeft':
                case 'KeyA':
                    this.moveLeft = true;
                    break;
                case 'ArrowDown':
                case 'KeyS':
                    this.moveBackward = true;
                    break;
                case 'ArrowRight':
                case 'KeyD':
                    this.moveRight = true;
                    break;
                case 'KeyR':
                    this.moveUp = true;
                    break;
                case 'KeyF':
                    this.moveDown = true;
                    break;
            }
        };

        this.onKeyUp = function(event:Dynamic) {
            switch (event.code) {
                case 'ArrowUp':
                case 'KeyW':
                    this.moveForward = false;
                    break;
                case 'ArrowLeft':
                case 'KeyA':
                    this.moveLeft = false;
                    break;
                case 'ArrowDown':
                case 'KeyS':
                    this.moveBackward = false;
                    break;
                case 'ArrowRight':
                case 'KeyD':
                    this.moveRight = false;
                    break;
                case 'KeyR':
                    this.moveUp = false;
                    break;
                case 'KeyF':
                    this.moveDown = false;
                    break;
            }
        };

        this.lookAt = function(x:Dynamic, y:Dynamic, z:Dynamic) {
            var _target = new Vector3();
            if (x.isVector3) {
                _target.copy(x);
            } else {
                _target.set(x, y, z);
            }
            this.object.lookAt(_target);
            setOrientation(this);
            return this;
        };

        this.update = function(delta:Float) {
            if (this.enabled == false) return;
            var targetPosition = new Vector3();
            if (this.heightSpeed) {
                var y = MathUtils.clamp(this.object.position.y, this.heightMin, this.heightMax);
                var heightDelta = y - this.heightMin;
                this.autoSpeedFactor = delta * (heightDelta * this.heightCoef);
            } else {
                this.autoSpeedFactor = 0.0;
            }
            var actualMoveSpeed = delta * this.movementSpeed;
            if (this.moveForward || (this.autoForward && !this.moveBackward)) {
                this.object.translateZ(-(actualMoveSpeed + this.autoSpeedFactor));
            }
            if (this.moveBackward) {
                this.object.translateZ(actualMoveSpeed);
            }
            if (this.moveLeft) {
                this.object.translateX(-actualMoveSpeed);
            }
            if (this.moveRight) {
                this.object.translateX(actualMoveSpeed);
            }
            if (this.moveUp) {
                this.object.translateY(actualMoveSpeed);
            }
            if (this.moveDown) {
                this.object.translateY(-actualMoveSpeed);
            }
            var actualLookSpeed = delta * this.lookSpeed;
            if (!this.activeLook) {
                actualLookSpeed = 0;
            }
            var verticalLookRatio = 1;
            if (this.constrainVertical) {
                verticalLookRatio = Math.PI / (this.verticalMax - this.verticalMin);
            }
            lon -= this.pointerX * actualLookSpeed;
            if (this.lookVertical) {
                lat -= this.pointerY * actualLookSpeed * verticalLookRatio;
            }
            lat = Math.max(-85, Math.min(85, lat));
            var phi = MathUtils.degToRad(90 - lat);
            var theta = MathUtils.degToRad(lon);
            if (this.constrainVertical) {
                phi = MathUtils.mapLinear(phi, 0, Math.PI, this.verticalMin, this.verticalMax);
            }
            var position = this.object.position;
            targetPosition.setFromSphericalCoords(1, phi, theta).add(position);
            this.object.lookAt(targetPosition);
        };

        this.dispose = function() {
            this.domElement.removeEventListener('contextmenu', contextmenu);
            this.domElement.removeEventListener('pointerdown', _onPointerDown);
            this.domElement.removeEventListener('pointermove', _onPointerMove);
            this.domElement.removeEventListener('pointerup', _onPointerUp);
            window.removeEventListener('keydown', _onKeyDown);
            window.removeEventListener('keyup', _onKeyUp);
        };

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

        function setOrientation(controls:FirstPersonControls) {
            var quaternion = controls.object.quaternion;
            var _lookDirection = new Vector3();
            _lookDirection.set(0, 0, -1).applyQuaternion(quaternion);
            var _spherical = new Spherical();
            _spherical.setFromVector3(_lookDirection);
            lat = 90 - MathUtils.radToDeg(_spherical.phi);
            lon = MathUtils.radToDeg(_spherical.theta);
        }

        this.handleResize();
        setOrientation(this);
    }
}

function contextmenu(event:Dynamic) {
    event.preventDefault();
}

function main() {
    var controls = new FirstPersonControls(null, null);
}

@:build(main())