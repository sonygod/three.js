import three.js.examples.jsm.controls.OrbitControls;
import three.js.examples.jsm.controls.EventDispatcher;
import three.js.examples.jsm.math.Vector2;
import three.js.examples.jsm.math.Vector3;
import three.js.examples.jsm.math.Quaternion;
import three.js.examples.jsm.math.Spherical;
import three.js.examples.jsm.math.Plane;
import three.js.examples.jsm.math.Ray;
import three.js.examples.jsm.math.MathUtils;

class OrbitControlsHaxe extends EventDispatcher {

    public var object:Dynamic;
    public var domElement:Dynamic;
    public var enabled:Bool;
    public var target:Vector3;
    public var cursor:Vector3;
    public var minDistance:Float;
    public var maxDistance:Float;
    public var minZoom:Float;
    public var maxZoom:Float;
    public var minTargetRadius:Float;
    public var maxTargetRadius:Float;
    public var minPolarAngle:Float;
    public var maxPolarAngle:Float;
    public var minAzimuthAngle:Float;
    public var maxAzimuthAngle:Float;
    public var enableDamping:Bool;
    public var dampingFactor:Float;
    public var enableZoom:Bool;
    public var zoomSpeed:Float;
    public var enableRotate:Bool;
    public var rotateSpeed:Float;
    public var enablePan:Bool;
    public var panSpeed:Float;
    public var screenSpacePanning:Bool;
    public var keyPanSpeed:Float;
    public var zoomToCursor:Bool;
    public var autoRotate:Bool;
    public var autoRotateSpeed:Float;
    public var keys:Dynamic;
    public var mouseButtons:Dynamic;
    public var touches:Dynamic;
    public var target0:Vector3;
    public var position0:Vector3;
    public var zoom0:Float;
    public var _domElementKeyEvents:Dynamic;

    public function new(object:Dynamic, domElement:Dynamic) {
        super();
        this.object = object;
        this.domElement = domElement;
        this.domElement.style.touchAction = 'none';
        this.enabled = true;
        this.target = new Vector3();
        this.cursor = new Vector3();
        this.minDistance = 0;
        this.maxDistance = Infinity;
        this.minZoom = 0;
        this.maxZoom = Infinity;
        this.minTargetRadius = 0;
        this.maxTargetRadius = Infinity;
        this.minPolarAngle = 0;
        this.maxPolarAngle = Math.PI;
        this.minAzimuthAngle = -Infinity;
        this.maxAzimuthAngle = Infinity;
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
        this.keys = { LEFT: 'ArrowLeft', UP: 'ArrowUp', RIGHT: 'ArrowRight', BOTTOM: 'ArrowDown' };
        this.mouseButtons = { LEFT: 0, MIDDLE: 1, RIGHT: 2 };
        this.touches = { ONE: 0, TWO: 1 };
        this.target0 = this.target.clone();
        this.position0 = this.object.position.clone();
        this.zoom0 = this.object.zoom;
    }

    public function getPolarAngle():Float {
        return spherical.phi;
    }

    public function getAzimuthalAngle():Float {
        return spherical.theta;
    }

    public function getDistance():Float {
        return this.object.position.distanceTo(this.target);
    }

    public function listenToKeyEvents(domElement:Dynamic) {
        domElement.addEventListener('keydown', onKeyDown);
        this._domElementKeyEvents = domElement;
    }

    public function stopListenToKeyEvents() {
        this._domElementKeyEvents.removeEventListener('keydown', onKeyDown);
        this._domElementKeyEvents = null;
    }

    public function saveState() {
        scope.target0.copy(scope.target);
        scope.position0.copy(scope.object.position);
        scope.zoom0 = scope.object.zoom;
    }

    public function reset() {
        scope.target.copy(scope.target0);
        scope.object.position.copy(scope.position0);
        scope.object.zoom = scope.zoom0;
        scope.object.updateProjectionMatrix();
        scope.dispatchEvent(_changeEvent);
        scope.update();
        state = STATE.NONE;
    }

