package;

import js.Browser.Window;
import js.html.Document;
import js.html.HtmlElement;
import js.html.PointerEvent;
import js.html.PointerType;
import js.html.WheelEvent;
import js.three.EventDispatcher;
import js.three.MathUtils;
import js.three.MouseEvent;
import js.three.Quaternion;
import js.three.Vector2;
import js.three.Vector3;

class TrackballControls extends EventDispatcher {
    private var scope:TrackballControls;
    private static var STATE = { NONE: -1, ROTATE: 0, ZOOM: 1, PAN: 2, TOUCH_ROTATE: 3, TOUCH_ZOOM_PAN: 4 };

    private var _changeEvent:Dynamic;
    private var _startEvent:Dynamic;
    private var _endEvent:Dynamic;

    private var _state:Int;
    private var _keyState:Int;
    private var _eye:Vector3;
    private var _movePrev:Vector2;
    private var _moveCurr:Vector2;
    private var _lastAxis:Vector3;
    private var _zoomStart:Vector2;
    private var _zoomEnd:Vector2;
    private var _panStart:Vector2;
    private var _panEnd:Vector2;
    private var _pointers:Array<PointerEvent>;
    private var _pointerPositions:Map<Int,Vector2>;

    public var object:Dynamic;
    public var domElement:HtmlElement;
    public var enabled:Bool;
    public var screen:Dynamic;
    public var rotateSpeed:Float;
    public var zoomSpeed:Float;
    public var panSpeed:Float;
    public var noRotate:Bool;
    public var noZoom:Bool;
    public var noPan:Bool;
    public var staticMoving:Bool;
    public var dynamicDampingFactor:Float;
    public var minDistance:Float;
    public var maxDistance:Float;
    public var minZoom:Float;
    public var maxZoom:Float;
    public var keys:Array<String>;
    public var mouseButtons:Dynamic;
    public var target:Vector3;
    private static var EPS:Float;
    private var lastPosition:Vector3;
    private var lastZoom:Float;

