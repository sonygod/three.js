package three.js.examples.jsm.controls;

import js.html.Window;
import js.html.Performance;
import js.html.MouseEvent;
import js.html.TouchEvent;
import js.Browser;
import three.MathUtils;
import three.Matrix4;
import three.Object3D;
import three.PerspectiveCamera;
import three.OrthographicCamera;
import three.Raycaster;
import three.Vector3;
import three.Vector2;

class ArcballControls {
    var _state:Int;
    var _timeCurrent:Float;
    var _timeStart:Float;
    var _animationId:Int;
    var _wPrev:Float;
    var _wCurr:Float;
    var _cursorPosPrev:Vector2;
    var _cursorPosCurr:Vector2;
    var _startCursorPosition:Vector3;
    var _currentCursorPosition:Vector3;
    var _startFingerRotation:Float;
    var _currentFingerRotation:Float;
    var _startFingerDistance:Float;
    var _currentFingerDistance:Float;
    var _devPxRatio:Float;
    var _v3_1:Vector3;
    var _v3_2:Vector3;
    var _m4_1:Matrix4;
    var _center:Vector2;
    var _offset:Vector3;
    var _gizmoMatrixState:Matrix4;
    var _cameraMatrixState:Matrix4;
    var _fovState:Float;
    var _scaleFactor:Float;
    var _minDistance:Float;
    var _maxDistance:Float;
    var _minFov:Float;
    var _maxFov:Float;
    var _touchCurrent:Array<Touch>;
    var _touchStart:Array<Touch>;
    var camera:PerspectiveCamera;
    var domElement:js.html.HtmlElement;
    var enabled:Bool;
    var enableRotate:Bool;
    var enablePan:Bool;
    var enableZoom:Bool;
    var enableAnimations:Bool;
    var enableGrid:Bool;
    var _changeEvent:Event;
    var _endEvent:Event;
    var _startEvent:Event;

    public function new() {
        _state = 0;
        _timeCurrent = 0;
        _timeStart = 0;
        _animationId = -1;
        _wPrev = 0;
        _wCurr = 0;
        _cursorPosPrev = new Vector2();
        _cursorPosCurr = new Vector2();
        _startCursorPosition = new Vector3();
        _currentCursorPosition = new Vector3();
        _startFingerRotation = 0;
        _currentFingerRotation = 0;
        _startFingerDistance = 0;
        _currentFingerDistance = 0;
        _devPxRatio = 1;
        _v3_1 = new Vector3();
        _v3_2 = new Vector3();
        _m4_1 = new Matrix4();
        _center = new Vector2();
        _offset = new Vector3();
        _gizmoMatrixState = new Matrix4();
        _cameraMatrixState = new Matrix4();
        _fovState = 0;
        _scaleFactor = 1;
        _minDistance = 0;
        _maxDistance = 100;
        _minFov = 10;
        _maxFov = 120;
        _touchCurrent = [];
        _touchStart = [];
        camera = null;
        domElement = null;
        enabled = true;
        enableRotate = true;
        enablePan = true;
        enableZoom = true;
        enableAnimations = true;
        enableGrid = true;
        _changeEvent = new Event('change');
        _endEvent = new Event('end');
        _startEvent = new Event('start');
    }

    public function onSinglePanEnd():Void {
        if (_state == STATE.ROTATE) {
            if (!enableRotate) return;
            if (enableAnimations) {
                var deltaTime:Float = (Browser.window.performance.now() - _timeCurrent);
                if (deltaTime < 120) {
                    var w:Float = Math.abs((_wPrev + _wCurr) / 2);
                    Browser.window.requestAnimationFrame(function(t:Float) {
                        updateTbState(STATE.ANIMATION_ROTATE, true);
                        var rotationAxis:Vector3 = calculateRotationAxis(_cursorPosPrev, _cursorPosCurr);
                        onRotationAnim(t, rotationAxis, Math.min(w, _wMax));
                    });
                } else {
                    updateTbState(STATE.IDLE, false);
                    activateGizmos(false);
                    dispatchEvent(_changeEvent);
                }
            } else {
                updateTbState(STATE.IDLE, false);
                activateGizmos(false);
                dispatchEvent(_changeEvent);
            }
        } else if (_state == STATE.PAN || _state == STATE.IDLE) {
            updateTbState(STATE.IDLE, false);
            if (enableGrid) {
                disposeGrid();
            }
            activateGizmos(false);
            dispatchEvent(_changeEvent);
        }
        dispatchEvent(_endEvent);
    }

