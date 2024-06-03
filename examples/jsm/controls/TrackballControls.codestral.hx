import three.EventDispatcher;
import three.MathUtils;
import three.MOUSE;
import three.Quaternion;
import three.Vector2;
import three.Vector3;

class TrackballControls extends EventDispatcher {
    public var object:Object;
    public var domElement:Element;

    public var enabled:Bool = true;
    public var screen:Dynamic = { left: 0, top: 0, width: 0, height: 0 };
    public var rotateSpeed:Float = 1.0;
    public var zoomSpeed:Float = 1.2;
    public var panSpeed:Float = 0.3;
    public var noRotate:Bool = false;
    public var noZoom:Bool = false;
    public var noPan:Bool = false;
    public var staticMoving:Bool = false;
    public var dynamicDampingFactor:Float = 0.2;
    public var minDistance:Float = 0;
    public var maxDistance:Float = Float.POSITIVE_INFINITY;
    public var minZoom:Float = 0;
    public var maxZoom:Float = Float.POSITIVE_INFINITY;
    public var keys:Array<String> = ['KeyA', 'KeyS', 'KeyD'];
    public var mouseButtons:Dynamic = { LEFT: MOUSE.ROTATE, MIDDLE: MOUSE.DOLLY, RIGHT: MOUSE.PAN };

    public var target:Vector3;
    private var _changeEvent:Dynamic = { type: 'change' };
    private var _startEvent:Dynamic = { type: 'start' };
    private var _endEvent:Dynamic = { type: 'end' };
    private var STATE:Dynamic = { NONE: -1, ROTATE: 0, ZOOM: 1, PAN: 2, TOUCH_ROTATE: 3, TOUCH_ZOOM_PAN: 4 };
    private var EPS:Float = 0.000001;
    private var lastPosition:Vector3 = new Vector3();
    private var lastZoom:Float = 1;
    private var _state:Int = STATE.NONE;
    private var _keyState:Int = STATE.NONE;
    private var _touchZoomDistanceStart:Float = 0;
    private var _touchZoomDistanceEnd:Float = 0;
    private var _lastAngle:Float = 0;
    private var _eye:Vector3 = new Vector3();
    private var _movePrev:Vector2 = new Vector2();
    private var _moveCurr:Vector2 = new Vector2();
    private var _lastAxis:Vector3 = new Vector3();
    private var _zoomStart:Vector2 = new Vector2();
    private var _zoomEnd:Vector2 = new Vector2();
    private var _panStart:Vector2 = new Vector2();
    private var _panEnd:Vector2 = new Vector2();
    private var _pointers:Array<Dynamic> = [];
    private var _pointerPositions:Dynamic = {};
    public var target0:Vector3;
    public var position0:Vector3;
    public var up0:Vector3;
    public var zoom0:Float;

    public function new(object:Object, domElement:Element) {
        super();
        this.object = object;
        this.domElement = domElement;
        this.domElement.style.touchAction = 'none';

        this.target = new Vector3();
        this.target0 = this.target.clone();
        this.position0 = this.object.position.clone();
        this.up0 = this.object.up.clone();
        this.zoom0 = this.object.zoom;

        this.domElement.addEventListener('contextmenu', ($event) => this.contextmenu($event));
        this.domElement.addEventListener('pointerdown', ($event) => this.onPointerDown($event));
        this.domElement.addEventListener('pointercancel', ($event) => this.onPointerCancel($event));
        this.domElement.addEventListener('wheel', ($event) => this.onMouseWheel($event), { passive: false });
        window.addEventListener('keydown', ($event) => this.keydown($event));
        window.addEventListener('keyup', ($event) => this.keyup($event));

        this.handleResize();
        this.update();
    }

    public function handleResize():Void {
        var box:Dynamic = this.domElement.getBoundingClientRect();
        var d:Element = this.domElement.ownerDocument.documentElement;
        this.screen.left = box.left + window.pageXOffset - d.clientLeft;
        this.screen.top = box.top + window.pageYOffset - d.clientTop;
        this.screen.width = box.width;
        this.screen.height = box.height;
    }

