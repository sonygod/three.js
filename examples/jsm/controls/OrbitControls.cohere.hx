import js.Browser.Window;
import js.three.EventDispatcher;
import js.three.MathUtils;
import js.three.Plane;
import js.three.Quaternion;
import js.three.Ray;
import js.three.Spherical;
import js.three.Vector2;
import js.three.Vector3;

class OrbitControls extends EventDispatcher {
    var _changeEvent:Dynamic;
    var _startEvent:Dynamic;
    var _endEvent:Dynamic;
    var _ray:Ray;
    var _plane:Plane;
    var TILT_LIMIT:Float;
    var STATE:Enum;
    var EPS:Float;
    var spherical:Spherical;
    var sphericalDelta:Spherical;
    var scale:Float;
    var panOffset:Vector3;
    var rotateStart:Vector2;
    var rotateEnd:Vector2;
    var rotateDelta:Vector2;
    var panStart:Vector2;
    var panEnd:Vector2;
    var panDelta:Vector2;
    var dollyStart:Vector2;
    var dollyEnd:Vector2;
    var dollyDelta:Vector2;
    var dollyDirection:Vector3;
    var mouse:Vector2;
    var performCursorZoom:Bool;
    var pointers:Array<Int>;
    var pointerPositions:Map<Int,Vector2>;
    var controlActive:Bool;
    var scope:OrbitControls;

    public function new(object:Dynamic, domElement:Dynamic) {
        super();
        this.object = object;
        this.domElement = domElement;
        this.domElement.style.touchAction = 'none';
        this.enabled = true;
        this.target = new Vector3();
        this.cursor = new Vector3();
        this.minDistance = 0;
        this.maxDistance = js.Browser.window.Infinity;
        this.minZoom = 0;
        this.maxZoom = js.Browser.window.Infinity;
        this.minTargetRadius = 0;
        this.maxTargetRadius = js.Browser.window.Infinity;
        this.minPolarAngle = 0;
        this.maxPolarAngle = Math.PI;
        this.minAzimuthAngle = -js.Browser.window.Infinity;
        this.maxAzimuthAngle = js.Browser.window.Infinity;
        this.enableDamping = false;
        this.dampingFactor = 0.05;
        this.enableZoom = true;
        this.zoomSpeed = 1.0;
        this.enableRotate = true;
        this.rotateSpeed = 1.0;
        this.enablePan = true;
        this.panSpeed = 1.0;
        this.screenSpacePanning = true;
        this.keyPanSpeed = 7.0;
        this.zoomToCursor = false;
        this.autoRotate = false;
        this.autoRotateSpeed = 2.0;
        this.keys = {
            LEFT: 'ArrowLeft',
            UP: 'ArrowUp',
            RIGHT: 'ArrowRight',
            BOTTOM: 'ArrowDown'
        };
        this.mouseButtons = {
            LEFT: 0,
            MIDDLE: 1,
            RIGHT: 2
        };
        this.touches = {
            ONE: 0,
            TWO: 1
        };
        this.target0 = this.target.clone();
        this.position0 = this.object.position.clone();
        this.zoom0 = this.object.zoom;
        this._domElementKeyEvents = null;
        this.getPolarAngle = $bind(this, $getPolarAngle);
        this.getAzimuthalAngle = $bind(this, $getAzimuthalAngle);
        this.getDistance = $bind(this, $getDistance);
        this.listenToKeyEvents = $bind(this, $listenToKeyEvents);
        this.stopListenToKeyEvents = $bind(this, $stopListenToKeyEvents);
        this.saveState = $bind(this, $saveState);
        this.reset = $bind(this, $reset);
        this.update = $bind(this, $update);
        this.dispose = $bind(this, $dispose);
        this.STATE = {
            NONE: -1,
            ROTATE: 0,
            DOLLY: 1,
            PAN: 2,
            TOUCH_ROTATE: 3,
            TOUCH_PAN: 4,
            TOUCH_DOLLY_PAN: 5,
            TOUCH_DOLLY_ROTATE: 6
        };
        this.EPS = 0.000001;
        this.spherical = new Spherical();
        this.sphericalDelta = new Spherical();
        this.scale = 1;
        this.panOffset = new Vector3();
        this.rotateStart = new Vector2();
        this.rotateEnd = new Vector2();
        this.rotateDelta = new Vector2();
        this.panStart = new Vector2();
        this.panEnd = new Vector2();
        this.panDelta = new Vector2();
        this.dollyStart = new Vector2();
        this.dollyEnd = new Vector2();
        this.dollyDelta = new Vector2();
        this.dollyDirection = new Vector3();
        this.mouse = new Vector2();
        this.performCursorZoom = false;
        this.pointers = [];
        this.pointerPositions = new Map();
        this.controlActive = false;
        this.scope = this;
        this._changeEvent = { type: 'change' };
        this._startEvent = { type: 'start' };
        this._endEvent = { type: 'end' };
        this._ray = new Ray();
        this._plane = new Plane();
        this.TILT_LIMIT = Math.cos(70 * MathUtils.DEG2RAD);
        this.domElement.addEventListener('contextmenu', $bind(this, $onContextMenu));
        this.domElement.addEventListener('pointerdown', $bind(this, $onPointerDown));
        this.domElement.addEventListener('pointercancel', $bind(this, $onPointerUp));
        this.domElement.addEventListener('wheel', $bind(this, $onMouseWheel), { passive: false });
        var document = this.domElement.getRootNode();
        document.addEventListener('keydown', $bind(this, $interceptControlDown), { capture: true });
        this.update();
    }