    public function onDoubleTap(event:TouchEvent):Void {
        if (enabled && enablePan && camera != null) {
            dispatchEvent(_startEvent);
            setCenter(event.clientX, event.clientY);
            var hitP:Vector3 = unprojectOnObj(getCursorNDC(_center.x, _center.y, domElement), camera);
            if (hitP != null && enableAnimations) {
                if (_animationId != -1) {
                    Browser.window.cancelAnimationFrame(_animationId);
                }
                _timeStart = -1;
                _animationId = Browser.window.requestAnimationFrame(function(t:Float) {
                    updateTbState(STATE.ANIMATION_FOCUS, true);
                    onFocusAnim(t, hitP, _cameraMatrixState, _gizmoMatrixState);
                });
            } else if (hitP != null && !enableAnimations) {
                updateTbState(STATE.FOCUS, true);
                focus(hitP, _scaleFactor);
                updateTbState(STATE.IDLE, false);
                dispatchEvent(_changeEvent);
            }
        }
        dispatchEvent(_endEvent);
    }

    public function onDoublePanStart():Void {
        if (enabled && enablePan) {
            dispatchEvent(_startEvent);
            updateTbState(STATE.PAN, true);
            setCenter(((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2), ((_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2));
            _startCursorPosition.copy(unprojectOnTbPlane(camera, _center.x, _center.y, domElement, true));
            _currentCursorPosition.copy(_startCursorPosition);
            activateGizmos(false);
        }
    }

    public function onDoublePanMove():Void {
        if (enabled && enablePan) {
            setCenter(((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2), ((_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2));
            if (_state != STATE.PAN) {
                updateTbState(STATE.PAN, true);
                _startCursorPosition.copy(_currentCursorPosition);
            }
            _currentCursorPosition.copy(unprojectOnTbPlane(camera, _center.x, _center.y, domElement, true));
            applyTransformMatrix(pan(_startCursorPosition, _currentCursorPosition, true));
            dispatchEvent(_changeEvent);
        }
    }

    public function onDoublePanEnd():Void {
        updateTbState(STATE.IDLE, false);
        dispatchEvent(_endEvent);
    }

    public function onRotateStart():Void {
        if (enabled && enableRotate) {
            dispatchEvent(_startEvent);
            updateTbState(STATE.ZROTATE, true);
            _startFingerRotation = getAngle(_touchCurrent[1], _touchCurrent[0]) + getAngle(_touchStart[1], _touchStart[0]);
            _currentFingerRotation = _startFingerRotation;
            camera.getWorldDirection(_rotationAxis); //rotation axis
            if (!enablePan && !enableZoom) {
                activateGizmos(true);
            }
        }
    }

    public function onRotateMove():Void {
        if (enabled && enableRotate) {
            setCenter(((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2), ((_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2));
            var rotationPoint:Vector3;
            if (_state != STATE.ZROTATE) {
                updateTbState(STATE.ZROTATE, true);
                _startFingerRotation = _currentFingerRotation;
            }
            _currentFingerRotation = getAngle(_touchCurrent[1], _touchCurrent[0]) + getAngle(_touchStart[1], _touchStart[0]);
            if (!enablePan) {
                rotationPoint = new Vector3().setFromMatrixPosition(_gizmoMatrixState);
            } else {
                _v3_2.setFromMatrixPosition(_gizmoMatrixState);
                rotationPoint = unprojectOnTbPlane(camera, _center.x, _center.y, domElement).applyQuaternion(camera.quaternion).multiplyScalar(1 / camera.zoom).add(_v3_2);
            }
            var amount:Float = MathUtils.DEG2RAD * (_startFingerRotation - _currentFingerRotation);
            applyTransformMatrix(zRotate(rotationPoint, amount));
            dispatchEvent(_changeEvent);
        }
    }

    public function onRotateEnd():Void {
        updateTbState(STATE.IDLE, false);
        activateGizmos(false);
        dispatchEvent(_endEvent);
    }

    public function onPinchStart():Void {
        if (enabled && enableZoom) {
            dispatchEvent(_startEvent);
            updateTbState(STATE.SCALE, true);
            _startFingerDistance = calculatePointersDistance(_touchCurrent[0], _touchCurrent[1]);
            _currentFingerDistance = _startFingerDistance;
            activateGizmos(false);
        }
    }

    public function onPinchMove():Void {
        if (enabled && enableZoom) {
            setCenter(((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2), ((_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2));
            var minDistance:Float = 12; //minimum distance between fingers (in css pixels)
            if (_state != STATE.SCALE) {
                _startFingerDistance = _currentFingerDistance;
                updateTbState(STATE.SCALE, true);
            }
            _currentFingerDistance = Math.max(calculatePointersDistance(_touchCurrent[0], _touchCurrent[1]), minDistance * _devPxRatio);
            var amount:Float = _currentFingerDistance / _startFingerDistance;
            var scalePoint:Vector3;
            if (!enablePan) {
                scalePoint = _gizmos.position;
            } else {
                if (camera.isOrthographicCamera) {
                    scalePoint = unprojectOnTbPlane(camera, _center.x, _center.y, domElement).applyQuaternion(camera.quaternion).multiplyScalar(1 / camera.zoom).add(_gizmos.position);
                } else if (camera.isPerspectiveCamera) {
                    scalePoint = unprojectOnTbPlane(camera, _center.x, _center.y, domElement).applyQuaternion(camera.quaternion).add(_gizmos.position);
                }
            }
            applyTransformMatrix(scale(amount, scalePoint));
            dispatchEvent(_changeEvent);
        }
    }

    public function onPinchEnd():Void {
        updateTbState(STATE.IDLE, false);
        dispatchEvent(_endEvent);
    }

    public function onTriplePanStart():Void {
        if (enabled && enableZoom) {
            dispatchEvent(_startEvent);
            updateTbState(STATE.SCALE, true);
            var clientX:Float = 0;
            var clientY:Float = 0;
            var nFingers:Int = _touchCurrent.length;
            for (i in 0...nFingers) {
                clientX += _touchCurrent[i].clientX;
                clientY += _touchCurrent[i].clientY;
            }
            setCenter(clientX / nFingers, clientY / nFingers);
            _startCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
            _currentCursorPosition.copy(_startCursorPosition);
        }
    }

    public function onTriplePanMove():Void {
        if (enabled && enableZoom) {
            var clientX:Float = 0;
            var clientY:Float = 0;
            var nFingers:Int = _touchCurrent.length;
            for (i in 0...nFingers) {
                clientX += _touchCurrent[i].clientX;
                clientY += _touchCurrent[i].clientY;
            }
            setCenter(clientX / nFingers, clientY / nFingers);
            _currentCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
            var movement:Float = _currentCursorPosition.y - _startCursorPosition.y;
            var size:Float = 1;
            if (movement < 0) {
                size = 1 / Math.pow(_scaleFactor, -movement * screenNotches);
            } else if (movement > 0) {
                size = Math.pow(_scaleFactor, movement * screenNotches);
            }
            _v3_1.setFromMatrixPosition(_cameraMatrixState);
            var x:Float = _v3_1.distanceTo(_gizmos.position);
            var xNew:Float = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed
            xNew = MathUtils.clamp(xNew, _minDistance, _maxDistance);
            var y:Float = x * Math.tan(MathUtils.DEG2RAD * _fovState * 0.5);
            var newFov:Float = MathUtils.RAD2DEG * (Math.atan(y / xNew) * 2);
            newFov = MathUtils.clamp(newFov, _minFov, _maxFov);
            var newDistance:Float = y / Math.tan(MathUtils.DEG2RAD * (newFov / 2));
            size = x / newDistance;
            _v3_2.setFromMatrixPosition(_gizmoMatrixState);
            setFov(newFov);
            applyTransformMatrix(scale(size, _v3_2, false));
            dispatchEvent(_changeEvent);
        }
    }

    public function onTriplePanEnd():Void {
        updateTbState(STATE.IDLE, false);
        dispatchEvent(_endEvent);
    }

    public function setCenter(clientX:Float, clientY:Float):Void {
        _center.x = clientX;
        _center.y = clientY;
    }

    public function initializeMouseActions():Void {
        setMouseAction('PAN', 0, 'CTRL');
        setMouseAction('PAN', 2);

        setMouseAction('ROTATE', 0);

        setMouseAction('ZOOM', 'WHEEL');
        setMouseAction('ZOOM', 1);

        setMouseAction('FOV', 'WHEEL', 'SHIFT');
        setMouseAction('FOV', 1, 'SHIFT');
    }

    public function compareMouseAction(action1:Object, action2:Object):Bool {
        if (action1.operation == action2.operation) {
            if (action1.mouse == action2.mouse && action1.key == action2.key) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
}