    private function getMouseOnScreen(pageX:Float, pageY:Float):Vector2 {
        var vector:Vector2 = new Vector2();
        vector.set(
            (pageX - this.screen.left) / this.screen.width,
            (pageY - this.screen.top) / this.screen.height
        );
        return vector;
    }

    private function getMouseOnCircle(pageX:Float, pageY:Float):Vector2 {
        var vector:Vector2 = new Vector2();
        vector.set(
            ((pageX - this.screen.width * 0.5 - this.screen.left) / (this.screen.width * 0.5)),
            ((this.screen.height + 2 * (this.screen.top - pageY)) / this.screen.width)
        );
        return vector;
    }

    public function rotateCamera():Void {
        var axis:Vector3 = new Vector3();
        var quaternion:Quaternion = new Quaternion();
        var eyeDirection:Vector3 = new Vector3();
        var objectUpDirection:Vector3 = new Vector3();
        var objectSidewaysDirection:Vector3 = new Vector3();
        var moveDirection:Vector3 = new Vector3();

        moveDirection.set(_moveCurr.x - _movePrev.x, _moveCurr.y - _movePrev.y, 0);
        var angle:Float = moveDirection.length();

        if (angle > 0) {
            _eye.copy(this.object.position).sub(this.target);
            eyeDirection.copy(_eye).normalize();
            objectUpDirection.copy(this.object.up).normalize();
            objectSidewaysDirection.crossVectors(objectUpDirection, eyeDirection).normalize();

            objectUpDirection.setLength(_moveCurr.y - _movePrev.y);
            objectSidewaysDirection.setLength(_moveCurr.x - _movePrev.x);

            moveDirection.copy(objectUpDirection.add(objectSidewaysDirection));
            axis.crossVectors(moveDirection, _eye).normalize();

            angle *= this.rotateSpeed;
            quaternion.setFromAxisAngle(axis, angle);

            _eye.applyQuaternion(quaternion);
            this.object.up.applyQuaternion(quaternion);

            _lastAxis.copy(axis);
            _lastAngle = angle;
        } else if (!this.staticMoving && _lastAngle > 0) {
            _lastAngle *= Math.sqrt(1.0 - this.dynamicDampingFactor);
            _eye.copy(this.object.position).sub(this.target);
            quaternion.setFromAxisAngle(_lastAxis, _lastAngle);
            _eye.applyQuaternion(quaternion);
            this.object.up.applyQuaternion(quaternion);
        }

        _movePrev.copy(_moveCurr);
    }

    public function zoomCamera():Void {
        var factor:Float;

        if (_state === STATE.TOUCH_ZOOM_PAN) {
            factor = _touchZoomDistanceStart / _touchZoomDistanceEnd;
            _touchZoomDistanceStart = _touchZoomDistanceEnd;

            if (this.object.isPerspectiveCamera) {
                _eye.multiplyScalar(factor);
            } else if (this.object.isOrthographicCamera) {
                this.object.zoom = MathUtils.clamp(this.object.zoom / factor, this.minZoom, this.maxZoom);
                if (lastZoom !== this.object.zoom) {
                    this.object.updateProjectionMatrix();
                }
            } else {
                console.warn('THREE.TrackballControls: Unsupported camera type');
            }
        } else {
            factor = 1.0 + (_zoomEnd.y - _zoomStart.y) * this.zoomSpeed;

            if (factor !== 1.0 && factor > 0.0) {
                if (this.object.isPerspectiveCamera) {
                    _eye.multiplyScalar(factor);
                } else if (this.object.isOrthographicCamera) {
                    this.object.zoom = MathUtils.clamp(this.object.zoom / factor, this.minZoom, this.maxZoom);
                    if (lastZoom !== this.object.zoom) {
                        this.object.updateProjectionMatrix();
                    }
                } else {
                    console.warn('THREE.TrackballControls: Unsupported camera type');
                }
            }

            if (this.staticMoving) {
                _zoomStart.copy(_zoomEnd);
            } else {
                _zoomStart.y += (_zoomEnd.y - _zoomStart.y) * this.dynamicDampingFactor;
            }
        }
    }