    public function new(object:Dynamic, domElement:HtmlElement) {
        super();
        scope = this;
        _changeEvent = { type: 'change' };
        _startEvent = { type: 'start' };
        _endEvent = { type: 'end' };
        _state = STATE.NONE;
        _keyState = STATE.NONE;
        _eye = new Vector3();
        _movePrev = new Vector2();
        _moveCurr = new Vector2();
        _lastAxis = new Vector3();
        _zoomStart = new Vector2();
        _zoomEnd = new Vector2();
        _panStart = new Vector2();
        _panEnd = new Vector2();
        _pointers = [];
        _pointerPositions = new Map();
        target = new Vector3();
        EPS = 0.000001;
        lastPosition = new Vector3();
        lastZoom = 1;

        this.object = object;
        this.domElement = domElement;
        this.domElement.style.touchAction = 'none'; // disable touch scroll

        // API

        this.enabled = true;

        this.screen = { left: 0, top: 0, width: 0, height: 0 };

        this.rotateSpeed = 1.0;
        this.zoomSpeed = 1.2;
        this.panSpeed = 0.3;

        this.noRotate = false;
        this.noZoom = false;
        this.noPan = false;

        this.staticMoving = false;
        this.dynamicDampingFactor = 0.2;

        this.minDistance = 0;
        this.maxDistance = Float.POSITIVE_INFINITY;

        this.minZoom = 0;
        this.maxZoom = Float.POSITIVE_INFINITY;

        this.keys = [ 'KeyA', 'KeyS', 'KeyD' ];

        this.mouseButtons = { LEFT: MOUSE.ROTATE, MIDDLE: MOUSE.DOLLY, RIGHT: MOUSE.PAN };

        // methods

        function handleResize() {
            var box = domElement.getBoundingClientRect();
            // adjustments come from similar code in the jquery offset() function
            var d = domElement.ownerDocument;
            screen.left = box.left + Window.pageXOffset - d.clientLeft;
            screen.top = box.top + Window.pageYOffset - d.clientTop;
            screen.width = box.width;
            screen.height = box.height;
        }

        function getMouseOnScreen(pageX:Int, pageY:Int):Vector2 {
            var vector = new Vector2((pageX - screen.left) / screen.width, (pageY - screen.top) / screen.height);
            return vector;
        }

        function getMouseOnCircle(pageX:Int, pageY:Int):Vector2 {
            var vector = new Vector2(((pageX - (screen.width * 0.5 + screen.left)) / (screen.width * 0.5)), ((screen.height + 2 * (screen.top - pageY)) / screen.width)); // screen.width intentional
            return vector;
        }

        function rotateCamera() {
            var axis = new Vector3();
            var quaternion = new Quaternion();
            var eyeDirection = new Vector3();
            var objectUpDirection = new Vector3();
            var objectSidewaysDirection = new Vector3();
            var moveDirection = new Vector3();

            moveDirection.set(_moveCurr.x - _movePrev.x, _movePrev.y - _movePrev.y, 0);
            var angle = moveDirection.length();

            if (angle != 0) {
                _eye.copy(object.position).sub(target);

                eyeDirection.copy(_eye).normalize();
                objectUpDirection.copy(object.up).normalize();
                objectSidewaysDirection.crossVectors(objectUpDirection, eyeDirection).normalize();

                objectUpDirection.setLength(_moveCurr.y - _movePrev.y);
                objectSidewaysDirection.setLength(_moveCurr.x - _movePrev.x);

                moveDirection.copy(objectUpDirection.add(objectSidewaysDirection));

                axis.crossVectors(moveDirection, _eye).normalize();

                angle *= rotateSpeed;
                quaternion.setFromAxisAngle(axis, angle);

                _eye.applyQuaternion(quaternion);
                object.up.applyQuaternion(quaternion);

                _lastAxis.copy(axis);
                _lastAngle = angle;
            } else if (!staticMoving && _lastAngle != 0) {
                _lastAngle *= Math.sqrt(1.0 - dynamicDampingFactor);
                _eye.copy(object.position).sub(target);
                quaternion.setFromAxisAngle(_lastAxis, _lastAngle);
                _eye.applyQuaternion(quaternion);
                object.up.applyQuaternion(quaternion);
            }

            _movePrev.copy(_moveCurr);
        }

        function zoomCamera() {
            var factor:Float;

            if (_state == STATE.TOUCH_ZOOM_PAN) {
                factor = _touchZoomDistanceStart / _touchZoomDistanceEnd;
                _touchZoomDistanceStart = _touchZoomDistanceEnd;

                if (object.isPerspectiveCamera) {
                    _eye.multiplyScalar(factor);
                } else if (object.isOrthographicCamera) {
                    object.zoom = MathUtils.clamp(object.zoom / factor, minZoom, maxZoom);

                    if (lastZoom != object.zoom) {
                        object.updateProjectionMatrix();
                    }
                } else {
                    trace('TrackballControls: Unsupported camera type');
                }
            } else {
                factor = 1.0 + (_zoomEnd.y - _zoomStart.y) * zoomSpeed;

                if (factor != 1.0 && factor > 0.0) {
                    if (object.isPerspectiveCamera) {
                        _eye.multiplyScalar(factor);
                    } else if (object.isOrthographicCamera) {
                        object.zoom = MathUtils.clamp(object.zoom / factor, minZoom, maxZoom);

                        if (lastZoom != object.zoom) {
                            object.updateProjectionMatrix();
                        }
                    } else {
                        trace('TrackballControls: Unsupported camera type');
                    }
                }

                if (staticMoving) {
                    _zoomStart.copy(_zoomEnd);
                } else {
                    _zoomStart.y += (_zoomEnd.y - _zoomStart.y) * dynamicDampingFactor;
                }
            }
        }

        function panCamera() {
            var mouseChange = new Vector2();
            var objectUp = new Vector3();
            var pan = new Vector3();

            mouseChange.copy(_panEnd).sub(_panStart);

            if (mouseChange.lengthSq() != 0) {
                if (object.isOrthographicCamera) {
                    var scale_x = (object.right - object.left) / object.zoom / domElement.clientWidth;
                    var scale_y = (object.top - object.bottom) / object.zoom / domElement.clientWidth;

                    mouseChange.x *= scale_x;
                    mouseChange.y *= scale_y;
                }

                mouseChange.multiplyScalar(_eye.length() * panSpeed);

                pan.copy(_eye).cross(object.up).setLength(mouseChange.x);
                pan.add(objectUp.copy(object.up).setLength(mouseChange.y));

                object.position.add(pan);
                target.add(pan);

                if (staticMoving) {
                    _panStart.copy(_panEnd);
                } else {
                    _panStart.add(mouseChange.subVectors(_panEnd, _panStart).multiplyScalar(dynamicDampingFactor));
                }
            }
        }

        function checkDistances() {
            if (!noZoom || !noPan) {
                if (_eye.lengthSq() > maxDistance * maxDistance) {
                    object.position.addVectors(target, _eye.setLength(maxDistance));
                    _zoomStart.copy(_zoomEnd);
                }

                if (_eye.lengthSq() < minDistance * minDistance) {
                    object.position.addVectors(target, _eye.setLength(minDistance));
                    _zoomStart.copy(_zoomEnd);
                }
            }
        }

        function update() {
            _eye.subVectors(object.position, target);

            if (!noRotate) {
                rotateCamera();
            }

            if (!noZoom) {
                zoomCamera();
            }

            if (!noPan) {
                panCamera();
            }

            object.position.addVectors(target, _eye);

            if (object.isPerspectiveCamera) {
                checkDistances();

                object.lookAt(target);

                if (lastPosition.distanceToSquared(object.position) > EPS) {
                    dispatchEvent(_changeEvent);

                    lastPosition.copy(object.position);
                }
            } else if (object.isOrthographicCamera) {
                object.lookAt(target);

                if (lastPosition.distanceToSquared(object.position) > EPS || lastZoom != object.zoom) {
                    dispatchEvent(_changeEvent);

                    lastPosition.copy(object.position);
                    lastZoom = object.zoom;
                }
            } else {
                trace('TrackballControls: Unsupported camera type');
            }
        }

        function reset() {
            _state = STATE.NONE;
            _keyState = STATE.NONE;

            target.copy(target0);
            object.position.copy(position0);
            object.up.copy(up0);
            object.zoom = zoom0;

            object.updateProjectionMatrix();

            _eye.subVectors(object.position, target);

            object.lookAt(target);

            dispatchEvent(_changeEvent);

            lastPosition.copy(object.position);
            lastZoom = object.zoom;
        }

        // listeners

        function onPointerDown(event:PointerEvent) {
            if (!enabled) return;

            if (_pointers.length == 0) {
                domElement.setPointerCapture(event.pointerId);

                domElement.addEventListener('pointermove', onPointerMove);
                domElement.addEventListener('pointerup', onPointerUp);
            }

            addPointer(event);

            if (event.pointerType == PointerType.TOUCH) {
                onTouchStart(event);
            } else {
                onMouseDown(event);
            }
        }

        function onPointerMove(event:PointerEvent) {
            if (!enabled) return;

            if (event.pointerType == PointerType.TOUCH) {
                onTouchMove(event);
            } else {
                onMouseMove(event);
            }
        }

        function onPointerUp(event:PointerEvent) {
            if (!enabled) return;

            if (event.pointerType == PointerType.TOUCH) {
                onTouchEnd(event);
            } else {
                onMouseUp();
            }

            removePointer(event);

            if (_pointers.length == 0) {
                domElement.releasePointerCapture(event.pointerId);

                domElement.removeEventListener('pointermove', onPointerMove);
                domElement.removeEventListener('pointerup', onPointerUp);
            }
        }

        function onPointerCancel(event:PointerEvent) {
            removePointer(event);
        }

        function keydown(event:Dynamic) {
            if (!enabled) return;

            Window.removeEventListener('keydown', keydown);

            if (_keyState != STATE.NONE) {
                return;
            } else if (event.code == keys[STATE.ROTATE] && !noRotate) {
                _keyState = STATE.ROTATE;
            } else if (event.code == keys[STATE.ZOOM] && !noZoom) {
                _keyState = STATE.ZOOM;
            } else if (event.code == keys[STATE.PAN] && !noPan) {
                _keyState = STATE.PAN;
            }
        }

        function keyup() {
            if (!enabled) return;

            _keyState = STATE.NONE;

            Window.addEventListener('keydown', keydown);
        }

        function onMouseDown(event:MouseEvent) {
            if (_state == STATE.NONE) {
                switch (event.button) {
                    case mouseButtons.LEFT:
                        _state = STATE.ROTATE;
                        break;
                    case mouseButtons.MIDDLE:
                        _state = STATE.ZOOM;
                        break;
                    case mouseButtons.RIGHT:
                        _state = STATE.PAN;
                        break;
                }
            }

            var state = (_keyState != STATE.NONE) ? _keyState : _state;

            if (state == STATE.ROTATE && !noRotate) {
                _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
                _movePrev.copy(_moveCurr);
            } else if (state == STATE.ZOOM && !noZoom) {
                _zoomStart.copy(getMouseOnScreen(event.pageX, event.pageY));
                _zoomEnd.copy(_zoomStart);
            } else if (state == STATE.PAN && !noPan) {
                _panStart.copy(getMouseOnScreen(event.pageX, event.pageY));
                _panEnd.copy(_panStart);
            }

            dispatchEvent(_startEvent);
        }

        function onMouseMove(event:MouseEvent) {
            var state = (_keyState != STATE.NONE) ? _keyState : _state;

            if (state == STATE.ROTATE && !noRotate) {
                _movePrev.copy(_moveCurr);
                _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
            } else if (state == STATE.ZOOM && !noZoom) {
                _zoomEnd.copy(getMouseOnScreen(event.pageX, event.pageY));
            } else if (state == STATE.PAN && !noPan) {
                _panEnd.copy(getMouseOnScreen(event.pageX, event.pageY));
            }
        }

        function onMouseUp() {
            _state = STATE.NONE;

            dispatchEvent(_endEvent);
        }

        function onMouseWheel(event:WheelEvent) {
            if (!enabled) return;

            if (noZoom) return;

            event.preventDefault();

            switch (event.deltaMode) {
                case 2:
                    // Zoom in pages
                    _zoomStart.y -= event.deltaY * 0.025;
                    break;
                case 1:
                    // Zoom in lines
                    _zoomStart.y -= event.deltaY * 0.01;
                    break;
                default:
                    // undefined, 0, assume pixels
                    _zoomStart.y -= event.deltaY * 0.00025;
                    break;
            }

            dispatchEvent(_startEvent);
            dispatchEvent(_endEvent);
        }

        function onTouchStart(event:PointerEvent) {
            trackPointer(event);

            switch (_pointers.length) {
                case 1:
                    _state = STATE.TOUCH_ROTATE;
                    _moveCurr.copy(getMouseOnCircle(_pointers[0].pageX, _pointers[0].pageY));
                    _movePrev.copy(_moveCurr);
                    break;
                default: // 2 or more
                    _state = STATE.TOUCH_ZOOM_PAN;
                    var dx = _pointers[0].pageX - _pointers[1].pageX;
                    var dy = _pointers[0].pageY - _pointers[1].pageY;
                    _touchZoomDistanceEnd = _touchZoomDistanceStart = Math.sqrt(dx * dx + dy * dy);

                    var x = (_pointers[0].pageX + _pointers[1].pageX) / 2;
                    var y = (_pointers[0].pageY + _pointers[1].pageY) / 2;
                    _panStart.copy(getMouseOnScreen(x, y));
                    _panEnd.copy(_panStart);
                    break;
            }

            dispatchEvent(_startEvent);
        }

        function onTouchMove(event:PointerEvent) {
            trackPointer
            trackPointer(event);

            switch (_pointers.length) {
                case 1:
                    _movePrev.copy(_moveCurr);
                    _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
                    break;
                default: // 2 or more

                    var position = getSecondPointerPosition(event);

                    var dx = event.pageX - position.x;
                    var dy = event.pageY - position.y;
                    _touchZoomDistanceEnd = Math.sqrt(dx * dx + dy * dy);

                    var x = (event.pageX + position.x) / 2;
                    var y = (event.pageY + position.y) / 2;
                    _panEnd.copy(getMouseOnScreen(x, y));
                    break;
            }
        }

        function onTouchEnd(event:PointerEvent) {
            switch (_pointers.length) {
                case 0:
                    _state = STATE.NONE;
                    break;
                case 1:
                    _state = STATE.TOUCH_ROTATE;
                    _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
                    _movePrev.copy(_moveCurr);
                    break;
                case 2:
                    _state = STATE.TOUCH_ZOOM_PAN;

                    for (i in 0..._pointers.length) {
                        if (_pointers[i].pointerId != event.pointerId) {
                            var position = _pointerPositions[_pointers[i].pointerId];
                            _moveCurr.copy(getMouseOnCircle(position.x, position.y));
                            _movePrev.copy(_moveCurr);
                            break;
                        }
                    }

                    break;
            }

            dispatchEvent(_endEvent);
        }

        function contextmenu(event:Dynamic) {
            if (enabled) {
                event.preventDefault();
            }
        }

        function addPointer(event:PointerEvent) {
            _pointers.push(event);
        }

        function removePointer(event:PointerEvent) {
            _pointerPositions.remove(event.pointerId);

            for (i in 0..._pointers.length) {
                if (_pointers[i].pointerId == event.pointerId) {
                    _pointers.splice(i, 1);
                    return;
                }
            }
        }

        function trackPointer(event:PointerEvent) {
            var position = _pointerPositions[event.pointerId];

            if (position == null) {
                position = new Vector2();
                _pointerPositions[event.pointerId] = position;
            }

            position.set(event.pageX, event.pageY);
        }

        function getSecondPointerPosition(event:PointerEvent):Vector2 {
            var pointer = (_pointers[0].pointerId == event.pointerId) ? _pointers[1] : _pointers[0];

            return _pointerPositions[pointer.pointerId];
        }

        public function dispose() {
            domElement.removeEventListener('contextmenu', contextmenu);

            domElement.removeEventListener('pointerdown', onPointerDown);
            domElement.removeEventListener('pointercancel', onPointerCancel);
            domElement.removeEventListener('wheel', onMouseWheel);

            domElement.removeEventListener('pointermove', onPointerMove);
            domElement.removeEventListener('pointerup', onPointerUp);

            Window.removeEventListener('keydown', keydown);
            Window.removeEventListener('keyup', keyup);
        }

        handleResize();

        // force an update at start
        update();
    }
}