    public function update(deltaTime:Float = null):Bool {
        const offset = new Vector3();
        const quat = new Quaternion().setFromUnitVectors(object.up, new Vector3(0, 1, 0));
        const quatInverse = quat.clone().invert();
        const lastPosition = new Vector3();
        const lastQuaternion = new Quaternion();
        const lastTargetPosition = new Vector3();
        const twoPI = 2 * Math.PI;
        return function update(deltaTime = null) {
            const position = scope.object.position;
            offset.copy(position).sub(scope.target);
            offset.applyQuaternion(quat);
            spherical.setFromVector3(offset);
            if (scope.autoRotate && state === STATE.NONE) {
                rotateLeft(getAutoRotationAngle(deltaTime));
            }
            if (scope.enableDamping) {
                spherical.theta += sphericalDelta.theta * scope.dampingFactor;
                spherical.phi += sphericalDelta.phi * scope.dampingFactor;
            } else {
                spherical.theta += sphericalDelta.theta;
                spherical.phi += sphericalDelta.phi;
            }
            let min = scope.minAzimuthAngle;
            let max = scope.maxAzimuthAngle;
            if (isFinite(min) && isFinite(max)) {
                if (min < -Math.PI) min += twoPI; else if (min > Math.PI) min -= twoPI;
                if (max < -Math.PI) max += twoPI; else if (max > Math.PI) max -= twoPI;
                if (min <= max) {
                    spherical.theta = Math.max(min, Math.min(max, spherical.theta));
                } else {
                    spherical.theta = (spherical.theta > (min + max) / 2) ?
                        Math.max(min, spherical.theta) :
                        Math.min(max, spherical.theta);
                }
            }
            spherical.phi = Math.max(scope.minPolarAngle, Math.min(scope.maxPolarAngle, spherical.phi));
            spherical.makeSafe();
            scope.target.addScaledVector(panOffset, scope.dampingFactor);
            scope.target.sub(scope.cursor);
            scope.target.clampLength(scope.minTargetRadius, scope.maxTargetRadius);
            scope.target.add(scope.cursor);
            let zoomChanged = false;
            if (scope.zoomToCursor && performCursorZoom || scope.object.isOrthographicCamera) {
                spherical.radius = clampDistance(spherical.radius);
            } else {
                const prevRadius = spherical.radius;
                spherical.radius = clampDistance(spherical.radius * scale);
                zoomChanged = prevRadius != spherical.radius;
            }
            offset.setFromSpherical(spherical);
            offset.applyQuaternion(quatInverse);
            position.copy(scope.target).add(offset);
            scope.object.lookAt(scope.target);
            if (scope.enableDamping === true) {
                sphericalDelta.theta *= (1 - scope.dampingFactor);
                sphericalDelta.phi *= (1 - scope.dampingFactor);
                panOffset.multiplyScalar(1 - scope.dampingFactor);
            } else {
                sphericalDelta.set(0, 0, 0);
                panOffset.set(0, 0, 0);
            }
            if (scope.zoomToCursor && performCursorZoom) {
                let newRadius = null;
                if (scope.object.isPerspectiveCamera) {
                    newRadius = clampDistance(prevRadius * scale);
                    const radiusDelta = prevRadius - newRadius;
                    scope.object.position.addScaledVector(dollyDirection, radiusDelta);
                    scope.object.updateMatrixWorld();
                    zoomChanged = !!radiusDelta;
                } else if (scope.object.isOrthographicCamera) {
                    const mouseBefore = new Vector3(mouse.x, mouse.y, 0);
                    mouseBefore.unproject(scope.object);
                    const prevZoom = scope.object.zoom;
                    scope.object.zoom = Math.max(scope.minZoom, Math.min(scope.maxZoom, scope.object.zoom / scale));
                    scope.object.updateProjectionMatrix();
                    zoomChanged = prevZoom !== scope.object.zoom;
                    const mouseAfter = new Vector3(mouse.x, mouse.y, 0);
                    mouseAfter.unproject(scope.object);
                    scope.object.position.sub(mouseAfter).add(mouseBefore);
                    scope.object.updateMatrixWorld();
                    newRadius = offset.length();
                } else {
                    console.warn('WARNING: OrbitControls.js encountered an unknown camera type - zoom to cursor disabled.');
                    scope.zoomToCursor = false;
                }
                if (newRadius !== null) {
                    if (this.screenSpacePanning) {
                        scope.target.set(0, 0, -1)
                            .transformDirection(scope.object.matrix)
                            .multiplyScalar(newRadius)
                            .add(scope.object.position);
                    } else {
                        _ray.origin.copy(scope.object.position);
                        _ray.direction.set(0, 0, -1).transformDirection(scope.object.matrix);
                        if (Math.abs(scope.object.up.dot(_ray.direction)) < TILT_LIMIT) {
                            object.lookAt(scope.target);
                        } else {
                            _plane.setFromNormalAndCoplanarPoint(scope.object.up, scope.target);
                            _ray.intersectPlane(_plane, scope.target);
                        }
                    }
                }
            } else if (scope.object.isOrthographicCamera) {
                const prevZoom = scope.object.zoom;
                scope.object.zoom = Math.max(scope.minZoom, Math.min(scope.maxZoom, scope.object.zoom / scale));
                if (prevZoom !== scope.object.zoom) {
                    scope.object.updateProjectionMatrix();
                    zoomChanged = true;
                }
            }
            scale = 1;
            performCursorZoom = false;
            if (zoomChanged ||
                lastPosition.distanceToSquared(scope.object.position) > EPS ||
                8 * (1 - lastQuaternion.dot(scope.object.quaternion)) > EPS ||
                lastTargetPosition.distanceToSquared(scope.target) > EPS) {
                scope.dispatchEvent(_changeEvent);
                lastPosition.copy(scope.object.position);
                lastQuaternion.copy(scope.object.quaternion);
                lastTargetPosition.copy(scope.target);
                return true;
            }
            return false;
        };
    }

    public function dispose() {
        scope.domElement.removeEventListener('contextmenu', onContextMenu);
        scope.domElement.removeEventListener('pointerdown', onPointerDown);
        scope.domElement.removeEventListener('pointercancel', onPointerUp);
        scope.domElement.removeEventListener('wheel', onMouseWheel);
        scope.domElement.removeEventListener('pointermove', onPointerMove);
        scope.domElement.removeEventListener('pointerup', onPointerUp);
        const document = scope.domElement.getRootNode();
        document.removeEventListener('keydown', interceptControlDown, { capture: true });
        if (scope._domElementKeyEvents !== null) {
            scope._domElementKeyEvents.removeEventListener('keydown', onKeyDown);
            scope._domElementKeyEvents = null;
        }
    }

    // ... rest of the code ...
}