    public function panCamera():Void {
        var mouseChange:Vector2 = new Vector2();
        var objectUp:Vector3 = new Vector3();
        var pan:Vector3 = new Vector3();

        mouseChange.copy(_panEnd).sub(_panStart);

        if (mouseChange.lengthSq() > 0) {
            if (this.object.isOrthographicCamera) {
                var scale_x:Float = (this.object.right - this.object.left) / this.object.zoom / this.domElement.clientWidth;
                var scale_y:Float = (this.object.top - this.object.bottom) / this.object.zoom / this.domElement.clientWidth;

                mouseChange.x *= scale_x;
                mouseChange.y *= scale_y;
            }

            mouseChange.multiplyScalar(_eye.length() * this.panSpeed);

            pan.copy(_eye).cross(this.object.up).setLength(mouseChange.x);
            pan.add(objectUp.copy(this.object.up).setLength(mouseChange.y));

            this.object.position.add(pan);
            this.target.add(pan);

            if (this.staticMoving) {
                _panStart.copy(_panEnd);
            } else {
                _panStart.add(mouseChange.subVectors(_panEnd, _panStart).multiplyScalar(this.dynamicDampingFactor));
            }
        }
    }

    public function checkDistances():Void {
        if (!this.noZoom || !this.noPan) {
            if (_eye.lengthSq() > this.maxDistance * this.maxDistance) {
                this.object.position.addVectors(this.target, _eye.setLength(this.maxDistance));
                _zoomStart.copy(_zoomEnd);
            }

            if (_eye.lengthSq() < this.minDistance * this.minDistance) {
                this.object.position.addVectors(this.target, _eye.setLength(this.minDistance));
                _zoomStart.copy(_zoomEnd);
            }
        }
    }

    public function update():Void {
        _eye.subVectors(this.object.position, this.target);

        if (!this.noRotate) {
            this.rotateCamera();
        }

        if (!this.noZoom) {
            this.zoomCamera();
        }

        if (!this.noPan) {
            this.panCamera();
        }

        this.object.position.addVectors(this.target, _eye);

        if (this.object.isPerspectiveCamera) {
            this.checkDistances();
            this.object.lookAt(this.target);

            if (lastPosition.distanceToSquared(this.object.position) > EPS) {
                this.dispatchEvent(_changeEvent);
                lastPosition.copy(this.object.position);
            }
        } else if (this.object.isOrthographicCamera) {
            this.object.lookAt(this.target);

            if (lastPosition.distanceToSquared(this.object.position) > EPS || lastZoom !== this.object.zoom) {
                this.dispatchEvent(_changeEvent);
                lastPosition.copy(this.object.position);
                lastZoom = this.object.zoom;
            }
        } else {
            console.warn('THREE.TrackballControls: Unsupported camera type');
        }
    }

    public function reset():Void {
        _state = STATE.NONE;
        _keyState = STATE.NONE;

        this.target.copy(this.target0);
        this.object.position.copy(this.position0);
        this.object.up.copy(this.up0);
        this.object.zoom = this.zoom0;

        this.object.updateProjectionMatrix();

        _eye.subVectors(this.object.position, this.target);

        this.object.lookAt(this.target);

        this.dispatchEvent(_changeEvent);

        lastPosition.copy(this.object.position);
        lastZoom = this.object.zoom;
    }

    private function onPointerDown(event:Dynamic):Void {
        if (this.enabled === false) return;

        if (_pointers.length === 0) {
            this.domElement.setPointerCapture(event.pointerId);
            this.domElement.addEventListener('pointermove', ($event) => this.onPointerMove($event));
            this.domElement.addEventListener('pointerup', ($event) => this.onPointerUp($event));
        }

        addPointer(event);

        if (event.pointerType === 'touch') {
            onTouchStart(event);
        } else {
            onMouseDown(event);
        }
    }

