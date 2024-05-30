package three.js.examples.jsm.controls;

import three.MathUtils;
import three.Spherical;
import three.Vector3;

class FirstPersonControls {
    public var object:Dynamic;
    public var domElement:Dynamic;

    // API
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

    // internals
    public var autoSpeedFactor:Float = 0.0;
    public var pointerX:Float = 0;
    public var pointerY:Float = 0;
    public var moveForward:Bool = false;
    public var moveBackward:Bool = false;
    public var moveLeft:Bool = false;
    public var moveRight:Bool = false;
    public var moveUp:Bool = false;
    public var moveDown:Bool = false;
    public var viewHalfX:Float = 0;
    public var viewHalfY:Float = 0;

    // private variables
    var lat:Float = 0;
    var lon:Float = 0;

    public function new(object:Dynamic, domElement:Dynamic) {
        this.object = object;
        this.domElement = domElement;

        handleResize();

        var _lookDirection = new Vector3();
        var _spherical = new Spherical();
        var _target = new Vector3();

        function setOrientation(controls:FirstPersonControls) {
            var quaternion = controls.object.quaternion;

            _lookDirection.set(0, 0, -1).applyQuaternion(quaternion);
            _spherical.setFromVector3(_lookDirection);

            lat = 90 - MathUtils.radToDeg(_spherical.phi);
            lon = MathUtils.radToDeg(_spherical.theta);
        }

        function handleResize() {
            if (domElement == document) {
                viewHalfX = window.innerWidth / 2;
                viewHalfY = window.innerHeight / 2;
            } else {
                viewHalfX = domElement.offsetWidth / 2;
                viewHalfY = domElement.offsetHeight / 2;
            }
        }

        function onPointerDown(event:Dynamic) {
            if (domElement != document) {
                domElement.focus();
            }
            if (activeLook) {
                switch (event.button) {
                    case 0: moveForward = true;
                    case 2: moveBackward = true;
                }
            }
            mouseDragOn = true;
        }

        function onPointerUp(event:Dynamic) {
            if (activeLook) {
                switch (event.button) {
                    case 0: moveForward = false;
                    case 2: moveBackward = false;
                }
            }
            mouseDragOn = false;
        }

        function onPointerMove(event:Dynamic) {
            if (domElement == document) {
                pointerX = event.pageX - viewHalfX;
                pointerY = event.pageY - viewHalfY;
            } else {
                pointerX = event.pageX - domElement.offsetLeft - viewHalfX;
                pointerY = event.pageY - domElement.offsetTop - viewHalfY;
            }
        }

        function onKeyDown(event:Dynamic) {
            switch (event.code) {
                case 'ArrowUp':
                case 'KeyW': moveForward = true;
                case 'ArrowLeft':
                case 'KeyA': moveLeft = true;
                case 'ArrowDown':
                case 'KeyS': moveBackward = true;
                case 'ArrowRight':
                case 'KeyD': moveRight = true;
                case 'KeyR': moveUp = true;
                case 'KeyF': moveDown = true;
            }
        }

        function onKeyUp(event:Dynamic) {
            switch (event.code) {
                case 'ArrowUp':
                case 'KeyW': moveForward = false;
                case 'ArrowLeft':
                case 'KeyA': moveLeft = false;
                case 'ArrowDown':
                case 'KeyS': moveBackward = false;
                case 'ArrowRight':
                case 'KeyD': moveRight = false;
                case 'KeyR': moveUp = false;
                case 'KeyF': moveDown = false;
            }
        }

        function update() {
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

                if (moveForward || (autoForward && !moveBackward))
                    object.translateZ(-(actualMoveSpeed + autoSpeedFactor));
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

                var position = object.position;

                targetPosition.setFromSphericalCoords(1, phi, theta).add(position);

                object.lookAt(targetPosition);
            };
        }

        function dispose() {
            domElement.removeEventListener('contextmenu', contextmenu);
            domElement.removeEventListener('pointerdown', onPointerDown);
            domElement.removeEventListener('pointermove', onPointerMove);
            domElement.removeEventListener('pointerup', onPointerUp);

            window.removeEventListener('keydown', onKeyDown);
            window.removeEventListener('keyup', onKeyUp);
        }

        var _onPointerMove = onPointerMove.bind(this);
        var _onPointerDown = onPointerDown.bind(this);
        var _onPointerUp = onPointerUp.bind(this);
        var _onKeyDown = onKeyDown.bind(this);
        var _onKeyUp = onKeyUp.bind(this);

        domElement.addEventListener('contextmenu', contextmenu);
        domElement.addEventListener('pointerdown', _onPointerDown);
        domElement.addEventListener('pointermove', _onPointerMove);
        domElement.addEventListener('pointerup', _onPointerUp);

        window.addEventListener('keydown', _onKeyDown);
        window.addEventListener('keyup', _onKeyUp);

        setOrientation(this);

        handleResize();
    }

    public function lookAt(x:Dynamic, y:Float = 0, z:Float = 0) {
        if (x.isVector3) {
            _target.copy(x);
        } else {
            _target.set(x, y, z);
        }

        object.lookAt(_target);

        setOrientation(this);

        return this;
    }

    public function dispose() {
        domElement.removeEventListener('contextmenu', contextmenu);
        domElement.removeEventListener('pointerdown', onPointerDown);
        domElement.removeEventListener('pointermove', onPointerMove);
        domElement.removeEventListener('pointerup', onPointerUp);

        window.removeEventListener('keydown', onKeyDown);
        window.removeEventListener('keyup', onKeyUp);
    }
}

function contextmenu(event:Dynamic) {
    event.preventDefault();
}