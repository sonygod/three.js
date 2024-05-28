import h3d.Vector3;
import h3d.Quaternion;
import js.Browser;

class FlyControls {
    private static var _changeEvent:Dynamic = { type: 'change' };

    public var object:Dynamic;
    public var domElement:Dynamic;
    public var enabled:Bool;
    public var movementSpeed:Float;
    public var rollSpeed:Float;
    public var dragToLook:Bool;
    public var autoForward:Bool;

    private var _scope:FlyControls;
    private var _EPS:Float;
    private var _lastQuaternion:Quaternion;
    private var _lastPosition:Vector3;
    private var _tmpQuaternion:Quaternion;
    private var _status:Int;
    private var _moveState:Dynamic;
    private var _moveVector:Vector3;
    private var _rotationVector:Vector3;

    public function new(object:Dynamic, domElement:Dynamic) {
        _scope = this;
        _EPS = 0.000001;
        _lastQuaternion = new Quaternion();
        _lastPosition = new Vector3();
        _tmpQuaternion = new Quaternion();
        _status = 0;
        _moveState = { up: 0, down: 0, left: 0, right: 0, forward: 0, back: 0, pitchUp: 0, pitchDown: 0, yawLeft: 0, yawRight: 0, rollLeft: 0, rollRight: 0 };
        _moveVector = new Vector3(0, 0, 0);
        _rotationVector = new Vector3(0, 0, 0);

        this.object = object;
        this.domElement = domElement;
        this.enabled = true;
        this.movementSpeed = 1.0;
        this.rollSpeed = 0.005;
        this.dragToLook = false;
        this.autoForward = false;

        _keydown = function(event:Dynamic) {
            if (event.altKey || !enabled) {
                return;
            }
            switch (event.code) {
                case 'ShiftLeft':
                case 'ShiftRight':
                    _scope.movementSpeedMultiplier = .1;
                    break;
                case 'KeyW':
                    _scope._moveState.forward = 1;
                    break;
                case 'KeyS':
                    _scope._moveState.back = 1;
                    break;
                case 'KeyA':
                    _scope._moveState.left = 1;
                    break;
                case 'KeyD':
                    _scope._moveState.right = 1;
                    break;
                case 'KeyR':
                    _scope._moveState.up = 1;
                    break;
                case 'KeyF':
                    _scope._moveState.down = 1;
                    break;
                case 'ArrowUp':
                    _scope._moveState.pitchUp = 1;
                    break;
                case 'ArrowDown':
                    _scope._moveState.pitchDown = 1;
                    break;
                case 'ArrowLeft':
                    _scope._moveState.yawLeft = 1;
                    break;
                case 'ArrowRight':
                    _scope._moveState.yawRight = 1;
                    break;
                case 'KeyQ':
                    _scope._moveState.rollLeft = 1;
                    break;
                case 'KeyE':
                    _scope._moveState.rollRight = 1;
                    break;
            }
            _scope.updateMovementVector();
            _scope.updateRotationVector();
        };

        _keyup = function(event:Dynamic) {
            if (!enabled) {
                return;
            }
            switch (event.code) {
                case 'ShiftLeft':
                case 'ShiftRight':
                    _scope.movementSpeedMultiplier = 1;
                    break;
                case 'KeyW':
                    _scope._moveState.forward = 0;
                    break;
                case 'KeyS':
                    _scope._moveState.back = 0;
                    break;
                case 'KeyA':
                    _scope._moveState.left = 0;
                    break;
                case 'KeyD':
                    _scope._moveState.right = 0;
                    break;
                case 'KeyR':
                    _scope._moveState.up = 0;
                    break;
                case 'KeyF':
                    _scope._moveState.down = 0;
                    break;
                case 'ArrowUp':
                    _scope._moveState.pitchUp = 0;
                    break;
                case 'ArrowDown':
                    _scope._moveState.pitchDown = 0;
                    break;
                case 'ArrowLeft':
                    _scope._moveState.yawLeft = 0;
                    break;
                case 'ArrowRight':
                    _scope._moveState.yawRight = 0;
                    break;
                case 'KeyQ':
                    _scope._moveState.rollLeft = 0;
                    break;
                case 'KeyE':
                    _scope._moveState.rollRight = 0;
                    break;
            }
            _scope.updateMovementVector();
            _scope.updateRotationVector();
        };

        _pointerdown = function(event:Dynamic) {
            if (!enabled) {
                return;
            }
            if (dragToLook) {
                _status++;
            } else {
                switch (event.button) {
                    case 0:
                        _scope._moveState.forward = 1;
                        break;
                    case 2:
                        _scope._moveState.back = 1;
                        break;
                }
                _scope.updateMovementVector();
            }
        };

        _pointermove = function(event:Dynamic) {
            if (!enabled) {
                return;
            }
            if (!dragToLook || _status > 0) {
                var container = _scope.getContainerDimensions();
                var halfWidth = container.size[0] / 2;
                var halfHeight = container.size[1] / 2;
                _scope._moveState.yawLeft = -((event.pageX - container.offset[0]) - halfWidth) / halfWidth;
                _scope._moveState.pitchDown = ((event.pageY - container.offset[1]) - halfHeight) / halfHeight;
                _scope.updateRotationVector();
            }
        };

        _pointerup = function(event:Dynamic) {
            if (!enabled) {
                return;
            }
            if (dragToLook) {
                _status--;
                _scope._moveState.yawLeft = _scope._moveState.pitchDown = 0;
            } else {
                switch (event.button) {
                    case 0:
                        _scope._moveState.forward = 0;
                        break;
                    case 2:
                        _scope._moveState.back = 0;
                        break;
                }
                _scope.updateMovementVector();
            }
            _scope.updateRotationVector();
        };

        _pointercancel = function() {
            if (!enabled) {
                return;
            }
            if (dragToLook) {
                _status = 0;
                _scope._moveState.yawLeft = _scope._moveState.pitchDown = 0;
            } else {
                _scope._moveState.forward = 0;
                _scope._moveState.back = 0;
                _scope.updateMovementVector();
            }
            _scope.updateRotationVector();
        };

        _contextmenu = function(event:Dynamic) {
            if (enabled) {
                event.preventDefault();
            }
        };

        _update = function(delta:Float) {
            if (!enabled) {
                return;
            }
            var moveMult = delta * _scope.movementSpeed;
            var rotMult = delta * _scope.rollSpeed;
            _scope.object.translateX(_scope._moveVector.x * moveMult);
            _scope.object.translateY(_scope._moveVector.y * moveMult);
            _scope.object.translateZ(_scope._moveVector.z * moveMult);
            _scope._tmpQuaternion.set(_scope._rotationVector.x * rotMult, _scope._rotationVector.y * rotMult, _scope._rotationVector.z * rotMult, 1).normalize();
            _scope.object.quaternion.multiply(_scope._tmpQuaternion);
            if (
                _lastPosition.distanceToSquared(_scope.object.position) > _EPS ||
                8 * (1 - _lastQuaternion.dot(_scope.object.quaternion)) > _EPS
            ) {
                _scope.dispatchEvent(_changeEvent);
                _lastQuaternion.copy(_scope.object.quaternion);
                _lastPosition.copy(_scope.object.position);
            }
        };

        _updateMovementVector = function() {
            var forward = (_moveState.forward || (autoForward && !_moveState.back)) ? 1 : 0;
            _moveVector.x = (-_moveState.left + _moveState.right);
            _moveVector.y = (-_moveState.down + _moveState.up);
            _moveVector.z = (-forward + _moveState.back);
        };

        _updateRotationVector = function() {
            _rotationVector.x = (-_moveState.pitchDown + _moveState.pitchUp);
            _rotationVector.y = (-_moveState.yawRight + _moveState.yawLeft);
            _rotationVector.z = (-_moveState.rollRight + _moveState.rollLeft);
        };

        _getContainerDimensions = function() {
            if (domElement != Browser.document) {
                return {
                    size: [domElement.offsetWidth, domElement.offsetHeight],
                    offset: [domElement.offsetLeft, domElement.offsetTop]
                };
            } else {
                return {
                    size: [Browser.window.innerWidth, Browser.window.innerHeight],
                    offset: [0, 0]
                };
            }
        };

        _dispose = function() {
            domElement.removeEventListener('contextmenu', _contextmenu);
            domElement.removeEventListener('pointerdown', _pointerdown);
            domElement.removeEventListener('pointermove', _pointermove);
            domElement.removeEventListener('pointerup', _pointerup);
            domElement.removeEventListener('pointercancel', _pointercancel);
            Browser.window.removeEventListener('keydown', _keydown);
            Browser.window.removeEventListener('keyup', _keyup);
        };

        domElement.addEventListener('contextmenu', _contextmenu);
        domElement.addEventListener('pointerdown', _pointerdown);
        domElement.addEventListener('pointermove', _pointermove);
        domElement.addEventListener('pointerup', _pointerup);
        domElement.addEventListener('pointercancel', _pointercancel);
        Browser.window.addEventListener('keydown', _keydown);
        Browser.window.addEventListener('keyup', _keyup);

        _updateMovementVector();
        _updateRotationVector();
    }
}