    private function onPointerMove(event:Dynamic):Void {
        if (this.enabled === false) return;

        if (event.pointerType === 'touch') {
            onTouchMove(event);
        } else {
            onMouseMove(event);
        }
    }

    private function onPointerUp(event:Dynamic):Void {
        if (this.enabled === false) return;

        if (event.pointerType === 'touch') {
            onTouchEnd(event);
        } else {
            onMouseUp();
        }

        removePointer(event);

        if (_pointers.length === 0) {
            this.domElement.releasePointerCapture(event.pointerId);
            this.domElement.removeEventListener('pointermove', ($event) => this.onPointerMove($event));
            this.domElement.removeEventListener('pointerup', ($event) => this.onPointerUp($event));
        }
    }

    private function onPointerCancel(event:Dynamic):Void {
        removePointer(event);
    }

    private function keydown(event:Dynamic):Void {
        if (this.enabled === false) return;

        window.removeEventListener('keydown', ($event) => this.keydown($event));

        if (_keyState !== STATE.NONE) {
            return;
        } else if (event.code === this.keys[STATE.ROTATE] && !this.noRotate) {
            _keyState = STATE.ROTATE;
        } else if (event.code === this.keys[STATE.ZOOM] && !this.noZoom) {
            _keyState = STATE.ZOOM;
        } else if (event.code === this.keys[STATE.PAN] && !this.noPan) {
            _keyState = STATE.PAN;
        }
    }

    private function keyup():Void {
        if (this.enabled === false) return;

        _keyState = STATE.NONE;

        window.addEventListener('keydown', ($event) => this.keydown($event));
    }

    private function onMouseDown(event:Dynamic):Void {
        if (_state === STATE.NONE) {
            switch (event.button) {
                case this.mouseButtons.LEFT:
                    _state = STATE.ROTATE;
                    break;
                case this.mouseButtons.MIDDLE:
                    _state = STATE.ZOOM;
                    break;
                case this.mouseButtons.RIGHT:
                    _state = STATE.PAN;
                    break;
            }
        }

        var state:Int = (_keyState !== STATE.NONE) ? _keyState : _state;

        if (state === STATE.ROTATE && !this.noRotate) {
            _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
            _movePrev.copy(_moveCurr);
        } else if (state === STATE.ZOOM && !this.noZoom) {
            _zoomStart.copy(getMouseOnScreen(event.pageX, event.pageY));
            _zoomEnd.copy(_zoomStart);
        } else if (state === STATE.PAN && !this.noPan) {
            _panStart.copy(getMouseOnScreen(event.pageX, event.pageY));
            _panEnd.copy(_panStart);
        }

        this.dispatchEvent(_startEvent);
    }

    private function onMouseMove(event:Dynamic):Void {
        var state:Int = (_keyState !== STATE.NONE) ? _keyState : _state;

        if (state === STATE.ROTATE && !this.noRotate) {
            _movePrev.copy(_moveCurr);
            _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
        } else if (state === STATE.ZOOM && !this.noZoom) {
            _zoomEnd.copy(getMouseOnScreen(event.pageX, event.pageY));
        } else if (state === STATE.PAN && !this.noPan) {
            _panEnd.copy(getMouseOnScreen(event.pageX, event.pageY));
        }
    }

    private function onMouseUp():Void {
        _state = STATE.NONE;
        this.dispatchEvent(_endEvent);
    }

    private function onMouseWheel(event:Dynamic):Void {
        if (this.enabled === false) return;
        if (this.noZoom === true) return;

        event.preventDefault();

        switch (event.deltaMode) {
            case 2:
                _zoomStart.y -= event.deltaY * 0.025;
                break;
            case 1:
                _zoomStart.y -= event.deltaY * 0.01;
                break;
            default:
                _zoomStart.y -= event.deltaY * 0.00025;
                break;
        }

        this.dispatchEvent(_startEvent);
        this.dispatchEvent(_endEvent);
    }