    function $getPolarAngle():Float {
        return this.spherical.phi;
    }

    function $getAzimuthalAngle():Float {
        return this.spherical.theta;
    }

    function $getDistance():Float {
        return this.object.position.distanceTo(this.target);
    }

    function $listenToKeyEvents(domElement:Dynamic) {
        domElement.addEventListener('keydown', this.onKeyDown);
        this._domElementKeyEvents = domElement;
    }

    function $stopListenToKeyEvents() {
        this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
        this._domElementKeyEvents = null;
    }

    function $saveState() {
        this.target0.copy(this.target);
        this.position0.copy(this.object.position);
        this.zoom0 = this.object.zoom;
    }

    function $reset() {
        this.target.copy(this.target0);
        this.object.position.copy(this.position0);
        this.object.zoom = this.zoom0;
        this.object.updateProjectionMatrix();
        this.dispatchEvent(this._changeEvent);
        this.update();
        this.state = this.STATE.NONE;
    }

    function $update(deltaTime:Float = null) {
        var offset = new Vector3();
        var quat = new Quaternion().setFromUnitVectors(this.object.up, new Vector3(0, 1, 0));
        var quatInverse = quat.clone().invert();
        var lastPosition = new Vector3();
        var lastQuaternion = new Quaternion();
        var lastTargetPosition = new Vector3();
        var twoPI = 2 * Math.PI;
        offset.copy(this.object.position).sub(this.target);
        offset.applyQuaternion(quat);
        this.spherical.setFromVector3(offset);
        if (this.autoRotate && this.state == this.STATE.NONE) {
            this.rotateLeft(getAutoRotationAngle(deltaTime));
        }
        if (this.enableDamping) {
            this.spherical.theta += this.sphericalDelta.theta * this.dampingFactor;
            this.spherical.phi += this.sphericalDelta.phi * this.dampingFactor;
        } else {
            this.spherical.theta += this.sphericalDelta.theta;
            this.spherical.phi += this.sphericalDelta.phi;
        }
        var min = this.minAzimuthAngle;
        var max = this.maxAzimuthAngle;
        if (min < -Math.PI) min += twoPI;
        else if (min > Math.PI) min -= twoPI;
        if (max < -Math.PI) max += twoPI;
        else if (max > Math.PI) max -= twoPI;
        if (min <= max) {
            this.spherical.theta = Math.max(min, Math.min(max, this.spherical.theta));
        } else {
            this.spherical.theta = (this.spherical.theta > (min + max) / 2) ?
                Math.max(min, this.spherical.theta) :
                Math.min(max, this.spherical.theta);
        }
        this.spherical.phi = Math.max(this.minPolarAngle, Math.min(this.maxPolarAngle, this.spherical.phi));
        this.spherical.makeSafe();
        if (this.enableDamping) {
            this.target.addScaledVector(this.panOffset, this.dampingFactor);
        } else {
            this.target.add(this.panOffset);
        }
        this.target.sub(this.cursor);
        this.target.clampLength(this.minTargetRadius, this.maxTargetRadius);
        this.target.add(this.cursor);
        var zoomChanged = false;
        if (this.zoomToCursor && this.performCursorZoom || this.object.isOrthographicCamera) {
            this.spherical.radius = this.clampDistance(this.spherical.radius);
        } else {
            var prevRadius = this.spherical.radius;
            this.spherical.radius = this.clampDistance(this.spherical.radius * this.scale);
            zoomChanged = prevRadius != this.spherical.radius;
        }
        offset.setFromSpherical(this.spherical);
        offset.applyQuaternion(quatInverse);
        this.object.position.copy(this.target).add(offset);
        this.object.lookAt(this.target);
        if (this.enableDamping) {
            this.sphericalDelta.theta *= (1 - this.dampingFactor);
            this.sphericalDelta.phi *= (1 - this.dampingFactor);
            this.panOffset.multiplyScalar(1 - this.dampingFactor);
        } else {
            this.sphericalDelta.set(0, 0, 0);
            this.panOffset.set(0, 0, 0);
        }
        if (this.zoomToCursor && this.performCursorZoom) {
            var newRadius = null;
            if (this.object.isPerspectiveCamera) {
                var prevRadius = offset.length();
                newRadius = this.clampDistance(prevRadius * this.scale);
                var radiusDelta = prevRadius - newRadius;
                this.object.position.addScaledVector(this.dollyDirection, radiusDelta);
                this.object.updateMatrixWorld();
                zoomChanged = true;
            } else if (this.object.isOrthographicCamera) {
                var mouseBefore = new Vector3(this.mouse.x, this.mouse.y, 0);
                mouseBefore.unproject(this.object);
                var prevZoom = this.object.zoom;
                this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this.scale));
                if (prevZoom != this.object.zoom) {
                    this.object.updateProjectionMatrix();
                    zoomChanged = true;
                }
                var mouseAfter = new Vector3(this.mouse.x, this.mouse.y, 0);
                mouseAfter.unproject(this.object);
                this.object.position.sub(mouseAfter).add(mouseBefore);
                this.object.updateMatrixWorld();
                newRadius = offset.length();
            } else {
                trace('WARNING: OrbitControls.js encountered an unknown camera type - zoom to cursor disabled.');
                this.zoomToCursor = false;
            }
            if (newRadius != null) {
                if (this.screenSpacePanning) {
                    this.target.set(0, 0, -1)
                        .transformDirection(this.object.matrix)
                        .multiplyScalar(newRadius)
                        .add(this.object.position);
                } else {
                    this._ray.origin.copy(this.object.position);
                    this._ray.direction.set(0, 0, -1).transformDirection(this.object.matrix);
                    if (Math.abs(this.object.up.dot(this._ray.direction)) < this.TILT_LIMIT) {
                        this.object.lookAt(this.target);
                    } else {
                        this._plane.setFromNormalAndCoplanarPoint(this.object.up, this.target);
                        this._ray.intersectPlane(this._plane, this.target);
                    }
                }
            }
        } else if (this.object.isOrthographicCamera) {
            var prevZoom = this.object.zoom;
            this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this.scale));
            if (prevZoom != this.object.zoom) {
                this.object.updateProjectionMatrix();
                zoomChanged = true;
            }
        }
        this.scale = 1;
        this.performCursorZoom = false;
        if (zoomChanged ||
            lastPosition.distanceToSquared(this.object.position) > this.EPS ||
            8 * (1 - lastQuaternion.dot(this.object.quaternion)) > this.EPS ||
            lastTargetPosition.distanceToSquared(this.target) > this.EPS) {
            this.dispatchEvent(this._changeEvent);
            lastPosition.copy(this.object.position);
            lastQuaternion.copy(this.object.quaternion);
            lastTargetPosition.copy(this.target);
            return true;
        }
        return false;
    }

    function $dispose() {
        this.domElement.removeEventListener('contextmenu', this.onContextMenu);
        this.domElement.removeEventListener('pointerdown', this.onPointerDown);
        this.domElement.removeEventListener('pointercancel', this.onPointerUp);
        this.domElement.removeEventListener('wheel', this.onMouseWheel);
        var document = this.domElement.getRootNode();
        document.removeEventListener('keydown', this.interceptControlDown, { capture: true });
        if (this._domElementKeyEvents != null) {
            this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
            this._domElementKeyEvents = null;
        }
    }

    function getAutoRotationAngle(deltaTime:Float):Float {
        if (deltaTime != null) {
            return (2 * Math.PI / 60 * this.autoRotateSpeed) * deltaTime;
        } else {
            return 2 * Math.PI / 60 / 60 * this.autoRotateSpeed;
        }
    }

    function getZoomScale(delta:Float):Float {
        var normalizedDelta = Math.abs(delta * 0.01);
        return Math.pow(0.95, this.zoomSpeed * normalizedDelta);
    }

    function rotateLeft(angle:Float) {
        this.sphericalDelta.theta -= angle;
    }

    function rotateUp(angle:Float) {
        this.sphericalDelta.phi -= angle;
    }

    function panLeft(distance:Float, objectMatrix:Dynamic) {
        var v = new Vector3();
        v.setFromMatrixColumn(objectMatrix, 0);
        v.multiplyScalar(-distance);
        this.panOffset.add(v);
    }

    function panUp(distance:Float, objectMatrix:Dynamic) {
        var v = new Vector3();
        if (this.screenSpacePanning) {
            v.setFromMatrixColumn(objectMatrix, 1);
        } else {
            v.setFromMatrixColumn(objectMatrix, 0);
            v.crossVectors(this.object.up, v);
        }
        v.multiplyScalar(distance);
        this.panOffset.add(v);
    }

    function pan(deltaX:Float, deltaY:Float) {
        var element = this.domElement;
        if (this.object.isPerspectiveCamera) {
            var position = this.object.position;
            var offset = position.sub(this.target);
            var targetDistance = offset.length();
            var halfFoV = this.object.fov / 2;
            var targetDistance2 = targetDistance * Math.tan(halfFoV * Math.PI / 180.0);
            this.panLeft(2 * deltaX * targetDistance2 / element.clientHeight, this.object.matrix);
            this.panUp(2 * deltaY * targetDistance2 / element.clientHeight, this.object.matrix);
        } else if (this.object.isOrthographicCamera) {
            this.panLeft(deltaX * (this.object.right - this.object.