    private function onTouchStart(event:Dynamic):Void {
        trackPointer(event);

        switch (_pointers.length) {
            case 1:
                _state = STATE.TOUCH_ROTATE;
                _moveCurr.copy(getMouseOnCircle(_pointers[0].pageX, _pointers[0].pageY));
                _movePrev.copy(_moveCurr);
                break;
            default:
                _state = STATE.TOUCH_ZOOM_PAN;
                var dx:Float = _pointers[0].pageX - _pointers[1].pageX;
                var dy:Float = _pointers[0].pageY - _pointers[1].pageY;
                _touchZoomDistanceEnd = _touchZoomDistanceStart = Math.sqrt(dx * dx + dy * dy);

                var x:Float = (_pointers[0].pageX + _pointers[1].pageX) / 2;
                var y:Float = (_pointers[0].pageY + _pointers[1].pageY) / 2;
                _panStart.copy(getMouseOnScreen(x, y));
                _panEnd.copy(_panStart);
                break;
        }

        this.dispatchEvent(_startEvent);
    }

    private function onTouchMove(event:Dynamic):Void {
        trackPointer(event);

        switch (_pointers.length) {
            case 1:
                _movePrev.copy(_moveCurr);
                _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
                break;
            default:
                var position:Dynamic = getSecondPointerPosition(event);

                var dx:Float = event.pageX - position.x;
                var dy:Float = event.pageY - position.y;
                _touchZoomDistanceEnd = Math.sqrt(dx * dx + dy * dy);

                var x:Float = (event.pageX + position.x) / 2;
                var y:Float = (event.pageY + position.y) / 2;
                _panEnd.copy(getMouseOnScreen(x, y));
                break;
        }
    }

    private function onTouchEnd(event:Dynamic):Void {
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

                for (var i:Int = 0; i < _pointers.length; i++) {
                    if (_pointers[i].pointerId !== event.pointerId) {
                        var position:Dynamic = _pointerPositions[_pointers[i].pointerId];
                        _moveCurr.copy(getMouseOnCircle(position.x, position.y));
                        _movePrev.copy(_moveCurr);
                        break;
                    }
                }

                break;
        }

        this.dispatchEvent(_endEvent);
    }

    private function contextmenu(event:Dynamic):Void {
        if (this.enabled === false) return;

        event.preventDefault();
    }

    private function addPointer(event:Dynamic):Void {
        _pointers.push(event);
    }

    private function removePointer(event:Dynamic):Void {
        delete _pointerPositions[event.pointerId];

        for (var i:Int = 0; i < _pointers.length; i++) {
            if (_pointers[i].pointerId == event.pointerId) {
                _pointers.splice(i, 1);
                return;
            }
        }
    }

    private function trackPointer(event:Dynamic):Void {
        var position:Dynamic = _pointerPositions[event.pointerId];

        if (position === null) {
            position = new Vector2();
            _pointerPositions[event.pointerId] = position;
        }

        position.set(event.pageX, event.pageY);
    }

    private function getSecondPointerPosition(event:Dynamic):Dynamic {
        var pointer:Dynamic = (event.pointerId === _pointers[0].pointerId) ? _pointers[1] : _pointers[0];
        return _pointerPositions[pointer.pointerId];
    }

    public function dispose():Void {
        this.domElement.removeEventListener('contextmenu', ($event) => this.contextmenu($event));
        this.domElement.removeEventListener('pointerdown', ($event) => this.onPointerDown($event));
        this.domElement.removeEventListener('pointercancel', ($event) => this.onPointerCancel($event));
        this.domElement.removeEventListener('wheel', ($event) => this.onMouseWheel($event), { passive: false });
        this.domElement.removeEventListener('pointermove', ($event) => this.onPointerMove($event));
        this.domElement.removeEventListener('pointerup', ($event) => this.onPointerUp($event));
        window.removeEventListener('keydown', ($event) => this.keydown($event));
        window.removeEventListener('keyup', ($event) => this.keyup($event));
    }
}