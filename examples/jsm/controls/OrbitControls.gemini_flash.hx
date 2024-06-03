import three.core.EventDispatcher;
import three.math.Quaternion;
import three.math.Spherical;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Plane;
import three.math.Ray;
import three.math.MathUtils;
import three.cameras.Camera;
import three.cameras.PerspectiveCamera;
import three.cameras.OrthographicCamera;

// OrbitControls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
//
//    Orbit - left mouse / touch: one-finger move
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - right mouse, or left mouse + ctrl/meta/shiftKey, or arrow keys / touch: two-finger move

class OrbitControls extends EventDispatcher {

	public var object:Camera;
	public var domElement:Dynamic;

	// Set to false to disable this control
	public var enabled:Bool = true;

	// "target" sets the location of focus, where the object orbits around
	public var target:Vector3 = new Vector3();

	// Sets the 3D cursor (similar to Blender), from which the maxTargetRadius takes effect
	public var cursor:Vector3 = new Vector3();

	// How far you can dolly in and out ( PerspectiveCamera only )
	public var minDistance:Float = 0;
	public var maxDistance:Float = Math.POSITIVE_INFINITY;

	// How far you can zoom in and out ( OrthographicCamera only )
	public var minZoom:Float = 0;
	public var maxZoom:Float = Math.POSITIVE_INFINITY;

	// Limit camera target within a spherical area around the cursor
	public var minTargetRadius:Float = 0;
	public var maxTargetRadius:Float = Math.POSITIVE_INFINITY;

	// How far you can orbit vertically, upper and lower limits.
	// Range is 0 to Math.PI radians.
	public var minPolarAngle:Float = 0; // radians
	public var maxPolarAngle:Float = Math.PI; // radians

	// How far you can orbit horizontally, upper and lower limits.
	// If set, the interval [ min, max ] must be a sub-interval of [ - 2 PI, 2 PI ], with ( max - min < 2 PI )
	public var minAzimuthAngle:Float = -Math.POSITIVE_INFINITY; // radians
	public var maxAzimuthAngle:Float = Math.POSITIVE_INFINITY; // radians

	// Set to true to enable damping (inertia)
	// If damping is enabled, you must call controls.update() in your animation loop
	public var enableDamping:Bool = false;
	public var dampingFactor:Float = 0.05;

	// This option actually enables dollying in and out; left as "zoom" for backwards compatibility.
	// Set to false to disable zooming
	public var enableZoom:Bool = true;
	public var zoomSpeed:Float = 1.0;

	// Set to false to disable rotating
	public var enableRotate:Bool = true;
	public var rotateSpeed:Float = 1.0;

	// Set to false to disable panning
	public var enablePan:Bool = true;
	public var panSpeed:Float = 1.0;
	public var screenSpacePanning:Bool = true; // if false, pan orthogonal to world-space direction camera.up
	public var keyPanSpeed:Float = 7.0;	// pixels moved per arrow key push
	public var zoomToCursor:Bool = false;

	// Set to true to automatically rotate around the target
	// If auto-rotate is enabled, you must call controls.update() in your animation loop
	public var autoRotate:Bool = false;
	public var autoRotateSpeed:Float = 2.0; // 30 seconds per orbit when fps is 60

	// The four arrow keys
	public var keys:{ LEFT:String, UP:String, RIGHT:String, BOTTOM:String } = { LEFT: 'ArrowLeft', UP: 'ArrowUp', RIGHT: 'ArrowRight', BOTTOM: 'ArrowDown' };

	// Mouse buttons
	public var mouseButtons:{ LEFT:Int, MIDDLE:Int, RIGHT:Int } = { LEFT: 0, MIDDLE: 1, RIGHT: 2 };

	// Touch fingers
	public var touches:{ ONE:Int, TWO:Int } = { ONE: 0, TWO: 1 };

	// for reset
	public var target0:Vector3 = new Vector3();
	public var position0:Vector3 = new Vector3();
	public var zoom0:Float = 0;

	// the target DOM element for key events
	private var _domElementKeyEvents:Dynamic = null;

	private var _ray:Ray = new Ray();
	private var _plane:Plane = new Plane();
	private static inline var TILT_LIMIT:Float = Math.cos( 70 * MathUtils.DEG2RAD );
	private var _spherical:Spherical = new Spherical();
	private var _sphericalDelta:Spherical = new Spherical();
	private var _scale:Float = 1;
	private var _panOffset:Vector3 = new Vector3();
	private var _rotateStart:Vector2 = new Vector2();
	private var _rotateEnd:Vector2 = new Vector2();
	private var _rotateDelta:Vector2 = new Vector2();
	private var _panStart:Vector2 = new Vector2();
	private var _panEnd:Vector2 = new Vector2();
	private var _panDelta:Vector2 = new Vector2();
	private var _dollyStart:Vector2 = new Vector2();
	private var _dollyEnd:Vector2 = new Vector2();
	private var _dollyDelta:Vector2 = new Vector2();
	private var _dollyDirection:Vector3 = new Vector3();
	private var _mouse:Vector2 = new Vector2();
	private var _performCursorZoom:Bool = false;
	private var _pointers:Array<Int> = [];
	private var _pointerPositions:Map<Int, Vector2> = new Map();
	private var _controlActive:Bool = false;

	public function new(object:Camera, domElement:Dynamic) {
		super();

		this.object = object;
		this.domElement = domElement;
		this.domElement.style.touchAction = 'none'; // disable touch scroll

		this.target0.copy(this.target);
		this.position0.copy(this.object.position);
		this.zoom0 = this.object.zoom;

		domElement.addEventListener('contextmenu', this.onContextMenu);
		domElement.addEventListener('pointerdown', this.onPointerDown);
		domElement.addEventListener('pointercancel', this.onPointerUp);
		domElement.addEventListener('wheel', this.onMouseWheel, {passive: false});
		domElement.addEventListener('pointermove', this.onPointerMove);
		domElement.addEventListener('pointerup', this.onPointerUp);

		var document = this.domElement.getRootNode(); // offscreen canvas compatibility
		document.addEventListener('keydown', this.interceptControlDown, {capture: true});

		this.update();
	}

	public function getPolarAngle():Float {
		return this._spherical.phi;
	}

	public function getAzimuthalAngle():Float {
		return this._spherical.theta;
	}

	public function getDistance():Float {
		return this.object.position.distanceTo(this.target);
	}

	public function listenToKeyEvents(domElement:Dynamic) {
		domElement.addEventListener('keydown', this.onKeyDown);
		this._domElementKeyEvents = domElement;
	}

	public function stopListenToKeyEvents() {
		if (this._domElementKeyEvents != null) {
			this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
			this._domElementKeyEvents = null;
		}
	}

	public function saveState() {
		this.target0.copy(this.target);
		this.position0.copy(this.object.position);
		this.zoom0 = this.object.zoom;
	}

	public function reset() {
		this.target.copy(this.target0);
		this.object.position.copy(this.position0);
		this.object.zoom = this.zoom0;
		this.object.updateProjectionMatrix();
		this.dispatchEvent({type: 'change'});
		this.update();
	}

	public function update(deltaTime:Float = null) {
		var offset = new Vector3();
		var quat = new Quaternion().setFromUnitVectors(this.object.up, new Vector3(0, 1, 0));
		var quatInverse = quat.clone().invert();
		var lastPosition = new Vector3();
		var lastQuaternion = new Quaternion();
		var lastTargetPosition = new Vector3();
		var twoPI = 2 * Math.PI;

		var position = this.object.position;
		offset.copy(position).sub(this.target);
		offset.applyQuaternion(quat);
		this._spherical.setFromVector3(offset);

		if (this.autoRotate && state == STATE.NONE) {
			rotateLeft(getAutoRotationAngle(deltaTime));
		}

		if (this.enableDamping) {
			this._spherical.theta += this._sphericalDelta.theta * this.dampingFactor;
			this._spherical.phi += this._sphericalDelta.phi * this.dampingFactor;
		} else {
			this._spherical.theta += this._sphericalDelta.theta;
			this._spherical.phi += this._sphericalDelta.phi;
		}

		var min = this.minAzimuthAngle;
		var max = this.maxAzimuthAngle;
		if (isFinite(min) && isFinite(max)) {
			if (min < -Math.PI) min += twoPI; else if (min > Math.PI) min -= twoPI;
			if (max < -Math.PI) max += twoPI; else if (max > Math.PI) max -= twoPI;
			if (min <= max) {
				this._spherical.theta = Math.max(min, Math.min(max, this._spherical.theta));
			} else {
				this._spherical.theta = (this._spherical.theta > (min + max) / 2) ?
					Math.max(min, this._spherical.theta) :
					Math.min(max, this._spherical.theta);
			}
		}

		this._spherical.phi = Math.max(this.minPolarAngle, Math.min(this.maxPolarAngle, this._spherical.phi));
		this._spherical.makeSafe();

		if (this.enableDamping) {
			this.target.addScaledVector(this._panOffset, this.dampingFactor);
		} else {
			this.target.add(this._panOffset);
		}

		this.target.sub(this.cursor);
		this.target.clampLength(this.minTargetRadius, this.maxTargetRadius);
		this.target.add(this.cursor);

		var zoomChanged = false;
		if (this.zoomToCursor && this._performCursorZoom || this.object.isOrthographicCamera) {
			this._spherical.radius = clampDistance(this._spherical.radius);
		} else {
			var prevRadius = this._spherical.radius;
			this._spherical.radius = clampDistance(this._spherical.radius * this._scale);
			zoomChanged = prevRadius != this._spherical.radius;
		}

		offset.setFromSpherical(this._spherical);
		offset.applyQuaternion(quatInverse);
		position.copy(this.target).add(offset);
		this.object.lookAt(this.target);

		if (this.enableDamping) {
			this._sphericalDelta.theta *= (1 - this.dampingFactor);
			this._sphericalDelta.phi *= (1 - this.dampingFactor);
			this._panOffset.multiplyScalar(1 - this.dampingFactor);
		} else {
			this._sphericalDelta.set(0, 0, 0);
			this._panOffset.set(0, 0, 0);
		}

		if (this.zoomToCursor && this._performCursorZoom) {
			var newRadius:Float = null;
			if (this.object.isPerspectiveCamera) {
				var prevRadius = offset.length();
				newRadius = clampDistance(prevRadius * this._scale);
				var radiusDelta = prevRadius - newRadius;
				this.object.position.addScaledVector(this._dollyDirection, radiusDelta);
				this.object.updateMatrixWorld();
				zoomChanged = !!radiusDelta;
			} else if (this.object.isOrthographicCamera) {
				var mouseBefore = new Vector3(this._mouse.x, this._mouse.y, 0);
				mouseBefore.unproject(this.object);
				var prevZoom = this.object.zoom;
				this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this._scale));
				this.object.updateProjectionMatrix();
				zoomChanged = prevZoom != this.object.zoom;
				var mouseAfter = new Vector3(this._mouse.x, this._mouse.y, 0);
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
					this.target.set(0, 0, -1).transformDirection(this.object.matrix).multiplyScalar(newRadius).add(this.object.position);
				} else {
					this._ray.origin.copy(this.object.position);
					this._ray.direction.set(0, 0, -1).transformDirection(this.object.matrix);
					if (Math.abs(this.object.up.dot(this._ray.direction)) < TILT_LIMIT) {
						this.object.lookAt(this.target);
					} else {
						this._plane.setFromNormalAndCoplanarPoint(this.object.up, this.target);
						this._ray.intersectPlane(this._plane, this.target);
					}
				}
			}
		} else if (this.object.isOrthographicCamera) {
			var prevZoom = this.object.zoom;
			this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this._scale));
			if (prevZoom != this.object.zoom) {
				this.object.updateProjectionMatrix();
				zoomChanged = true;
			}
		}

		this._scale = 1;
		this._performCursorZoom = false;

		if (zoomChanged || lastPosition.distanceToSquared(this.object.position) > EPS || 8 * (1 - lastQuaternion.dot(this.object.quaternion)) > EPS || lastTargetPosition.distanceToSquared(this.target) > EPS) {
			this.dispatchEvent({type: 'change'});
			lastPosition.copy(this.object.position);
			lastQuaternion.copy(this.object.quaternion);
			lastTargetPosition.copy(this.target);
			return true;
		}

		return false;
	}

	public function dispose() {
		this.domElement.removeEventListener('contextmenu', this.onContextMenu);
		this.domElement.removeEventListener('pointerdown', this.onPointerDown);
		this.domElement.removeEventListener('pointercancel', this.onPointerUp);
		this.domElement.removeEventListener('wheel', this.onMouseWheel);
		this.domElement.removeEventListener('pointermove', this.onPointerMove);
		this.domElement.removeEventListener('pointerup', this.onPointerUp);
		var document = this.domElement.getRootNode(); // offscreen canvas compatibility
		document.removeEventListener('keydown', this.interceptControlDown, {capture: true});
		if (this._domElementKeyEvents != null) {
			this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
			this._domElementKeyEvents = null;
		}
	}

	private static inline var EPS:Float = 0.000001;

	private static inline var STATE = {
		NONE: -1,
		ROTATE: 0,
		DOLLY: 1,
		PAN: 2,
		TOUCH_ROTATE: 3,
		TOUCH_PAN: 4,
		TOUCH_DOLLY_PAN: 5,
		TOUCH_DOLLY_ROTATE: 6
	};

	private var state:Int = STATE.NONE;

	private function getAutoRotationAngle(deltaTime:Float):Float {
		if (deltaTime != null) {
			return (2 * Math.PI / 60 * this.autoRotateSpeed) * deltaTime;
		} else {
			return 2 * Math.PI / 60 / 60 * this.autoRotateSpeed;
		}
	}

	private function getZoomScale(delta:Float):Float {
		var normalizedDelta = Math.abs(delta * 0.01);
		return Math.pow(0.95, this.zoomSpeed * normalizedDelta);
	}

	private function rotateLeft(angle:Float) {
		this._sphericalDelta.theta -= angle;
	}

	private function rotateUp(angle:Float) {
		this._sphericalDelta.phi -= angle;
	}

	private function panLeft(distance:Float, objectMatrix:Matrix4) {
		var v = new Vector3();
		v.setFromMatrixColumn(objectMatrix, 0);
		v.multiplyScalar(-distance);
		this._panOffset.add(v);
	}

	private function panUp(distance:Float, objectMatrix:Matrix4) {
		var v = new Vector3();
		if (this.screenSpacePanning) {
			v.setFromMatrixColumn(objectMatrix, 1);
		} else {
			v.setFromMatrixColumn(objectMatrix, 0);
			v.crossVectors(this.object.up, v);
		}
		v.multiplyScalar(distance);
		this._panOffset.add(v);
	}

	private function pan(deltaX:Float, deltaY:Float) {
		var offset = new Vector3();
		var element = this.domElement;
		if (this.object.isPerspectiveCamera) {
			var position = this.object.position;
			offset.copy(position).sub(this.target);
			var targetDistance = offset.length();
			targetDistance *= Math.tan((this.object.fov / 2) * Math.PI / 180.0);
			panLeft(2 * deltaX * targetDistance / element.clientHeight, this.object.matrix);
			panUp(2 * deltaY * targetDistance / element.clientHeight, this.object.matrix);
		} else if (this.object.isOrthographicCamera) {
			panLeft(deltaX * (this.object.right - this.object.left) / this.object.zoom / element.clientWidth, this.object.matrix);
			panUp(deltaY * (this.object.top - this.object.bottom) / this.object.zoom / element.clientHeight, this.object.matrix);
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - pan disabled.');
			this.enablePan = false;
		}
	}

	private function dollyOut(dollyScale:Float) {
		if (this.object.isPerspectiveCamera || this.object.isOrthographicCamera) {
			this._scale /= dollyScale;
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
			this.enableZoom = false;
		}
	}

	private function dollyIn(dollyScale:Float) {
		if (this.object.isPerspectiveCamera || this.object.isOrthographicCamera) {
			this._scale *= dollyScale;
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
			this.enableZoom = false;
		}
	}

	private function updateZoomParameters(x:Float, y:Float) {
		if (!this.zoomToCursor) {
			return;
		}
		this._performCursorZoom = true;
		var rect = this.domElement.getBoundingClientRect();
		var dx = x - rect.left;
		var dy = y - rect.top;
		var w = rect.width;
		var h = rect.height;
		this._mouse.x = (dx / w) * 2 - 1;
		this._mouse.y = -(dy / h) * 2 + 1;
		this._dollyDirection.set(this._mouse.x, this._mouse.y, 1).unproject(this.object).sub(this.object.position).normalize();
	}

	private function clampDistance(dist:Float):Float {
		return Math.max(this.minDistance, Math.min(this.maxDistance, dist));
	}

	// event callbacks - update the object state

	private function handleMouseDownRotate(event:Dynamic) {
		this._rotateStart.set(event.clientX, event.clientY);
	}

	private function handleMouseDownDolly(event:Dynamic) {
		updateZoomParameters(event.clientX, event.clientX);
		this._dollyStart.set(event.clientX, event.clientY);
	}

	private function handleMouseDownPan(event:Dynamic) {
		this._panStart.set(event.clientX, event.clientY);
	}

	private function handleMouseMoveRotate(event:Dynamic) {
		this._rotateEnd.set(event.clientX, event.clientY);
		this._rotateDelta.subVectors(this._rotateEnd, this._rotateStart).multiplyScalar(this.rotateSpeed);
		var element = this.domElement;
		rotateLeft(2 * Math.PI * this._rotateDelta.x / element.clientHeight);
		rotateUp(2 * Math.PI * this._rotateDelta.y / element.clientHeight);
		this._rotateStart.copy(this._rotateEnd);
		this.update();
	}

	private function handleMouseMoveDolly(event:Dynamic) {
		this._dollyEnd.set(event.clientX, event.clientY);
		this._dollyDelta.subVectors(this._dollyEnd, this._dollyStart);
		if (this._dollyDelta.y > 0) {
			dollyOut(getZoomScale(this._dollyDelta.y));
		} else if (this._dollyDelta.y < 0) {
			dollyIn(getZoomScale(this._dollyDelta.y));
		}
		this._dollyStart.copy(this._dollyEnd);
		this.update();
	}

	private function handleMouseMovePan(event:Dynamic) {
		this._panEnd.set(event.clientX, event.clientY);
		this._panDelta.subVectors(this._panEnd, this._panStart).multiplyScalar(this.panSpeed);
		pan(this._panDelta.x, this._panDelta.y);
		this._panStart.copy(this._panEnd);
		this.update();
	}

	private function handleMouseWheel(event:Dynamic) {
		if (this.enabled == false || this.enableZoom == false || state != STATE.NONE) return;
		event.preventDefault();
		this.dispatchEvent({type: 'start'});
		handleMouseWheel(customWheelEvent(event));
		this.dispatchEvent({type: 'end'});
	}

	private function handleKeyDown(event:Dynamic) {
		var needsUpdate = false;
		switch (event.code) {
			case this.keys.UP:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateUp(2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(0, this.keyPanSpeed);
				}
				needsUpdate = true;
				break;
			case this.keys.BOTTOM:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateUp(-2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(0, -this.keyPanSpeed);
				}
				needsUpdate = true;
				break;
			case this.keys.LEFT:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateLeft(2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(this.keyPanSpeed, 0);
				}
				needsUpdate = true;
				break;
			case this.keys.RIGHT:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateLeft(-2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(-this.keyPanSpeed, 0);
				}
				needsUpdate = true;
				break;
		}
		if (needsUpdate) {
			event.preventDefault();
			this.update();
		}
	}

	private function handleTouchStartRotate(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._rotateStart.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._rotateStart.set(x, y);
		}
	}

	private function handleTouchStartPan(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._panStart.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._panStart.set(x, y);
		}
	}

	private function handleTouchStartDolly(event:Dynamic) {
		var position = getSecondPointerPosition(event);
		var dx = event.pageX - position.x;
		var dy = event.pageY - position.y;
		var distance = Math.sqrt(dx * dx + dy * dy);
		this._dollyStart.set(0, distance);
	}

	private function handleTouchStartDollyPan(event:Dynamic) {
		if (this.enableZoom) handleTouchStartDolly(event);
		if (this.enablePan) handleTouchStartPan(event);
	}

	private function handleTouchStartDollyRotate(event:Dynamic) {
		if (this.enableZoom) handleTouchStartDolly(event);
		if (this.enableRotate) handleTouchStartRotate(event);
	}

	private function handleTouchMoveRotate(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._rotateEnd.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._rotateEnd.set(x, y);
		}
		this._rotateDelta.subVectors(this._rotateEnd, this._rotateStart).multiplyScalar(this.rotateSpeed);
		var element = this.domElement;
		rotateLeft(2 * Math.PI * this._rotateDelta.x / element.clientHeight);
		rotateUp(2 * Math.PI * this._rotateDelta.y / element.clientHeight);
		this._rotateStart.copy(this._rotateEnd);
	}

	private function handleTouchMovePan(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._panEnd.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._panEnd.set(x, y);
		}
		this._panDelta.subVectors(this._panEnd, this._panStart).multiplyScalar(this.panSpeed);
		pan(this._panDelta.x, this._panDelta.y);
		this._panStart.copy(this._panEnd);
	}

	private function handleTouchMoveDolly(event:Dynamic) {
		var position = getSecondPointerPosition(event);
		var dx = event.pageX - position.x;
		var dy = event.pageY - position.y;
		var distance = Math.sqrt(dx * dx + dy * dy);
		this._dollyEnd.set(0, distance);
		this._dollyDelta.set(0, Math.pow(this._dollyEnd.y / this._dollyStart.y, this.zoomSpeed));
		dollyOut(this._dollyDelta.y);
		this._dollyStart.copy(this._dollyEnd);
		var centerX = (event.pageX + position.x) * 0.5;
		var centerY = (event.pageY + position.y) * 0.5;
		updateZoomParameters(centerX, centerY);
	}

	private function handleTouchMoveDollyPan(event:Dynamic) {
		if (this.enableZoom) handleTouchMoveDolly(event);
		if (this.enablePan) handleTouchMovePan(event);
	}

	private function handleTouchMoveDollyRotate(event:Dynamic) {
		if (this.enableZoom) handleTouchMoveDolly(event);
		if (this.enableRotate) handleTouchMoveRotate(event);
	}

	// event handlers - FSM: listen for events and reset state

	private function onPointerDown(event:Dynamic) {
		if (this.enabled == false) return;
		if (this._pointers.length == 0) {
			this.domElement.setPointerCapture(event.pointerId);
			this.domElement.addEventListener('pointermove', this.onPointerMove);
			this.domElement.addEventListener('pointerup', this.onPointerUp);
		}
		if (isTrackingPointer(event)) return;
		addPointer(event);
		if (event.pointerType == 'touch') {
			onTouchStart(event);
		} else {
			onMouseDown(event);
		}
	}

	private function onPointerMove(event:Dynamic) {
		if (this.enabled == false) return;
		if (event.pointerType == 'touch') {
			onTouchMove(event);
		} else {
			onMouseMove(event);
		}
	}

	private function onPointerUp(event:Dynamic) {
		removePointer(event);
		switch (this._pointers.length) {
			case 0:
				this.domElement.releasePointerCapture(event.pointerId);
				this.domElement.removeEventListener('pointermove', this.onPointerMove);
				this.domElement.removeEventListener('pointerup', this.onPointerUp);
				this.dispatchEvent({type: 'end'});
				state = STATE.NONE;
				break;
			case 1:
				var pointerId = this._pointers[0];
				var position = this._pointerPositions[pointerId];
				onTouchStart({pointerId: pointerId, pageX: position.x, pageY: position.y});
				break;
		}
	}

	private function onMouseDown(event:Dynamic) {
		var mouseAction:Int;
		switch (event.button) {
			case 0:
				mouseAction = this.mouseButtons.LEFT;
				break;
			case 1:
				mouseAction = this.mouseButtons.MIDDLE;
				break;
			case 2:
				mouseAction = this.mouseButtons.RIGHT;
				break;
			default:
				mouseAction = -1;
		}
		switch (mouseAction) {
			case 0:
				if (this.enableZoom == false) return;
				handleMouseDownDolly(event);
				state = STATE.DOLLY;
				break;
			case 1:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (this.enablePan == false) return;
					handleMouseDownPan(event);
					state = STATE.PAN;
				} else {
					if (this.enableRotate == false) return;
					handleMouseDownRotate(event);
					state = STATE.ROTATE;
				}
				break;
			case 2:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (this.enableRotate == false) return;
					handleMouseDownRotate(event);
					state = STATE.ROTATE;
				} else {
					if (this.enablePan == false) return;
					handleMouseDownPan(event);
					state = STATE.PAN;
				}
				break;
			default:
				state = STATE.NONE;
		}
		if (state != STATE.NONE) {
			this.dispatchEvent({type: 'start'});
		}
	}

	private function onMouseMove(event:Dynamic) {
		switch (state) {
			case STATE.ROTATE:
				if (this.enableRotate == false) return;
				handleMouseMoveRotate(event);
				break;
			case STATE.DOLLY:
				if (this.enableZoom == false) return;
				handleMouseMoveDolly(event);
				break;
			case STATE.PAN:
				if (this.enablePan == false) return;
				handleMouseMovePan(event);
				break;
		}
	}

	private function onMouseWheel(event:Dynamic) {
		if (this.enabled == false || this.enableZoom == false || state != STATE.NONE) return;
		event.preventDefault();
		this.dispatchEvent({type: 'start'});
		handleMouseWheel(customWheelEvent(event));
		this.dispatchEvent({type: 'end
import three.core.EventDispatcher;
import three.math.Quaternion;
import three.math.Spherical;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Plane;
import three.math.Ray;
import three.math.MathUtils;
import three.cameras.Camera;
import three.cameras.PerspectiveCamera;
import three.cameras.OrthographicCamera;

// OrbitControls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
//
//    Orbit - left mouse / touch: one-finger move
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - right mouse, or left mouse + ctrl/meta/shiftKey, or arrow keys / touch: two-finger move

class OrbitControls extends EventDispatcher {

	public var object:Camera;
	public var domElement:Dynamic;

	// Set to false to disable this control
	public var enabled:Bool = true;

	// "target" sets the location of focus, where the object orbits around
	public var target:Vector3 = new Vector3();

	// Sets the 3D cursor (similar to Blender), from which the maxTargetRadius takes effect
	public var cursor:Vector3 = new Vector3();

	// How far you can dolly in and out ( PerspectiveCamera only )
	public var minDistance:Float = 0;
	public var maxDistance:Float = Math.POSITIVE_INFINITY;

	// How far you can zoom in and out ( OrthographicCamera only )
	public var minZoom:Float = 0;
	public var maxZoom:Float = Math.POSITIVE_INFINITY;

	// Limit camera target within a spherical area around the cursor
	public var minTargetRadius:Float = 0;
	public var maxTargetRadius:Float = Math.POSITIVE_INFINITY;

	// How far you can orbit vertically, upper and lower limits.
	// Range is 0 to Math.PI radians.
	public var minPolarAngle:Float = 0; // radians
	public var maxPolarAngle:Float = Math.PI; // radians

	// How far you can orbit horizontally, upper and lower limits.
	// If set, the interval [ min, max ] must be a sub-interval of [ - 2 PI, 2 PI ], with ( max - min < 2 PI )
	public var minAzimuthAngle:Float = -Math.POSITIVE_INFINITY; // radians
	public var maxAzimuthAngle:Float = Math.POSITIVE_INFINITY; // radians

	// Set to true to enable damping (inertia)
	// If damping is enabled, you must call controls.update() in your animation loop
	public var enableDamping:Bool = false;
	public var dampingFactor:Float = 0.05;

	// This option actually enables dollying in and out; left as "zoom" for backwards compatibility.
	// Set to false to disable zooming
	public var enableZoom:Bool = true;
	public var zoomSpeed:Float = 1.0;

	// Set to false to disable rotating
	public var enableRotate:Bool = true;
	public var rotateSpeed:Float = 1.0;

	// Set to false to disable panning
	public var enablePan:Bool = true;
	public var panSpeed:Float = 1.0;
	public var screenSpacePanning:Bool = true; // if false, pan orthogonal to world-space direction camera.up
	public var keyPanSpeed:Float = 7.0;	// pixels moved per arrow key push
	public var zoomToCursor:Bool = false;

	// Set to true to automatically rotate around the target
	// If auto-rotate is enabled, you must call controls.update() in your animation loop
	public var autoRotate:Bool = false;
	public var autoRotateSpeed:Float = 2.0; // 30 seconds per orbit when fps is 60

	// The four arrow keys
	public var keys:{ LEFT:String, UP:String, RIGHT:String, BOTTOM:String } = { LEFT: 'ArrowLeft', UP: 'ArrowUp', RIGHT: 'ArrowRight', BOTTOM: 'ArrowDown' };

	// Mouse buttons
	public var mouseButtons:{ LEFT:Int, MIDDLE:Int, RIGHT:Int } = { LEFT: 0, MIDDLE: 1, RIGHT: 2 };

	// Touch fingers
	public var touches:{ ONE:Int, TWO:Int } = { ONE: 0, TWO: 1 };

	// for reset
	public var target0:Vector3 = new Vector3();
	public var position0:Vector3 = new Vector3();
	public var zoom0:Float = 0;

	// the target DOM element for key events
	private var _domElementKeyEvents:Dynamic = null;

	private var _ray:Ray = new Ray();
	private var _plane:Plane = new Plane();
	private static inline var TILT_LIMIT:Float = Math.cos( 70 * MathUtils.DEG2RAD );
	private var _spherical:Spherical = new Spherical();
	private var _sphericalDelta:Spherical = new Spherical();
	private var _scale:Float = 1;
	private var _panOffset:Vector3 = new Vector3();
	private var _rotateStart:Vector2 = new Vector2();
	private var _rotateEnd:Vector2 = new Vector2();
	private var _rotateDelta:Vector2 = new Vector2();
	private var _panStart:Vector2 = new Vector2();
	private var _panEnd:Vector2 = new Vector2();
	private var _panDelta:Vector2 = new Vector2();
	private var _dollyStart:Vector2 = new Vector2();
	private var _dollyEnd:Vector2 = new Vector2();
	private var _dollyDelta:Vector2 = new Vector2();
	private var _dollyDirection:Vector3 = new Vector3();
	private var _mouse:Vector2 = new Vector2();
	private var _performCursorZoom:Bool = false;
	private var _pointers:Array<Int> = [];
	private var _pointerPositions:Map<Int, Vector2> = new Map();
	private var _controlActive:Bool = false;

	public function new(object:Camera, domElement:Dynamic) {
		super();

		this.object = object;
		this.domElement = domElement;
		this.domElement.style.touchAction = 'none'; // disable touch scroll

		this.target0.copy(this.target);
		this.position0.copy(this.object.position);
		this.zoom0 = this.object.zoom;

		domElement.addEventListener('contextmenu', this.onContextMenu);
		domElement.addEventListener('pointerdown', this.onPointerDown);
		domElement.addEventListener('pointercancel', this.onPointerUp);
		domElement.addEventListener('wheel', this.onMouseWheel, {passive: false});
		domElement.addEventListener('pointermove', this.onPointerMove);
		domElement.addEventListener('pointerup', this.onPointerUp);

		var document = this.domElement.getRootNode(); // offscreen canvas compatibility
		document.addEventListener('keydown', this.interceptControlDown, {capture: true});

		this.update();
	}

	public function getPolarAngle():Float {
		return this._spherical.phi;
	}

	public function getAzimuthalAngle():Float {
		return this._spherical.theta;
	}

	public function getDistance():Float {
		return this.object.position.distanceTo(this.target);
	}

	public function listenToKeyEvents(domElement:Dynamic) {
		domElement.addEventListener('keydown', this.onKeyDown);
		this._domElementKeyEvents = domElement;
	}

	public function stopListenToKeyEvents() {
		if (this._domElementKeyEvents != null) {
			this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
			this._domElementKeyEvents = null;
		}
	}

	public function saveState() {
		this.target0.copy(this.target);
		this.position0.copy(this.object.position);
		this.zoom0 = this.object.zoom;
	}

	public function reset() {
		this.target.copy(this.target0);
		this.object.position.copy(this.position0);
		this.object.zoom = this.zoom0;
		this.object.updateProjectionMatrix();
		this.dispatchEvent({type: 'change'});
		this.update();
	}

	public function update(deltaTime:Float = null) {
		var offset = new Vector3();
		var quat = new Quaternion().setFromUnitVectors(this.object.up, new Vector3(0, 1, 0));
		var quatInverse = quat.clone().invert();
		var lastPosition = new Vector3();
		var lastQuaternion = new Quaternion();
		var lastTargetPosition = new Vector3();
		var twoPI = 2 * Math.PI;

		var position = this.object.position;
		offset.copy(position).sub(this.target);
		offset.applyQuaternion(quat);
		this._spherical.setFromVector3(offset);

		if (this.autoRotate && state == STATE.NONE) {
			rotateLeft(getAutoRotationAngle(deltaTime));
		}

		if (this.enableDamping) {
			this._spherical.theta += this._sphericalDelta.theta * this.dampingFactor;
			this._spherical.phi += this._sphericalDelta.phi * this.dampingFactor;
		} else {
			this._spherical.theta += this._sphericalDelta.theta;
			this._spherical.phi += this._sphericalDelta.phi;
		}

		var min = this.minAzimuthAngle;
		var max = this.maxAzimuthAngle;
		if (isFinite(min) && isFinite(max)) {
			if (min < -Math.PI) min += twoPI; else if (min > Math.PI) min -= twoPI;
			if (max < -Math.PI) max += twoPI; else if (max > Math.PI) max -= twoPI;
			if (min <= max) {
				this._spherical.theta = Math.max(min, Math.min(max, this._spherical.theta));
			} else {
				this._spherical.theta = (this._spherical.theta > (min + max) / 2) ?
					Math.max(min, this._spherical.theta) :
					Math.min(max, this._spherical.theta);
			}
		}

		this._spherical.phi = Math.max(this.minPolarAngle, Math.min(this.maxPolarAngle, this._spherical.phi));
		this._spherical.makeSafe();

		if (this.enableDamping) {
			this.target.addScaledVector(this._panOffset, this.dampingFactor);
		} else {
			this.target.add(this._panOffset);
		}

		this.target.sub(this.cursor);
		this.target.clampLength(this.minTargetRadius, this.maxTargetRadius);
		this.target.add(this.cursor);

		var zoomChanged = false;
		if (this.zoomToCursor && this._performCursorZoom || this.object.isOrthographicCamera) {
			this._spherical.radius = clampDistance(this._spherical.radius);
		} else {
			var prevRadius = this._spherical.radius;
			this._spherical.radius = clampDistance(this._spherical.radius * this._scale);
			zoomChanged = prevRadius != this._spherical.radius;
		}

		offset.setFromSpherical(this._spherical);
		offset.applyQuaternion(quatInverse);
		position.copy(this.target).add(offset);
		this.object.lookAt(this.target);

		if (this.enableDamping) {
			this._sphericalDelta.theta *= (1 - this.dampingFactor);
			this._sphericalDelta.phi *= (1 - this.dampingFactor);
			this._panOffset.multiplyScalar(1 - this.dampingFactor);
		} else {
			this._sphericalDelta.set(0, 0, 0);
			this._panOffset.set(0, 0, 0);
		}

		if (this.zoomToCursor && this._performCursorZoom) {
			var newRadius:Float = null;
			if (this.object.isPerspectiveCamera) {
				var prevRadius = offset.length();
				newRadius = clampDistance(prevRadius * this._scale);
				var radiusDelta = prevRadius - newRadius;
				this.object.position.addScaledVector(this._dollyDirection, radiusDelta);
				this.object.updateMatrixWorld();
				zoomChanged = !!radiusDelta;
			} else if (this.object.isOrthographicCamera) {
				var mouseBefore = new Vector3(this._mouse.x, this._mouse.y, 0);
				mouseBefore.unproject(this.object);
				var prevZoom = this.object.zoom;
				this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this._scale));
				this.object.updateProjectionMatrix();
				zoomChanged = prevZoom != this.object.zoom;
				var mouseAfter = new Vector3(this._mouse.x, this._mouse.y, 0);
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
					this.target.set(0, 0, -1).transformDirection(this.object.matrix).multiplyScalar(newRadius).add(this.object.position);
				} else {
					this._ray.origin.copy(this.object.position);
					this._ray.direction.set(0, 0, -1).transformDirection(this.object.matrix);
					if (Math.abs(this.object.up.dot(this._ray.direction)) < TILT_LIMIT) {
						this.object.lookAt(this.target);
					} else {
						this._plane.setFromNormalAndCoplanarPoint(this.object.up, this.target);
						this._ray.intersectPlane(this._plane, this.target);
					}
				}
			}
		} else if (this.object.isOrthographicCamera) {
			var prevZoom = this.object.zoom;
			this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this._scale));
			if (prevZoom != this.object.zoom) {
				this.object.updateProjectionMatrix();
				zoomChanged = true;
			}
		}

		this._scale = 1;
		this._performCursorZoom = false;

		if (zoomChanged || lastPosition.distanceToSquared(this.object.position) > EPS || 8 * (1 - lastQuaternion.dot(this.object.quaternion)) > EPS || lastTargetPosition.distanceToSquared(this.target) > EPS) {
			this.dispatchEvent({type: 'change'});
			lastPosition.copy(this.object.position);
			lastQuaternion.copy(this.object.quaternion);
			lastTargetPosition.copy(this.target);
			return true;
		}

		return false;
	}

	public function dispose() {
		this.domElement.removeEventListener('contextmenu', this.onContextMenu);
		this.domElement.removeEventListener('pointerdown', this.onPointerDown);
		this.domElement.removeEventListener('pointercancel', this.onPointerUp);
		this.domElement.removeEventListener('wheel', this.onMouseWheel);
		this.domElement.removeEventListener('pointermove', this.onPointerMove);
		this.domElement.removeEventListener('pointerup', this.onPointerUp);
		var document = this.domElement.getRootNode(); // offscreen canvas compatibility
		document.removeEventListener('keydown', this.interceptControlDown, {capture: true});
		if (this._domElementKeyEvents != null) {
			this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
			this._domElementKeyEvents = null;
		}
	}

	private static inline var EPS:Float = 0.000001;

	private static inline var STATE = {
		NONE: -1,
		ROTATE: 0,
		DOLLY: 1,
		PAN: 2,
		TOUCH_ROTATE: 3,
		TOUCH_PAN: 4,
		TOUCH_DOLLY_PAN: 5,
		TOUCH_DOLLY_ROTATE: 6
	};

	private var state:Int = STATE.NONE;

	private function getAutoRotationAngle(deltaTime:Float):Float {
		if (deltaTime != null) {
			return (2 * Math.PI / 60 * this.autoRotateSpeed) * deltaTime;
		} else {
			return 2 * Math.PI / 60 / 60 * this.autoRotateSpeed;
		}
	}

	private function getZoomScale(delta:Float):Float {
		var normalizedDelta = Math.abs(delta * 0.01);
		return Math.pow(0.95, this.zoomSpeed * normalizedDelta);
	}

	private function rotateLeft(angle:Float) {
		this._sphericalDelta.theta -= angle;
	}

	private function rotateUp(angle:Float) {
		this._sphericalDelta.phi -= angle;
	}

	private function panLeft(distance:Float, objectMatrix:Matrix4) {
		var v = new Vector3();
		v.setFromMatrixColumn(objectMatrix, 0);
		v.multiplyScalar(-distance);
		this._panOffset.add(v);
	}

	private function panUp(distance:Float, objectMatrix:Matrix4) {
		var v = new Vector3();
		if (this.screenSpacePanning) {
			v.setFromMatrixColumn(objectMatrix, 1);
		} else {
			v.setFromMatrixColumn(objectMatrix, 0);
			v.crossVectors(this.object.up, v);
		}
		v.multiplyScalar(distance);
		this._panOffset.add(v);
	}

	private function pan(deltaX:Float, deltaY:Float) {
		var offset = new Vector3();
		var element = this.domElement;
		if (this.object.isPerspectiveCamera) {
			var position = this.object.position;
			offset.copy(position).sub(this.target);
			var targetDistance = offset.length();
			targetDistance *= Math.tan((this.object.fov / 2) * Math.PI / 180.0);
			panLeft(2 * deltaX * targetDistance / element.clientHeight, this.object.matrix);
			panUp(2 * deltaY * targetDistance / element.clientHeight, this.object.matrix);
		} else if (this.object.isOrthographicCamera) {
			panLeft(deltaX * (this.object.right - this.object.left) / this.object.zoom / element.clientWidth, this.object.matrix);
			panUp(deltaY * (this.object.top - this.object.bottom) / this.object.zoom / element.clientHeight, this.object.matrix);
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - pan disabled.');
			this.enablePan = false;
		}
	}

	private function dollyOut(dollyScale:Float) {
		if (this.object.isPerspectiveCamera || this.object.isOrthographicCamera) {
			this._scale /= dollyScale;
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
			this.enableZoom = false;
		}
	}

	private function dollyIn(dollyScale:Float) {
		if (this.object.isPerspectiveCamera || this.object.isOrthographicCamera) {
			this._scale *= dollyScale;
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
			this.enableZoom = false;
		}
	}

	private function updateZoomParameters(x:Float, y:Float) {
		if (!this.zoomToCursor) {
			return;
		}
		this._performCursorZoom = true;
		var rect = this.domElement.getBoundingClientRect();
		var dx = x - rect.left;
		var dy = y - rect.top;
		var w = rect.width;
		var h = rect.height;
		this._mouse.x = (dx / w) * 2 - 1;
		this._mouse.y = -(dy / h) * 2 + 1;
		this._dollyDirection.set(this._mouse.x, this._mouse.y, 1).unproject(this.object).sub(this.object.position).normalize();
	}

	private function clampDistance(dist:Float):Float {
		return Math.max(this.minDistance, Math.min(this.maxDistance, dist));
	}

	// event callbacks - update the object state

	private function handleMouseDownRotate(event:Dynamic) {
		this._rotateStart.set(event.clientX, event.clientY);
	}

	private function handleMouseDownDolly(event:Dynamic) {
		updateZoomParameters(event.clientX, event.clientX);
		this._dollyStart.set(event.clientX, event.clientY);
	}

	private function handleMouseDownPan(event:Dynamic) {
		this._panStart.set(event.clientX, event.clientY);
	}

	private function handleMouseMoveRotate(event:Dynamic) {
		this._rotateEnd.set(event.clientX, event.clientY);
		this._rotateDelta.subVectors(this._rotateEnd, this._rotateStart).multiplyScalar(this.rotateSpeed);
		var element = this.domElement;
		rotateLeft(2 * Math.PI * this._rotateDelta.x / element.clientHeight);
		rotateUp(2 * Math.PI * this._rotateDelta.y / element.clientHeight);
		this._rotateStart.copy(this._rotateEnd);
		this.update();
	}

	private function handleMouseMoveDolly(event:Dynamic) {
		this._dollyEnd.set(event.clientX, event.clientY);
		this._dollyDelta.subVectors(this._dollyEnd, this._dollyStart);
		if (this._dollyDelta.y > 0) {
			dollyOut(getZoomScale(this._dollyDelta.y));
		} else if (this._dollyDelta.y < 0) {
			dollyIn(getZoomScale(this._dollyDelta.y));
		}
		this._dollyStart.copy(this._dollyEnd);
		this.update();
	}

	private function handleMouseMovePan(event:Dynamic) {
		this._panEnd.set(event.clientX, event.clientY);
		this._panDelta.subVectors(this._panEnd, this._panStart).multiplyScalar(this.panSpeed);
		pan(this._panDelta.x, this._panDelta.y);
		this._panStart.copy(this._panEnd);
		this.update();
	}

	private function handleMouseWheel(event:Dynamic) {
		if (this.enabled == false || this.enableZoom == false || state != STATE.NONE) return;
		event.preventDefault();
		this.dispatchEvent({type: 'start'});
		handleMouseWheel(customWheelEvent(event));
		this.dispatchEvent({type: 'end'});
	}

	private function handleKeyDown(event:Dynamic) {
		var needsUpdate = false;
		switch (event.code) {
			case this.keys.UP:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateUp(2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(0, this.keyPanSpeed);
				}
				needsUpdate = true;
				break;
			case this.keys.BOTTOM:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateUp(-2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(0, -this.keyPanSpeed);
				}
				needsUpdate = true;
				break;
			case this.keys.LEFT:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateLeft(2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(this.keyPanSpeed, 0);
				}
				needsUpdate = true;
				break;
			case this.keys.RIGHT:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateLeft(-2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(-this.keyPanSpeed, 0);
				}
				needsUpdate = true;
				break;
		}
		if (needsUpdate) {
			event.preventDefault();
			this.update();
		}
	}

	private function handleTouchStartRotate(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._rotateStart.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._rotateStart.set(x, y);
		}
	}

	private function handleTouchStartPan(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._panStart.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._panStart.set(x, y);
		}
	}

	private function handleTouchStartDolly(event:Dynamic) {
		var position = getSecondPointerPosition(event);
		var dx = event.pageX - position.x;
		var dy = event.pageY - position.y;
		var distance = Math.sqrt(dx * dx + dy * dy);
		this._dollyStart.set(0, distance);
	}

	private function handleTouchStartDollyPan(event:Dynamic) {
		if (this.enableZoom) handleTouchStartDolly(event);
		if (this.enablePan) handleTouchStartPan(event);
	}

	private function handleTouchStartDollyRotate(event:Dynamic) {
		if (this.enableZoom) handleTouchStartDolly(event);
		if (this.enableRotate) handleTouchStartRotate(event);
	}

	private function handleTouchMoveRotate(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._rotateEnd.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._rotateEnd.set(x, y);
		}
		this._rotateDelta.subVectors(this._rotateEnd, this._rotateStart).multiplyScalar(this.rotateSpeed);
		var element = this.domElement;
		rotateLeft(2 * Math.PI * this._rotateDelta.x / element.clientHeight);
		rotateUp(2 * Math.PI * this._rotateDelta.y / element.clientHeight);
		this._rotateStart.copy(this._rotateEnd);
	}

	private function handleTouchMovePan(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._panEnd.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._panEnd.set(x, y);
		}
		this._panDelta.subVectors(this._panEnd, this._panStart).multiplyScalar(this.panSpeed);
		pan(this._panDelta.x, this._panDelta.y);
		this._panStart.copy(this._panEnd);
	}

	private function handleTouchMoveDolly(event:Dynamic) {
		var position = getSecondPointerPosition(event);
		var dx = event.pageX - position.x;
		var dy = event.pageY - position.y;
		var distance = Math.sqrt(dx * dx + dy * dy);
		this._dollyEnd.set(0, distance);
		this._dollyDelta.set(0, Math.pow(this._dollyEnd.y / this._dollyStart.y, this.zoomSpeed));
		dollyOut(this._dollyDelta.y);
		this._dollyStart.copy(this._dollyEnd);
		var centerX = (event.pageX + position.x) * 0.5;
		var centerY = (event.pageY + position.y) * 0.5;
		updateZoomParameters(centerX, centerY);
	}

	private function handleTouchMoveDollyPan(event:Dynamic) {
		if (this.enableZoom) handleTouchMoveDolly(event);
		if (this.enablePan) handleTouchMovePan(event);
	}

	private function handleTouchMoveDollyRotate(event:Dynamic) {
		if (this.enableZoom) handleTouchMoveDolly(event);
		if (this.enableRotate) handleTouchMoveRotate(event);
	}

	// event handlers - FSM: listen for events and reset state

	private function onPointerDown(event:Dynamic) {
		if (this.enabled == false) return;
		if (this._pointers.length == 0) {
			this.domElement.setPointerCapture(event.pointerId);
			this.domElement.addEventListener('pointermove', this.onPointerMove);
			this.domElement.addEventListener('pointerup', this.onPointerUp);
		}
		if (isTrackingPointer(event)) return;
		addPointer(event);
		if (event.pointerType == 'touch') {
			onTouchStart(event);
		} else {
			onMouseDown(event);
		}
	}

	private function onPointerMove(event:Dynamic) {
		if (this.enabled == false) return;
		if (event.pointerType == 'touch') {
			onTouchMove(event);
		} else {
			onMouseMove(event);
		}
	}

	private function onPointerUp(event:Dynamic) {
		removePointer(event);
		switch (this._pointers.length) {
			case 0:
				this.domElement.releasePointerCapture(event.pointerId);
				this.domElement.removeEventListener('pointermove', this.onPointerMove);
				this.domElement.removeEventListener('pointerup', this.onPointerUp);
				this.dispatchEvent({type: 'end'});
				state = STATE.NONE;
				break;
			case 1:
				var pointerId = this._pointers[0];
				var position = this._pointerPositions[pointerId];
				onTouchStart({pointerId: pointerId, pageX: position.x, pageY: position.y});
				break;
		}
	}

	private function onMouseDown(event:Dynamic) {
		var mouseAction:Int;
		switch (event.button) {
			case 0:
				mouseAction = this.mouseButtons.LEFT;
				break;
			case 1:
				mouseAction = this.mouseButtons.MIDDLE;
				break;
			case 2:
				mouseAction = this.mouseButtons.RIGHT;
				break;
			default:
				mouseAction = -1;
		}
		switch (mouseAction) {
			case 0:
				if (this.enableZoom == false) return;
				handleMouseDownDolly(event);
				state = STATE.DOLLY;
				break;
			case 1:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (this.enablePan == false) return;
					handleMouseDownPan(event);
					state = STATE.PAN;
				} else {
					if (this.enableRotate == false) return;
					handleMouseDownRotate(event);
					state = STATE.ROTATE;
				}
				break;
			case 2:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (this.enableRotate == false) return;
					handleMouseDownRotate(event);
					state = STATE.ROTATE;
				} else {
					if (this.enablePan == false) return;
					handleMouseDownPan(event);
					state = STATE.PAN;
				}
				break;
			default:
				state = STATE.NONE;
		}
		if (state != STATE.NONE) {
			this.dispatchEvent({type: 'start'});
		}
	}

	private function onMouseMove(event:Dynamic) {
		switch (state) {
			case STATE.ROTATE:
				if (this.enableRotate == false) return;
				handleMouseMoveRotate(event);
				break;
			case STATE.DOLLY:
				if (this.enableZoom == false) return;
				handleMouseMoveDolly(event);
				break;
			case STATE.PAN:
				if (this.enablePan == false) return;
				handleMouseMovePan(event);
				break;
		}
	}

	private function onMouseWheel(event:Dynamic) {
		if (this.enabled == false || this.enableZoom == false || state != STATE.NONE) return;
		event.preventDefault();
		this.dispatchEvent({type: 'start'});
		handleMouseWheel(customWheelEvent(event));
		this.dispatchEvent({type: 'end
import three.core.EventDispatcher;
import three.math.Quaternion;
import three.math.Spherical;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Plane;
import three.math.Ray;
import three.math.MathUtils;
import three.cameras.Camera;
import three.cameras.PerspectiveCamera;
import three.cameras.OrthographicCamera;

// OrbitControls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
//
//    Orbit - left mouse / touch: one-finger move
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - right mouse, or left mouse + ctrl/meta/shiftKey, or arrow keys / touch: two-finger move

class OrbitControls extends EventDispatcher {

	public var object:Camera;
	public var domElement:Dynamic;

	// Set to false to disable this control
	public var enabled:Bool = true;

	// "target" sets the location of focus, where the object orbits around
	public var target:Vector3 = new Vector3();

	// Sets the 3D cursor (similar to Blender), from which the maxTargetRadius takes effect
	public var cursor:Vector3 = new Vector3();

	// How far you can dolly in and out ( PerspectiveCamera only )
	public var minDistance:Float = 0;
	public var maxDistance:Float = Math.POSITIVE_INFINITY;

	// How far you can zoom in and out ( OrthographicCamera only )
	public var minZoom:Float = 0;
	public var maxZoom:Float = Math.POSITIVE_INFINITY;

	// Limit camera target within a spherical area around the cursor
	public var minTargetRadius:Float = 0;
	public var maxTargetRadius:Float = Math.POSITIVE_INFINITY;

	// How far you can orbit vertically, upper and lower limits.
	// Range is 0 to Math.PI radians.
	public var minPolarAngle:Float = 0; // radians
	public var maxPolarAngle:Float = Math.PI; // radians

	// How far you can orbit horizontally, upper and lower limits.
	// If set, the interval [ min, max ] must be a sub-interval of [ - 2 PI, 2 PI ], with ( max - min < 2 PI )
	public var minAzimuthAngle:Float = -Math.POSITIVE_INFINITY; // radians
	public var maxAzimuthAngle:Float = Math.POSITIVE_INFINITY; // radians

	// Set to true to enable damping (inertia)
	// If damping is enabled, you must call controls.update() in your animation loop
	public var enableDamping:Bool = false;
	public var dampingFactor:Float = 0.05;

	// This option actually enables dollying in and out; left as "zoom" for backwards compatibility.
	// Set to false to disable zooming
	public var enableZoom:Bool = true;
	public var zoomSpeed:Float = 1.0;

	// Set to false to disable rotating
	public var enableRotate:Bool = true;
	public var rotateSpeed:Float = 1.0;

	// Set to false to disable panning
	public var enablePan:Bool = true;
	public var panSpeed:Float = 1.0;
	public var screenSpacePanning:Bool = true; // if false, pan orthogonal to world-space direction camera.up
	public var keyPanSpeed:Float = 7.0;	// pixels moved per arrow key push
	public var zoomToCursor:Bool = false;

	// Set to true to automatically rotate around the target
	// If auto-rotate is enabled, you must call controls.update() in your animation loop
	public var autoRotate:Bool = false;
	public var autoRotateSpeed:Float = 2.0; // 30 seconds per orbit when fps is 60

	// The four arrow keys
	public var keys:{ LEFT:String, UP:String, RIGHT:String, BOTTOM:String } = { LEFT: 'ArrowLeft', UP: 'ArrowUp', RIGHT: 'ArrowRight', BOTTOM: 'ArrowDown' };

	// Mouse buttons
	public var mouseButtons:{ LEFT:Int, MIDDLE:Int, RIGHT:Int } = { LEFT: 0, MIDDLE: 1, RIGHT: 2 };

	// Touch fingers
	public var touches:{ ONE:Int, TWO:Int } = { ONE: 0, TWO: 1 };

	// for reset
	public var target0:Vector3 = new Vector3();
	public var position0:Vector3 = new Vector3();
	public var zoom0:Float = 0;

	// the target DOM element for key events
	private var _domElementKeyEvents:Dynamic = null;

	private var _ray:Ray = new Ray();
	private var _plane:Plane = new Plane();
	private static inline var TILT_LIMIT:Float = Math.cos( 70 * MathUtils.DEG2RAD );
	private var _spherical:Spherical = new Spherical();
	private var _sphericalDelta:Spherical = new Spherical();
	private var _scale:Float = 1;
	private var _panOffset:Vector3 = new Vector3();
	private var _rotateStart:Vector2 = new Vector2();
	private var _rotateEnd:Vector2 = new Vector2();
	private var _rotateDelta:Vector2 = new Vector2();
	private var _panStart:Vector2 = new Vector2();
	private var _panEnd:Vector2 = new Vector2();
	private var _panDelta:Vector2 = new Vector2();
	private var _dollyStart:Vector2 = new Vector2();
	private var _dollyEnd:Vector2 = new Vector2();
	private var _dollyDelta:Vector2 = new Vector2();
	private var _dollyDirection:Vector3 = new Vector3();
	private var _mouse:Vector2 = new Vector2();
	private var _performCursorZoom:Bool = false;
	private var _pointers:Array<Int> = [];
	private var _pointerPositions:Map<Int, Vector2> = new Map();
	private var _controlActive:Bool = false;

	public function new(object:Camera, domElement:Dynamic) {
		super();

		this.object = object;
		this.domElement = domElement;
		this.domElement.style.touchAction = 'none'; // disable touch scroll

		this.target0.copy(this.target);
		this.position0.copy(this.object.position);
		this.zoom0 = this.object.zoom;

		domElement.addEventListener('contextmenu', this.onContextMenu);
		domElement.addEventListener('pointerdown', this.onPointerDown);
		domElement.addEventListener('pointercancel', this.onPointerUp);
		domElement.addEventListener('wheel', this.onMouseWheel, {passive: false});
		domElement.addEventListener('pointermove', this.onPointerMove);
		domElement.addEventListener('pointerup', this.onPointerUp);

		var document = this.domElement.getRootNode(); // offscreen canvas compatibility
		document.addEventListener('keydown', this.interceptControlDown, {capture: true});

		this.update();
	}

	public function getPolarAngle():Float {
		return this._spherical.phi;
	}

	public function getAzimuthalAngle():Float {
		return this._spherical.theta;
	}

	public function getDistance():Float {
		return this.object.position.distanceTo(this.target);
	}

	public function listenToKeyEvents(domElement:Dynamic) {
		domElement.addEventListener('keydown', this.onKeyDown);
		this._domElementKeyEvents = domElement;
	}

	public function stopListenToKeyEvents() {
		if (this._domElementKeyEvents != null) {
			this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
			this._domElementKeyEvents = null;
		}
	}

	public function saveState() {
		this.target0.copy(this.target);
		this.position0.copy(this.object.position);
		this.zoom0 = this.object.zoom;
	}

	public function reset() {
		this.target.copy(this.target0);
		this.object.position.copy(this.position0);
		this.object.zoom = this.zoom0;
		this.object.updateProjectionMatrix();
		this.dispatchEvent({type: 'change'});
		this.update();
	}

	public function update(deltaTime:Float = null) {
		var offset = new Vector3();
		var quat = new Quaternion().setFromUnitVectors(this.object.up, new Vector3(0, 1, 0));
		var quatInverse = quat.clone().invert();
		var lastPosition = new Vector3();
		var lastQuaternion = new Quaternion();
		var lastTargetPosition = new Vector3();
		var twoPI = 2 * Math.PI;

		var position = this.object.position;
		offset.copy(position).sub(this.target);
		offset.applyQuaternion(quat);
		this._spherical.setFromVector3(offset);

		if (this.autoRotate && state == STATE.NONE) {
			rotateLeft(getAutoRotationAngle(deltaTime));
		}

		if (this.enableDamping) {
			this._spherical.theta += this._sphericalDelta.theta * this.dampingFactor;
			this._spherical.phi += this._sphericalDelta.phi * this.dampingFactor;
		} else {
			this._spherical.theta += this._sphericalDelta.theta;
			this._spherical.phi += this._sphericalDelta.phi;
		}

		var min = this.minAzimuthAngle;
		var max = this.maxAzimuthAngle;
		if (isFinite(min) && isFinite(max)) {
			if (min < -Math.PI) min += twoPI; else if (min > Math.PI) min -= twoPI;
			if (max < -Math.PI) max += twoPI; else if (max > Math.PI) max -= twoPI;
			if (min <= max) {
				this._spherical.theta = Math.max(min, Math.min(max, this._spherical.theta));
			} else {
				this._spherical.theta = (this._spherical.theta > (min + max) / 2) ?
					Math.max(min, this._spherical.theta) :
					Math.min(max, this._spherical.theta);
			}
		}

		this._spherical.phi = Math.max(this.minPolarAngle, Math.min(this.maxPolarAngle, this._spherical.phi));
		this._spherical.makeSafe();

		if (this.enableDamping) {
			this.target.addScaledVector(this._panOffset, this.dampingFactor);
		} else {
			this.target.add(this._panOffset);
		}

		this.target.sub(this.cursor);
		this.target.clampLength(this.minTargetRadius, this.maxTargetRadius);
		this.target.add(this.cursor);

		var zoomChanged = false;
		if (this.zoomToCursor && this._performCursorZoom || this.object.isOrthographicCamera) {
			this._spherical.radius = clampDistance(this._spherical.radius);
		} else {
			var prevRadius = this._spherical.radius;
			this._spherical.radius = clampDistance(this._spherical.radius * this._scale);
			zoomChanged = prevRadius != this._spherical.radius;
		}

		offset.setFromSpherical(this._spherical);
		offset.applyQuaternion(quatInverse);
		position.copy(this.target).add(offset);
		this.object.lookAt(this.target);

		if (this.enableDamping) {
			this._sphericalDelta.theta *= (1 - this.dampingFactor);
			this._sphericalDelta.phi *= (1 - this.dampingFactor);
			this._panOffset.multiplyScalar(1 - this.dampingFactor);
		} else {
			this._sphericalDelta.set(0, 0, 0);
			this._panOffset.set(0, 0, 0);
		}

		if (this.zoomToCursor && this._performCursorZoom) {
			var newRadius:Float = null;
			if (this.object.isPerspectiveCamera) {
				var prevRadius = offset.length();
				newRadius = clampDistance(prevRadius * this._scale);
				var radiusDelta = prevRadius - newRadius;
				this.object.position.addScaledVector(this._dollyDirection, radiusDelta);
				this.object.updateMatrixWorld();
				zoomChanged = !!radiusDelta;
			} else if (this.object.isOrthographicCamera) {
				var mouseBefore = new Vector3(this._mouse.x, this._mouse.y, 0);
				mouseBefore.unproject(this.object);
				var prevZoom = this.object.zoom;
				this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this._scale));
				this.object.updateProjectionMatrix();
				zoomChanged = prevZoom != this.object.zoom;
				var mouseAfter = new Vector3(this._mouse.x, this._mouse.y, 0);
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
					this.target.set(0, 0, -1).transformDirection(this.object.matrix).multiplyScalar(newRadius).add(this.object.position);
				} else {
					this._ray.origin.copy(this.object.position);
					this._ray.direction.set(0, 0, -1).transformDirection(this.object.matrix);
					if (Math.abs(this.object.up.dot(this._ray.direction)) < TILT_LIMIT) {
						this.object.lookAt(this.target);
					} else {
						this._plane.setFromNormalAndCoplanarPoint(this.object.up, this.target);
						this._ray.intersectPlane(this._plane, this.target);
					}
				}
			}
		} else if (this.object.isOrthographicCamera) {
			var prevZoom = this.object.zoom;
			this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this._scale));
			if (prevZoom != this.object.zoom) {
				this.object.updateProjectionMatrix();
				zoomChanged = true;
			}
		}

		this._scale = 1;
		this._performCursorZoom = false;

		if (zoomChanged || lastPosition.distanceToSquared(this.object.position) > EPS || 8 * (1 - lastQuaternion.dot(this.object.quaternion)) > EPS || lastTargetPosition.distanceToSquared(this.target) > EPS) {
			this.dispatchEvent({type: 'change'});
			lastPosition.copy(this.object.position);
			lastQuaternion.copy(this.object.quaternion);
			lastTargetPosition.copy(this.target);
			return true;
		}

		return false;
	}

	public function dispose() {
		this.domElement.removeEventListener('contextmenu', this.onContextMenu);
		this.domElement.removeEventListener('pointerdown', this.onPointerDown);
		this.domElement.removeEventListener('pointercancel', this.onPointerUp);
		this.domElement.removeEventListener('wheel', this.onMouseWheel);
		this.domElement.removeEventListener('pointermove', this.onPointerMove);
		this.domElement.removeEventListener('pointerup', this.onPointerUp);
		var document = this.domElement.getRootNode(); // offscreen canvas compatibility
		document.removeEventListener('keydown', this.interceptControlDown, {capture: true});
		if (this._domElementKeyEvents != null) {
			this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
			this._domElementKeyEvents = null;
		}
	}

	private static inline var EPS:Float = 0.000001;

	private static inline var STATE = {
		NONE: -1,
		ROTATE: 0,
		DOLLY: 1,
		PAN: 2,
		TOUCH_ROTATE: 3,
		TOUCH_PAN: 4,
		TOUCH_DOLLY_PAN: 5,
		TOUCH_DOLLY_ROTATE: 6
	};

	private var state:Int = STATE.NONE;

	private function getAutoRotationAngle(deltaTime:Float):Float {
		if (deltaTime != null) {
			return (2 * Math.PI / 60 * this.autoRotateSpeed) * deltaTime;
		} else {
			return 2 * Math.PI / 60 / 60 * this.autoRotateSpeed;
		}
	}

	private function getZoomScale(delta:Float):Float {
		var normalizedDelta = Math.abs(delta * 0.01);
		return Math.pow(0.95, this.zoomSpeed * normalizedDelta);
	}

	private function rotateLeft(angle:Float) {
		this._sphericalDelta.theta -= angle;
	}

	private function rotateUp(angle:Float) {
		this._sphericalDelta.phi -= angle;
	}

	private function panLeft(distance:Float, objectMatrix:Matrix4) {
		var v = new Vector3();
		v.setFromMatrixColumn(objectMatrix, 0);
		v.multiplyScalar(-distance);
		this._panOffset.add(v);
	}

	private function panUp(distance:Float, objectMatrix:Matrix4) {
		var v = new Vector3();
		if (this.screenSpacePanning) {
			v.setFromMatrixColumn(objectMatrix, 1);
		} else {
			v.setFromMatrixColumn(objectMatrix, 0);
			v.crossVectors(this.object.up, v);
		}
		v.multiplyScalar(distance);
		this._panOffset.add(v);
	}

	private function pan(deltaX:Float, deltaY:Float) {
		var offset = new Vector3();
		var element = this.domElement;
		if (this.object.isPerspectiveCamera) {
			var position = this.object.position;
			offset.copy(position).sub(this.target);
			var targetDistance = offset.length();
			targetDistance *= Math.tan((this.object.fov / 2) * Math.PI / 180.0);
			panLeft(2 * deltaX * targetDistance / element.clientHeight, this.object.matrix);
			panUp(2 * deltaY * targetDistance / element.clientHeight, this.object.matrix);
		} else if (this.object.isOrthographicCamera) {
			panLeft(deltaX * (this.object.right - this.object.left) / this.object.zoom / element.clientWidth, this.object.matrix);
			panUp(deltaY * (this.object.top - this.object.bottom) / this.object.zoom / element.clientHeight, this.object.matrix);
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - pan disabled.');
			this.enablePan = false;
		}
	}

	private function dollyOut(dollyScale:Float) {
		if (this.object.isPerspectiveCamera || this.object.isOrthographicCamera) {
			this._scale /= dollyScale;
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
			this.enableZoom = false;
		}
	}

	private function dollyIn(dollyScale:Float) {
		if (this.object.isPerspectiveCamera || this.object.isOrthographicCamera) {
			this._scale *= dollyScale;
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
			this.enableZoom = false;
		}
	}

	private function updateZoomParameters(x:Float, y:Float) {
		if (!this.zoomToCursor) {
			return;
		}
		this._performCursorZoom = true;
		var rect = this.domElement.getBoundingClientRect();
		var dx = x - rect.left;
		var dy = y - rect.top;
		var w = rect.width;
		var h = rect.height;
		this._mouse.x = (dx / w) * 2 - 1;
		this._mouse.y = -(dy / h) * 2 + 1;
		this._dollyDirection.set(this._mouse.x, this._mouse.y, 1).unproject(this.object).sub(this.object.position).normalize();
	}

	private function clampDistance(dist:Float):Float {
		return Math.max(this.minDistance, Math.min(this.maxDistance, dist));
	}

	// event callbacks - update the object state

	private function handleMouseDownRotate(event:Dynamic) {
		this._rotateStart.set(event.clientX, event.clientY);
	}

	private function handleMouseDownDolly(event:Dynamic) {
		updateZoomParameters(event.clientX, event.clientX);
		this._dollyStart.set(event.clientX, event.clientY);
	}

	private function handleMouseDownPan(event:Dynamic) {
		this._panStart.set(event.clientX, event.clientY);
	}

	private function handleMouseMoveRotate(event:Dynamic) {
		this._rotateEnd.set(event.clientX, event.clientY);
		this._rotateDelta.subVectors(this._rotateEnd, this._rotateStart).multiplyScalar(this.rotateSpeed);
		var element = this.domElement;
		rotateLeft(2 * Math.PI * this._rotateDelta.x / element.clientHeight);
		rotateUp(2 * Math.PI * this._rotateDelta.y / element.clientHeight);
		this._rotateStart.copy(this._rotateEnd);
		this.update();
	}

	private function handleMouseMoveDolly(event:Dynamic) {
		this._dollyEnd.set(event.clientX, event.clientY);
		this._dollyDelta.subVectors(this._dollyEnd, this._dollyStart);
		if (this._dollyDelta.y > 0) {
			dollyOut(getZoomScale(this._dollyDelta.y));
		} else if (this._dollyDelta.y < 0) {
			dollyIn(getZoomScale(this._dollyDelta.y));
		}
		this._dollyStart.copy(this._dollyEnd);
		this.update();
	}

	private function handleMouseMovePan(event:Dynamic) {
		this._panEnd.set(event.clientX, event.clientY);
		this._panDelta.subVectors(this._panEnd, this._panStart).multiplyScalar(this.panSpeed);
		pan(this._panDelta.x, this._panDelta.y);
		this._panStart.copy(this._panEnd);
		this.update();
	}

	private function handleMouseWheel(event:Dynamic) {
		if (this.enabled == false || this.enableZoom == false || state != STATE.NONE) return;
		event.preventDefault();
		this.dispatchEvent({type: 'start'});
		handleMouseWheel(customWheelEvent(event));
		this.dispatchEvent({type: 'end'});
	}

	private function handleKeyDown(event:Dynamic) {
		var needsUpdate = false;
		switch (event.code) {
			case this.keys.UP:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateUp(2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(0, this.keyPanSpeed);
				}
				needsUpdate = true;
				break;
			case this.keys.BOTTOM:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateUp(-2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(0, -this.keyPanSpeed);
				}
				needsUpdate = true;
				break;
			case this.keys.LEFT:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateLeft(2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(this.keyPanSpeed, 0);
				}
				needsUpdate = true;
				break;
			case this.keys.RIGHT:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateLeft(-2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(-this.keyPanSpeed, 0);
				}
				needsUpdate = true;
				break;
		}
		if (needsUpdate) {
			event.preventDefault();
			this.update();
		}
	}

	private function handleTouchStartRotate(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._rotateStart.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._rotateStart.set(x, y);
		}
	}

	private function handleTouchStartPan(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._panStart.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._panStart.set(x, y);
		}
	}

	private function handleTouchStartDolly(event:Dynamic) {
		var position = getSecondPointerPosition(event);
		var dx = event.pageX - position.x;
		var dy = event.pageY - position.y;
		var distance = Math.sqrt(dx * dx + dy * dy);
		this._dollyStart.set(0, distance);
	}

	private function handleTouchStartDollyPan(event:Dynamic) {
		if (this.enableZoom) handleTouchStartDolly(event);
		if (this.enablePan) handleTouchStartPan(event);
	}

	private function handleTouchStartDollyRotate(event:Dynamic) {
		if (this.enableZoom) handleTouchStartDolly(event);
		if (this.enableRotate) handleTouchStartRotate(event);
	}

	private function handleTouchMoveRotate(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._rotateEnd.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._rotateEnd.set(x, y);
		}
		this._rotateDelta.subVectors(this._rotateEnd, this._rotateStart).multiplyScalar(this.rotateSpeed);
		var element = this.domElement;
		rotateLeft(2 * Math.PI * this._rotateDelta.x / element.clientHeight);
		rotateUp(2 * Math.PI * this._rotateDelta.y / element.clientHeight);
		this._rotateStart.copy(this._rotateEnd);
	}

	private function handleTouchMovePan(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._panEnd.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._panEnd.set(x, y);
		}
		this._panDelta.subVectors(this._panEnd, this._panStart).multiplyScalar(this.panSpeed);
		pan(this._panDelta.x, this._panDelta.y);
		this._panStart.copy(this._panEnd);
	}

	private function handleTouchMoveDolly(event:Dynamic) {
		var position = getSecondPointerPosition(event);
		var dx = event.pageX - position.x;
		var dy = event.pageY - position.y;
		var distance = Math.sqrt(dx * dx + dy * dy);
		this._dollyEnd.set(0, distance);
		this._dollyDelta.set(0, Math.pow(this._dollyEnd.y / this._dollyStart.y, this.zoomSpeed));
		dollyOut(this._dollyDelta.y);
		this._dollyStart.copy(this._dollyEnd);
		var centerX = (event.pageX + position.x) * 0.5;
		var centerY = (event.pageY + position.y) * 0.5;
		updateZoomParameters(centerX, centerY);
	}

	private function handleTouchMoveDollyPan(event:Dynamic) {
		if (this.enableZoom) handleTouchMoveDolly(event);
		if (this.enablePan) handleTouchMovePan(event);
	}

	private function handleTouchMoveDollyRotate(event:Dynamic) {
		if (this.enableZoom) handleTouchMoveDolly(event);
		if (this.enableRotate) handleTouchMoveRotate(event);
	}

	// event handlers - FSM: listen for events and reset state

	private function onPointerDown(event:Dynamic) {
		if (this.enabled == false) return;
		if (this._pointers.length == 0) {
			this.domElement.setPointerCapture(event.pointerId);
			this.domElement.addEventListener('pointermove', this.onPointerMove);
			this.domElement.addEventListener('pointerup', this.onPointerUp);
		}
		if (isTrackingPointer(event)) return;
		addPointer(event);
		if (event.pointerType == 'touch') {
			onTouchStart(event);
		} else {
			onMouseDown(event);
		}
	}

	private function onPointerMove(event:Dynamic) {
		if (this.enabled == false) return;
		if (event.pointerType == 'touch') {
			onTouchMove(event);
		} else {
			onMouseMove(event);
		}
	}

	private function onPointerUp(event:Dynamic) {
		removePointer(event);
		switch (this._pointers.length) {
			case 0:
				this.domElement.releasePointerCapture(event.pointerId);
				this.domElement.removeEventListener('pointermove', this.onPointerMove);
				this.domElement.removeEventListener('pointerup', this.onPointerUp);
				this.dispatchEvent({type: 'end'});
				state = STATE.NONE;
				break;
			case 1:
				var pointerId = this._pointers[0];
				var position = this._pointerPositions[pointerId];
				onTouchStart({pointerId: pointerId, pageX: position.x, pageY: position.y});
				break;
		}
	}

	private function onMouseDown(event:Dynamic) {
		var mouseAction:Int;
		switch (event.button) {
			case 0:
				mouseAction = this.mouseButtons.LEFT;
				break;
			case 1:
				mouseAction = this.mouseButtons.MIDDLE;
				break;
			case 2:
				mouseAction = this.mouseButtons.RIGHT;
				break;
			default:
				mouseAction = -1;
		}
		switch (mouseAction) {
			case 0:
				if (this.enableZoom == false) return;
				handleMouseDownDolly(event);
				state = STATE.DOLLY;
				break;
			case 1:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (this.enablePan == false) return;
					handleMouseDownPan(event);
					state = STATE.PAN;
				} else {
					if (this.enableRotate == false) return;
					handleMouseDownRotate(event);
					state = STATE.ROTATE;
				}
				break;
			case 2:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (this.enableRotate == false) return;
					handleMouseDownRotate(event);
					state = STATE.ROTATE;
				} else {
					if (this.enablePan == false) return;
					handleMouseDownPan(event);
					state = STATE.PAN;
				}
				break;
			default:
				state = STATE.NONE;
		}
		if (state != STATE.NONE) {
			this.dispatchEvent({type: 'start'});
		}
	}

	private function onMouseMove(event:Dynamic) {
		switch (state) {
			case STATE.ROTATE:
				if (this.enableRotate == false) return;
				handleMouseMoveRotate(event);
				break;
			case STATE.DOLLY:
				if (this.enableZoom == false) return;
				handleMouseMoveDolly(event);
				break;
			case STATE.PAN:
				if (this.enablePan == false) return;
				handleMouseMovePan(event);
				break;
		}
	}

	private function onMouseWheel(event:Dynamic) {
		if (this.enabled == false || this.enableZoom == false || state != STATE.NONE) return;
		event.preventDefault();
		this.dispatchEvent({type: 'start'});
		handleMouseWheel(customWheelEvent(event));
		this.dispatchEvent({type: 'end
import three.core.EventDispatcher;
import three.math.Quaternion;
import three.math.Spherical;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Plane;
import three.math.Ray;
import three.math.MathUtils;
import three.cameras.Camera;
import three.cameras.PerspectiveCamera;
import three.cameras.OrthographicCamera;

// OrbitControls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
//
//    Orbit - left mouse / touch: one-finger move
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - right mouse, or left mouse + ctrl/meta/shiftKey, or arrow keys / touch: two-finger move

class OrbitControls extends EventDispatcher {

	public var object:Camera;
	public var domElement:Dynamic;

	// Set to false to disable this control
	public var enabled:Bool = true;

	// "target" sets the location of focus, where the object orbits around
	public var target:Vector3 = new Vector3();

	// Sets the 3D cursor (similar to Blender), from which the maxTargetRadius takes effect
	public var cursor:Vector3 = new Vector3();

	// How far you can dolly in and out ( PerspectiveCamera only )
	public var minDistance:Float = 0;
	public var maxDistance:Float = Math.POSITIVE_INFINITY;

	// How far you can zoom in and out ( OrthographicCamera only )
	public var minZoom:Float = 0;
	public var maxZoom:Float = Math.POSITIVE_INFINITY;

	// Limit camera target within a spherical area around the cursor
	public var minTargetRadius:Float = 0;
	public var maxTargetRadius:Float = Math.POSITIVE_INFINITY;

	// How far you can orbit vertically, upper and lower limits.
	// Range is 0 to Math.PI radians.
	public var minPolarAngle:Float = 0; // radians
	public var maxPolarAngle:Float = Math.PI; // radians

	// How far you can orbit horizontally, upper and lower limits.
	// If set, the interval [ min, max ] must be a sub-interval of [ - 2 PI, 2 PI ], with ( max - min < 2 PI )
	public var minAzimuthAngle:Float = -Math.POSITIVE_INFINITY; // radians
	public var maxAzimuthAngle:Float = Math.POSITIVE_INFINITY; // radians

	// Set to true to enable damping (inertia)
	// If damping is enabled, you must call controls.update() in your animation loop
	public var enableDamping:Bool = false;
	public var dampingFactor:Float = 0.05;

	// This option actually enables dollying in and out; left as "zoom" for backwards compatibility.
	// Set to false to disable zooming
	public var enableZoom:Bool = true;
	public var zoomSpeed:Float = 1.0;

	// Set to false to disable rotating
	public var enableRotate:Bool = true;
	public var rotateSpeed:Float = 1.0;

	// Set to false to disable panning
	public var enablePan:Bool = true;
	public var panSpeed:Float = 1.0;
	public var screenSpacePanning:Bool = true; // if false, pan orthogonal to world-space direction camera.up
	public var keyPanSpeed:Float = 7.0;	// pixels moved per arrow key push
	public var zoomToCursor:Bool = false;

	// Set to true to automatically rotate around the target
	// If auto-rotate is enabled, you must call controls.update() in your animation loop
	public var autoRotate:Bool = false;
	public var autoRotateSpeed:Float = 2.0; // 30 seconds per orbit when fps is 60

	// The four arrow keys
	public var keys:{ LEFT:String, UP:String, RIGHT:String, BOTTOM:String } = { LEFT: 'ArrowLeft', UP: 'ArrowUp', RIGHT: 'ArrowRight', BOTTOM: 'ArrowDown' };

	// Mouse buttons
	public var mouseButtons:{ LEFT:Int, MIDDLE:Int, RIGHT:Int } = { LEFT: 0, MIDDLE: 1, RIGHT: 2 };

	// Touch fingers
	public var touches:{ ONE:Int, TWO:Int } = { ONE: 0, TWO: 1 };

	// for reset
	public var target0:Vector3 = new Vector3();
	public var position0:Vector3 = new Vector3();
	public var zoom0:Float = 0;

	// the target DOM element for key events
	private var _domElementKeyEvents:Dynamic = null;

	private var _ray:Ray = new Ray();
	private var _plane:Plane = new Plane();
	private static inline var TILT_LIMIT:Float = Math.cos( 70 * MathUtils.DEG2RAD );
	private var _spherical:Spherical = new Spherical();
	private var _sphericalDelta:Spherical = new Spherical();
	private var _scale:Float = 1;
	private var _panOffset:Vector3 = new Vector3();
	private var _rotateStart:Vector2 = new Vector2();
	private var _rotateEnd:Vector2 = new Vector2();
	private var _rotateDelta:Vector2 = new Vector2();
	private var _panStart:Vector2 = new Vector2();
	private var _panEnd:Vector2 = new Vector2();
	private var _panDelta:Vector2 = new Vector2();
	private var _dollyStart:Vector2 = new Vector2();
	private var _dollyEnd:Vector2 = new Vector2();
	private var _dollyDelta:Vector2 = new Vector2();
	private var _dollyDirection:Vector3 = new Vector3();
	private var _mouse:Vector2 = new Vector2();
	private var _performCursorZoom:Bool = false;
	private var _pointers:Array<Int> = [];
	private var _pointerPositions:Map<Int, Vector2> = new Map();
	private var _controlActive:Bool = false;

	public function new(object:Camera, domElement:Dynamic) {
		super();

		this.object = object;
		this.domElement = domElement;
		this.domElement.style.touchAction = 'none'; // disable touch scroll

		this.target0.copy(this.target);
		this.position0.copy(this.object.position);
		this.zoom0 = this.object.zoom;

		domElement.addEventListener('contextmenu', this.onContextMenu);
		domElement.addEventListener('pointerdown', this.onPointerDown);
		domElement.addEventListener('pointercancel', this.onPointerUp);
		domElement.addEventListener('wheel', this.onMouseWheel, {passive: false});
		domElement.addEventListener('pointermove', this.onPointerMove);
		domElement.addEventListener('pointerup', this.onPointerUp);

		var document = this.domElement.getRootNode(); // offscreen canvas compatibility
		document.addEventListener('keydown', this.interceptControlDown, {capture: true});

		this.update();
	}

	public function getPolarAngle():Float {
		return this._spherical.phi;
	}

	public function getAzimuthalAngle():Float {
		return this._spherical.theta;
	}

	public function getDistance():Float {
		return this.object.position.distanceTo(this.target);
	}

	public function listenToKeyEvents(domElement:Dynamic) {
		domElement.addEventListener('keydown', this.onKeyDown);
		this._domElementKeyEvents = domElement;
	}

	public function stopListenToKeyEvents() {
		if (this._domElementKeyEvents != null) {
			this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
			this._domElementKeyEvents = null;
		}
	}

	public function saveState() {
		this.target0.copy(this.target);
		this.position0.copy(this.object.position);
		this.zoom0 = this.object.zoom;
	}

	public function reset() {
		this.target.copy(this.target0);
		this.object.position.copy(this.position0);
		this.object.zoom = this.zoom0;
		this.object.updateProjectionMatrix();
		this.dispatchEvent({type: 'change'});
		this.update();
	}

	public function update(deltaTime:Float = null) {
		var offset = new Vector3();
		var quat = new Quaternion().setFromUnitVectors(this.object.up, new Vector3(0, 1, 0));
		var quatInverse = quat.clone().invert();
		var lastPosition = new Vector3();
		var lastQuaternion = new Quaternion();
		var lastTargetPosition = new Vector3();
		var twoPI = 2 * Math.PI;

		var position = this.object.position;
		offset.copy(position).sub(this.target);
		offset.applyQuaternion(quat);
		this._spherical.setFromVector3(offset);

		if (this.autoRotate && state == STATE.NONE) {
			rotateLeft(getAutoRotationAngle(deltaTime));
		}

		if (this.enableDamping) {
			this._spherical.theta += this._sphericalDelta.theta * this.dampingFactor;
			this._spherical.phi += this._sphericalDelta.phi * this.dampingFactor;
		} else {
			this._spherical.theta += this._sphericalDelta.theta;
			this._spherical.phi += this._sphericalDelta.phi;
		}

		var min = this.minAzimuthAngle;
		var max = this.maxAzimuthAngle;
		if (isFinite(min) && isFinite(max)) {
			if (min < -Math.PI) min += twoPI; else if (min > Math.PI) min -= twoPI;
			if (max < -Math.PI) max += twoPI; else if (max > Math.PI) max -= twoPI;
			if (min <= max) {
				this._spherical.theta = Math.max(min, Math.min(max, this._spherical.theta));
			} else {
				this._spherical.theta = (this._spherical.theta > (min + max) / 2) ?
					Math.max(min, this._spherical.theta) :
					Math.min(max, this._spherical.theta);
			}
		}

		this._spherical.phi = Math.max(this.minPolarAngle, Math.min(this.maxPolarAngle, this._spherical.phi));
		this._spherical.makeSafe();

		if (this.enableDamping) {
			this.target.addScaledVector(this._panOffset, this.dampingFactor);
		} else {
			this.target.add(this._panOffset);
		}

		this.target.sub(this.cursor);
		this.target.clampLength(this.minTargetRadius, this.maxTargetRadius);
		this.target.add(this.cursor);

		var zoomChanged = false;
		if (this.zoomToCursor && this._performCursorZoom || this.object.isOrthographicCamera) {
			this._spherical.radius = clampDistance(this._spherical.radius);
		} else {
			var prevRadius = this._spherical.radius;
			this._spherical.radius = clampDistance(this._spherical.radius * this._scale);
			zoomChanged = prevRadius != this._spherical.radius;
		}

		offset.setFromSpherical(this._spherical);
		offset.applyQuaternion(quatInverse);
		position.copy(this.target).add(offset);
		this.object.lookAt(this.target);

		if (this.enableDamping) {
			this._sphericalDelta.theta *= (1 - this.dampingFactor);
			this._sphericalDelta.phi *= (1 - this.dampingFactor);
			this._panOffset.multiplyScalar(1 - this.dampingFactor);
		} else {
			this._sphericalDelta.set(0, 0, 0);
			this._panOffset.set(0, 0, 0);
		}

		if (this.zoomToCursor && this._performCursorZoom) {
			var newRadius:Float = null;
			if (this.object.isPerspectiveCamera) {
				var prevRadius = offset.length();
				newRadius = clampDistance(prevRadius * this._scale);
				var radiusDelta = prevRadius - newRadius;
				this.object.position.addScaledVector(this._dollyDirection, radiusDelta);
				this.object.updateMatrixWorld();
				zoomChanged = !!radiusDelta;
			} else if (this.object.isOrthographicCamera) {
				var mouseBefore = new Vector3(this._mouse.x, this._mouse.y, 0);
				mouseBefore.unproject(this.object);
				var prevZoom = this.object.zoom;
				this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this._scale));
				this.object.updateProjectionMatrix();
				zoomChanged = prevZoom != this.object.zoom;
				var mouseAfter = new Vector3(this._mouse.x, this._mouse.y, 0);
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
					this.target.set(0, 0, -1).transformDirection(this.object.matrix).multiplyScalar(newRadius).add(this.object.position);
				} else {
					this._ray.origin.copy(this.object.position);
					this._ray.direction.set(0, 0, -1).transformDirection(this.object.matrix);
					if (Math.abs(this.object.up.dot(this._ray.direction)) < TILT_LIMIT) {
						this.object.lookAt(this.target);
					} else {
						this._plane.setFromNormalAndCoplanarPoint(this.object.up, this.target);
						this._ray.intersectPlane(this._plane, this.target);
					}
				}
			}
		} else if (this.object.isOrthographicCamera) {
			var prevZoom = this.object.zoom;
			this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this._scale));
			if (prevZoom != this.object.zoom) {
				this.object.updateProjectionMatrix();
				zoomChanged = true;
			}
		}

		this._scale = 1;
		this._performCursorZoom = false;

		if (zoomChanged || lastPosition.distanceToSquared(this.object.position) > EPS || 8 * (1 - lastQuaternion.dot(this.object.quaternion)) > EPS || lastTargetPosition.distanceToSquared(this.target) > EPS) {
			this.dispatchEvent({type: 'change'});
			lastPosition.copy(this.object.position);
			lastQuaternion.copy(this.object.quaternion);
			lastTargetPosition.copy(this.target);
			return true;
		}

		return false;
	}

	public function dispose() {
		this.domElement.removeEventListener('contextmenu', this.onContextMenu);
		this.domElement.removeEventListener('pointerdown', this.onPointerDown);
		this.domElement.removeEventListener('pointercancel', this.onPointerUp);
		this.domElement.removeEventListener('wheel', this.onMouseWheel);
		this.domElement.removeEventListener('pointermove', this.onPointerMove);
		this.domElement.removeEventListener('pointerup', this.onPointerUp);
		var document = this.domElement.getRootNode(); // offscreen canvas compatibility
		document.removeEventListener('keydown', this.interceptControlDown, {capture: true});
		if (this._domElementKeyEvents != null) {
			this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
			this._domElementKeyEvents = null;
		}
	}

	private static inline var EPS:Float = 0.000001;

	private static inline var STATE = {
		NONE: -1,
		ROTATE: 0,
		DOLLY: 1,
		PAN: 2,
		TOUCH_ROTATE: 3,
		TOUCH_PAN: 4,
		TOUCH_DOLLY_PAN: 5,
		TOUCH_DOLLY_ROTATE: 6
	};

	private var state:Int = STATE.NONE;

	private function getAutoRotationAngle(deltaTime:Float):Float {
		if (deltaTime != null) {
			return (2 * Math.PI / 60 * this.autoRotateSpeed) * deltaTime;
		} else {
			return 2 * Math.PI / 60 / 60 * this.autoRotateSpeed;
		}
	}

	private function getZoomScale(delta:Float):Float {
		var normalizedDelta = Math.abs(delta * 0.01);
		return Math.pow(0.95, this.zoomSpeed * normalizedDelta);
	}

	private function rotateLeft(angle:Float) {
		this._sphericalDelta.theta -= angle;
	}

	private function rotateUp(angle:Float) {
		this._sphericalDelta.phi -= angle;
	}

	private function panLeft(distance:Float, objectMatrix:Matrix4) {
		var v = new Vector3();
		v.setFromMatrixColumn(objectMatrix, 0);
		v.multiplyScalar(-distance);
		this._panOffset.add(v);
	}

	private function panUp(distance:Float, objectMatrix:Matrix4) {
		var v = new Vector3();
		if (this.screenSpacePanning) {
			v.setFromMatrixColumn(objectMatrix, 1);
		} else {
			v.setFromMatrixColumn(objectMatrix, 0);
			v.crossVectors(this.object.up, v);
		}
		v.multiplyScalar(distance);
		this._panOffset.add(v);
	}

	private function pan(deltaX:Float, deltaY:Float) {
		var offset = new Vector3();
		var element = this.domElement;
		if (this.object.isPerspectiveCamera) {
			var position = this.object.position;
			offset.copy(position).sub(this.target);
			var targetDistance = offset.length();
			targetDistance *= Math.tan((this.object.fov / 2) * Math.PI / 180.0);
			panLeft(2 * deltaX * targetDistance / element.clientHeight, this.object.matrix);
			panUp(2 * deltaY * targetDistance / element.clientHeight, this.object.matrix);
		} else if (this.object.isOrthographicCamera) {
			panLeft(deltaX * (this.object.right - this.object.left) / this.object.zoom / element.clientWidth, this.object.matrix);
			panUp(deltaY * (this.object.top - this.object.bottom) / this.object.zoom / element.clientHeight, this.object.matrix);
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - pan disabled.');
			this.enablePan = false;
		}
	}

	private function dollyOut(dollyScale:Float) {
		if (this.object.isPerspectiveCamera || this.object.isOrthographicCamera) {
			this._scale /= dollyScale;
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
			this.enableZoom = false;
		}
	}

	private function dollyIn(dollyScale:Float) {
		if (this.object.isPerspectiveCamera || this.object.isOrthographicCamera) {
			this._scale *= dollyScale;
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
			this.enableZoom = false;
		}
	}

	private function updateZoomParameters(x:Float, y:Float) {
		if (!this.zoomToCursor) {
			return;
		}
		this._performCursorZoom = true;
		var rect = this.domElement.getBoundingClientRect();
		var dx = x - rect.left;
		var dy = y - rect.top;
		var w = rect.width;
		var h = rect.height;
		this._mouse.x = (dx / w) * 2 - 1;
		this._mouse.y = -(dy / h) * 2 + 1;
		this._dollyDirection.set(this._mouse.x, this._mouse.y, 1).unproject(this.object).sub(this.object.position).normalize();
	}

	private function clampDistance(dist:Float):Float {
		return Math.max(this.minDistance, Math.min(this.maxDistance, dist));
	}

	// event callbacks - update the object state

	private function handleMouseDownRotate(event:Dynamic) {
		this._rotateStart.set(event.clientX, event.clientY);
	}

	private function handleMouseDownDolly(event:Dynamic) {
		updateZoomParameters(event.clientX, event.clientX);
		this._dollyStart.set(event.clientX, event.clientY);
	}

	private function handleMouseDownPan(event:Dynamic) {
		this._panStart.set(event.clientX, event.clientY);
	}

	private function handleMouseMoveRotate(event:Dynamic) {
		this._rotateEnd.set(event.clientX, event.clientY);
		this._rotateDelta.subVectors(this._rotateEnd, this._rotateStart).multiplyScalar(this.rotateSpeed);
		var element = this.domElement;
		rotateLeft(2 * Math.PI * this._rotateDelta.x / element.clientHeight);
		rotateUp(2 * Math.PI * this._rotateDelta.y / element.clientHeight);
		this._rotateStart.copy(this._rotateEnd);
		this.update();
	}

	private function handleMouseMoveDolly(event:Dynamic) {
		this._dollyEnd.set(event.clientX, event.clientY);
		this._dollyDelta.subVectors(this._dollyEnd, this._dollyStart);
		if (this._dollyDelta.y > 0) {
			dollyOut(getZoomScale(this._dollyDelta.y));
		} else if (this._dollyDelta.y < 0) {
			dollyIn(getZoomScale(this._dollyDelta.y));
		}
		this._dollyStart.copy(this._dollyEnd);
		this.update();
	}

	private function handleMouseMovePan(event:Dynamic) {
		this._panEnd.set(event.clientX, event.clientY);
		this._panDelta.subVectors(this._panEnd, this._panStart).multiplyScalar(this.panSpeed);
		pan(this._panDelta.x, this._panDelta.y);
		this._panStart.copy(this._panEnd);
		this.update();
	}

	private function handleMouseWheel(event:Dynamic) {
		if (this.enabled == false || this.enableZoom == false || state != STATE.NONE) return;
		event.preventDefault();
		this.dispatchEvent({type: 'start'});
		handleMouseWheel(customWheelEvent(event));
		this.dispatchEvent({type: 'end'});
	}

	private function handleKeyDown(event:Dynamic) {
		var needsUpdate = false;
		switch (event.code) {
			case this.keys.UP:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateUp(2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(0, this.keyPanSpeed);
				}
				needsUpdate = true;
				break;
			case this.keys.BOTTOM:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateUp(-2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(0, -this.keyPanSpeed);
				}
				needsUpdate = true;
				break;
			case this.keys.LEFT:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateLeft(2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(this.keyPanSpeed, 0);
				}
				needsUpdate = true;
				break;
			case this.keys.RIGHT:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateLeft(-2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(-this.keyPanSpeed, 0);
				}
				needsUpdate = true;
				break;
		}
		if (needsUpdate) {
			event.preventDefault();
			this.update();
		}
	}

	private function handleTouchStartRotate(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._rotateStart.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._rotateStart.set(x, y);
		}
	}

	private function handleTouchStartPan(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._panStart.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._panStart.set(x, y);
		}
	}

	private function handleTouchStartDolly(event:Dynamic) {
		var position = getSecondPointerPosition(event);
		var dx = event.pageX - position.x;
		var dy = event.pageY - position.y;
		var distance = Math.sqrt(dx * dx + dy * dy);
		this._dollyStart.set(0, distance);
	}

	private function handleTouchStartDollyPan(event:Dynamic) {
		if (this.enableZoom) handleTouchStartDolly(event);
		if (this.enablePan) handleTouchStartPan(event);
	}

	private function handleTouchStartDollyRotate(event:Dynamic) {
		if (this.enableZoom) handleTouchStartDolly(event);
		if (this.enableRotate) handleTouchStartRotate(event);
	}

	private function handleTouchMoveRotate(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._rotateEnd.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._rotateEnd.set(x, y);
		}
		this._rotateDelta.subVectors(this._rotateEnd, this._rotateStart).multiplyScalar(this.rotateSpeed);
		var element = this.domElement;
		rotateLeft(2 * Math.PI * this._rotateDelta.x / element.clientHeight);
		rotateUp(2 * Math.PI * this._rotateDelta.y / element.clientHeight);
		this._rotateStart.copy(this._rotateEnd);
	}

	private function handleTouchMovePan(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._panEnd.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._panEnd.set(x, y);
		}
		this._panDelta.subVectors(this._panEnd, this._panStart).multiplyScalar(this.panSpeed);
		pan(this._panDelta.x, this._panDelta.y);
		this._panStart.copy(this._panEnd);
	}

	private function handleTouchMoveDolly(event:Dynamic) {
		var position = getSecondPointerPosition(event);
		var dx = event.pageX - position.x;
		var dy = event.pageY - position.y;
		var distance = Math.sqrt(dx * dx + dy * dy);
		this._dollyEnd.set(0, distance);
		this._dollyDelta.set(0, Math.pow(this._dollyEnd.y / this._dollyStart.y, this.zoomSpeed));
		dollyOut(this._dollyDelta.y);
		this._dollyStart.copy(this._dollyEnd);
		var centerX = (event.pageX + position.x) * 0.5;
		var centerY = (event.pageY + position.y) * 0.5;
		updateZoomParameters(centerX, centerY);
	}

	private function handleTouchMoveDollyPan(event:Dynamic) {
		if (this.enableZoom) handleTouchMoveDolly(event);
		if (this.enablePan) handleTouchMovePan(event);
	}

	private function handleTouchMoveDollyRotate(event:Dynamic) {
		if (this.enableZoom) handleTouchMoveDolly(event);
		if (this.enableRotate) handleTouchMoveRotate(event);
	}

	// event handlers - FSM: listen for events and reset state

	private function onPointerDown(event:Dynamic) {
		if (this.enabled == false) return;
		if (this._pointers.length == 0) {
			this.domElement.setPointerCapture(event.pointerId);
			this.domElement.addEventListener('pointermove', this.onPointerMove);
			this.domElement.addEventListener('pointerup', this.onPointerUp);
		}
		if (isTrackingPointer(event)) return;
		addPointer(event);
		if (event.pointerType == 'touch') {
			onTouchStart(event);
		} else {
			onMouseDown(event);
		}
	}

	private function onPointerMove(event:Dynamic) {
		if (this.enabled == false) return;
		if (event.pointerType == 'touch') {
			onTouchMove(event);
		} else {
			onMouseMove(event);
		}
	}

	private function onPointerUp(event:Dynamic) {
		removePointer(event);
		switch (this._pointers.length) {
			case 0:
				this.domElement.releasePointerCapture(event.pointerId);
				this.domElement.removeEventListener('pointermove', this.onPointerMove);
				this.domElement.removeEventListener('pointerup', this.onPointerUp);
				this.dispatchEvent({type: 'end'});
				state = STATE.NONE;
				break;
			case 1:
				var pointerId = this._pointers[0];
				var position = this._pointerPositions[pointerId];
				onTouchStart({pointerId: pointerId, pageX: position.x, pageY: position.y});
				break;
		}
	}

	private function onMouseDown(event:Dynamic) {
		var mouseAction:Int;
		switch (event.button) {
			case 0:
				mouseAction = this.mouseButtons.LEFT;
				break;
			case 1:
				mouseAction = this.mouseButtons.MIDDLE;
				break;
			case 2:
				mouseAction = this.mouseButtons.RIGHT;
				break;
			default:
				mouseAction = -1;
		}
		switch (mouseAction) {
			case 0:
				if (this.enableZoom == false) return;
				handleMouseDownDolly(event);
				state = STATE.DOLLY;
				break;
			case 1:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (this.enablePan == false) return;
					handleMouseDownPan(event);
					state = STATE.PAN;
				} else {
					if (this.enableRotate == false) return;
					handleMouseDownRotate(event);
					state = STATE.ROTATE;
				}
				break;
			case 2:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (this.enableRotate == false) return;
					handleMouseDownRotate(event);
					state = STATE.ROTATE;
				} else {
					if (this.enablePan == false) return;
					handleMouseDownPan(event);
					state = STATE.PAN;
				}
				break;
			default:
				state = STATE.NONE;
		}
		if (state != STATE.NONE) {
			this.dispatchEvent({type: 'start'});
		}
	}

	private function onMouseMove(event:Dynamic) {
		switch (state) {
			case STATE.ROTATE:
				if (this.enableRotate == false) return;
				handleMouseMoveRotate(event);
				break;
			case STATE.DOLLY:
				if (this.enableZoom == false) return;
				handleMouseMoveDolly(event);
				break;
			case STATE.PAN:
				if (this.enablePan == false) return;
				handleMouseMovePan(event);
				break;
		}
	}

	private function onMouseWheel(event:Dynamic) {
		if (this.enabled == false || this.enableZoom == false || state != STATE.NONE) return;
		event.preventDefault();
		this.dispatchEvent({type: 'start'});
		handleMouseWheel(customWheelEvent(event));
		this.dispatchEvent({type: 'end
import three.core.EventDispatcher;
import three.math.Quaternion;
import three.math.Spherical;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Plane;
import three.math.Ray;
import three.math.MathUtils;
import three.cameras.Camera;
import three.cameras.PerspectiveCamera;
import three.cameras.OrthographicCamera;

// OrbitControls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
//
//    Orbit - left mouse / touch: one-finger move
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - right mouse, or left mouse + ctrl/meta/shiftKey, or arrow keys / touch: two-finger move

class OrbitControls extends EventDispatcher {

	public var object:Camera;
	public var domElement:Dynamic;

	// Set to false to disable this control
	public var enabled:Bool = true;

	// "target" sets the location of focus, where the object orbits around
	public var target:Vector3 = new Vector3();

	// Sets the 3D cursor (similar to Blender), from which the maxTargetRadius takes effect
	public var cursor:Vector3 = new Vector3();

	// How far you can dolly in and out ( PerspectiveCamera only )
	public var minDistance:Float = 0;
	public var maxDistance:Float = Math.POSITIVE_INFINITY;

	// How far you can zoom in and out ( OrthographicCamera only )
	public var minZoom:Float = 0;
	public var maxZoom:Float = Math.POSITIVE_INFINITY;

	// Limit camera target within a spherical area around the cursor
	public var minTargetRadius:Float = 0;
	public var maxTargetRadius:Float = Math.POSITIVE_INFINITY;

	// How far you can orbit vertically, upper and lower limits.
	// Range is 0 to Math.PI radians.
	public var minPolarAngle:Float = 0; // radians
	public var maxPolarAngle:Float = Math.PI; // radians

	// How far you can orbit horizontally, upper and lower limits.
	// If set, the interval [ min, max ] must be a sub-interval of [ - 2 PI, 2 PI ], with ( max - min < 2 PI )
	public var minAzimuthAngle:Float = -Math.POSITIVE_INFINITY; // radians
	public var maxAzimuthAngle:Float = Math.POSITIVE_INFINITY; // radians

	// Set to true to enable damping (inertia)
	// If damping is enabled, you must call controls.update() in your animation loop
	public var enableDamping:Bool = false;
	public var dampingFactor:Float = 0.05;

	// This option actually enables dollying in and out; left as "zoom" for backwards compatibility.
	// Set to false to disable zooming
	public var enableZoom:Bool = true;
	public var zoomSpeed:Float = 1.0;

	// Set to false to disable rotating
	public var enableRotate:Bool = true;
	public var rotateSpeed:Float = 1.0;

	// Set to false to disable panning
	public var enablePan:Bool = true;
	public var panSpeed:Float = 1.0;
	public var screenSpacePanning:Bool = true; // if false, pan orthogonal to world-space direction camera.up
	public var keyPanSpeed:Float = 7.0;	// pixels moved per arrow key push
	public var zoomToCursor:Bool = false;

	// Set to true to automatically rotate around the target
	// If auto-rotate is enabled, you must call controls.update() in your animation loop
	public var autoRotate:Bool = false;
	public var autoRotateSpeed:Float = 2.0; // 30 seconds per orbit when fps is 60

	// The four arrow keys
	public var keys:{ LEFT:String, UP:String, RIGHT:String, BOTTOM:String } = { LEFT: 'ArrowLeft', UP: 'ArrowUp', RIGHT: 'ArrowRight', BOTTOM: 'ArrowDown' };

	// Mouse buttons
	public var mouseButtons:{ LEFT:Int, MIDDLE:Int, RIGHT:Int } = { LEFT: 0, MIDDLE: 1, RIGHT: 2 };

	// Touch fingers
	public var touches:{ ONE:Int, TWO:Int } = { ONE: 0, TWO: 1 };

	// for reset
	public var target0:Vector3 = new Vector3();
	public var position0:Vector3 = new Vector3();
	public var zoom0:Float = 0;

	// the target DOM element for key events
	private var _domElementKeyEvents:Dynamic = null;

	private var _ray:Ray = new Ray();
	private var _plane:Plane = new Plane();
	private static inline var TILT_LIMIT:Float = Math.cos( 70 * MathUtils.DEG2RAD );
	private var _spherical:Spherical = new Spherical();
	private var _sphericalDelta:Spherical = new Spherical();
	private var _scale:Float = 1;
	private var _panOffset:Vector3 = new Vector3();
	private var _rotateStart:Vector2 = new Vector2();
	private var _rotateEnd:Vector2 = new Vector2();
	private var _rotateDelta:Vector2 = new Vector2();
	private var _panStart:Vector2 = new Vector2();
	private var _panEnd:Vector2 = new Vector2();
	private var _panDelta:Vector2 = new Vector2();
	private var _dollyStart:Vector2 = new Vector2();
	private var _dollyEnd:Vector2 = new Vector2();
	private var _dollyDelta:Vector2 = new Vector2();
	private var _dollyDirection:Vector3 = new Vector3();
	private var _mouse:Vector2 = new Vector2();
	private var _performCursorZoom:Bool = false;
	private var _pointers:Array<Int> = [];
	private var _pointerPositions:Map<Int, Vector2> = new Map();
	private var _controlActive:Bool = false;

	public function new(object:Camera, domElement:Dynamic) {
		super();

		this.object = object;
		this.domElement = domElement;
		this.domElement.style.touchAction = 'none'; // disable touch scroll

		this.target0.copy(this.target);
		this.position0.copy(this.object.position);
		this.zoom0 = this.object.zoom;

		domElement.addEventListener('contextmenu', this.onContextMenu);
		domElement.addEventListener('pointerdown', this.onPointerDown);
		domElement.addEventListener('pointercancel', this.onPointerUp);
		domElement.addEventListener('wheel', this.onMouseWheel, {passive: false});
		domElement.addEventListener('pointermove', this.onPointerMove);
		domElement.addEventListener('pointerup', this.onPointerUp);

		var document = this.domElement.getRootNode(); // offscreen canvas compatibility
		document.addEventListener('keydown', this.interceptControlDown, {capture: true});

		this.update();
	}

	public function getPolarAngle():Float {
		return this._spherical.phi;
	}

	public function getAzimuthalAngle():Float {
		return this._spherical.theta;
	}

	public function getDistance():Float {
		return this.object.position.distanceTo(this.target);
	}

	public function listenToKeyEvents(domElement:Dynamic) {
		domElement.addEventListener('keydown', this.onKeyDown);
		this._domElementKeyEvents = domElement;
	}

	public function stopListenToKeyEvents() {
		if (this._domElementKeyEvents != null) {
			this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
			this._domElementKeyEvents = null;
		}
	}

	public function saveState() {
		this.target0.copy(this.target);
		this.position0.copy(this.object.position);
		this.zoom0 = this.object.zoom;
	}

	public function reset() {
		this.target.copy(this.target0);
		this.object.position.copy(this.position0);
		this.object.zoom = this.zoom0;
		this.object.updateProjectionMatrix();
		this.dispatchEvent({type: 'change'});
		this.update();
	}

	public function update(deltaTime:Float = null) {
		var offset = new Vector3();
		var quat = new Quaternion().setFromUnitVectors(this.object.up, new Vector3(0, 1, 0));
		var quatInverse = quat.clone().invert();
		var lastPosition = new Vector3();
		var lastQuaternion = new Quaternion();
		var lastTargetPosition = new Vector3();
		var twoPI = 2 * Math.PI;

		var position = this.object.position;
		offset.copy(position).sub(this.target);
		offset.applyQuaternion(quat);
		this._spherical.setFromVector3(offset);

		if (this.autoRotate && state == STATE.NONE) {
			rotateLeft(getAutoRotationAngle(deltaTime));
		}

		if (this.enableDamping) {
			this._spherical.theta += this._sphericalDelta.theta * this.dampingFactor;
			this._spherical.phi += this._sphericalDelta.phi * this.dampingFactor;
		} else {
			this._spherical.theta += this._sphericalDelta.theta;
			this._spherical.phi += this._sphericalDelta.phi;
		}

		var min = this.minAzimuthAngle;
		var max = this.maxAzimuthAngle;
		if (isFinite(min) && isFinite(max)) {
			if (min < -Math.PI) min += twoPI; else if (min > Math.PI) min -= twoPI;
			if (max < -Math.PI) max += twoPI; else if (max > Math.PI) max -= twoPI;
			if (min <= max) {
				this._spherical.theta = Math.max(min, Math.min(max, this._spherical.theta));
			} else {
				this._spherical.theta = (this._spherical.theta > (min + max) / 2) ?
					Math.max(min, this._spherical.theta) :
					Math.min(max, this._spherical.theta);
			}
		}

		this._spherical.phi = Math.max(this.minPolarAngle, Math.min(this.maxPolarAngle, this._spherical.phi));
		this._spherical.makeSafe();

		if (this.enableDamping) {
			this.target.addScaledVector(this._panOffset, this.dampingFactor);
		} else {
			this.target.add(this._panOffset);
		}

		this.target.sub(this.cursor);
		this.target.clampLength(this.minTargetRadius, this.maxTargetRadius);
		this.target.add(this.cursor);

		var zoomChanged = false;
		if (this.zoomToCursor && this._performCursorZoom || this.object.isOrthographicCamera) {
			this._spherical.radius = clampDistance(this._spherical.radius);
		} else {
			var prevRadius = this._spherical.radius;
			this._spherical.radius = clampDistance(this._spherical.radius * this._scale);
			zoomChanged = prevRadius != this._spherical.radius;
		}

		offset.setFromSpherical(this._spherical);
		offset.applyQuaternion(quatInverse);
		position.copy(this.target).add(offset);
		this.object.lookAt(this.target);

		if (this.enableDamping) {
			this._sphericalDelta.theta *= (1 - this.dampingFactor);
			this._sphericalDelta.phi *= (1 - this.dampingFactor);
			this._panOffset.multiplyScalar(1 - this.dampingFactor);
		} else {
			this._sphericalDelta.set(0, 0, 0);
			this._panOffset.set(0, 0, 0);
		}

		if (this.zoomToCursor && this._performCursorZoom) {
			var newRadius:Float = null;
			if (this.object.isPerspectiveCamera) {
				var prevRadius = offset.length();
				newRadius = clampDistance(prevRadius * this._scale);
				var radiusDelta = prevRadius - newRadius;
				this.object.position.addScaledVector(this._dollyDirection, radiusDelta);
				this.object.updateMatrixWorld();
				zoomChanged = !!radiusDelta;
			} else if (this.object.isOrthographicCamera) {
				var mouseBefore = new Vector3(this._mouse.x, this._mouse.y, 0);
				mouseBefore.unproject(this.object);
				var prevZoom = this.object.zoom;
				this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this._scale));
				this.object.updateProjectionMatrix();
				zoomChanged = prevZoom != this.object.zoom;
				var mouseAfter = new Vector3(this._mouse.x, this._mouse.y, 0);
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
					this.target.set(0, 0, -1).transformDirection(this.object.matrix).multiplyScalar(newRadius).add(this.object.position);
				} else {
					this._ray.origin.copy(this.object.position);
					this._ray.direction.set(0, 0, -1).transformDirection(this.object.matrix);
					if (Math.abs(this.object.up.dot(this._ray.direction)) < TILT_LIMIT) {
						this.object.lookAt(this.target);
					} else {
						this._plane.setFromNormalAndCoplanarPoint(this.object.up, this.target);
						this._ray.intersectPlane(this._plane, this.target);
					}
				}
			}
		} else if (this.object.isOrthographicCamera) {
			var prevZoom = this.object.zoom;
			this.object.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.object.zoom / this._scale));
			if (prevZoom != this.object.zoom) {
				this.object.updateProjectionMatrix();
				zoomChanged = true;
			}
		}

		this._scale = 1;
		this._performCursorZoom = false;

		if (zoomChanged || lastPosition.distanceToSquared(this.object.position) > EPS || 8 * (1 - lastQuaternion.dot(this.object.quaternion)) > EPS || lastTargetPosition.distanceToSquared(this.target) > EPS) {
			this.dispatchEvent({type: 'change'});
			lastPosition.copy(this.object.position);
			lastQuaternion.copy(this.object.quaternion);
			lastTargetPosition.copy(this.target);
			return true;
		}

		return false;
	}

	public function dispose() {
		this.domElement.removeEventListener('contextmenu', this.onContextMenu);
		this.domElement.removeEventListener('pointerdown', this.onPointerDown);
		this.domElement.removeEventListener('pointercancel', this.onPointerUp);
		this.domElement.removeEventListener('wheel', this.onMouseWheel);
		this.domElement.removeEventListener('pointermove', this.onPointerMove);
		this.domElement.removeEventListener('pointerup', this.onPointerUp);
		var document = this.domElement.getRootNode(); // offscreen canvas compatibility
		document.removeEventListener('keydown', this.interceptControlDown, {capture: true});
		if (this._domElementKeyEvents != null) {
			this._domElementKeyEvents.removeEventListener('keydown', this.onKeyDown);
			this._domElementKeyEvents = null;
		}
	}

	private static inline var EPS:Float = 0.000001;

	private static inline var STATE = {
		NONE: -1,
		ROTATE: 0,
		DOLLY: 1,
		PAN: 2,
		TOUCH_ROTATE: 3,
		TOUCH_PAN: 4,
		TOUCH_DOLLY_PAN: 5,
		TOUCH_DOLLY_ROTATE: 6
	};

	private var state:Int = STATE.NONE;

	private function getAutoRotationAngle(deltaTime:Float):Float {
		if (deltaTime != null) {
			return (2 * Math.PI / 60 * this.autoRotateSpeed) * deltaTime;
		} else {
			return 2 * Math.PI / 60 / 60 * this.autoRotateSpeed;
		}
	}

	private function getZoomScale(delta:Float):Float {
		var normalizedDelta = Math.abs(delta * 0.01);
		return Math.pow(0.95, this.zoomSpeed * normalizedDelta);
	}

	private function rotateLeft(angle:Float) {
		this._sphericalDelta.theta -= angle;
	}

	private function rotateUp(angle:Float) {
		this._sphericalDelta.phi -= angle;
	}

	private function panLeft(distance:Float, objectMatrix:Matrix4) {
		var v = new Vector3();
		v.setFromMatrixColumn(objectMatrix, 0);
		v.multiplyScalar(-distance);
		this._panOffset.add(v);
	}

	private function panUp(distance:Float, objectMatrix:Matrix4) {
		var v = new Vector3();
		if (this.screenSpacePanning) {
			v.setFromMatrixColumn(objectMatrix, 1);
		} else {
			v.setFromMatrixColumn(objectMatrix, 0);
			v.crossVectors(this.object.up, v);
		}
		v.multiplyScalar(distance);
		this._panOffset.add(v);
	}

	private function pan(deltaX:Float, deltaY:Float) {
		var offset = new Vector3();
		var element = this.domElement;
		if (this.object.isPerspectiveCamera) {
			var position = this.object.position;
			offset.copy(position).sub(this.target);
			var targetDistance = offset.length();
			targetDistance *= Math.tan((this.object.fov / 2) * Math.PI / 180.0);
			panLeft(2 * deltaX * targetDistance / element.clientHeight, this.object.matrix);
			panUp(2 * deltaY * targetDistance / element.clientHeight, this.object.matrix);
		} else if (this.object.isOrthographicCamera) {
			panLeft(deltaX * (this.object.right - this.object.left) / this.object.zoom / element.clientWidth, this.object.matrix);
			panUp(deltaY * (this.object.top - this.object.bottom) / this.object.zoom / element.clientHeight, this.object.matrix);
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - pan disabled.');
			this.enablePan = false;
		}
	}

	private function dollyOut(dollyScale:Float) {
		if (this.object.isPerspectiveCamera || this.object.isOrthographicCamera) {
			this._scale /= dollyScale;
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
			this.enableZoom = false;
		}
	}

	private function dollyIn(dollyScale:Float) {
		if (this.object.isPerspectiveCamera || this.object.isOrthographicCamera) {
			this._scale *= dollyScale;
		} else {
			trace('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
			this.enableZoom = false;
		}
	}

	private function updateZoomParameters(x:Float, y:Float) {
		if (!this.zoomToCursor) {
			return;
		}
		this._performCursorZoom = true;
		var rect = this.domElement.getBoundingClientRect();
		var dx = x - rect.left;
		var dy = y - rect.top;
		var w = rect.width;
		var h = rect.height;
		this._mouse.x = (dx / w) * 2 - 1;
		this._mouse.y = -(dy / h) * 2 + 1;
		this._dollyDirection.set(this._mouse.x, this._mouse.y, 1).unproject(this.object).sub(this.object.position).normalize();
	}

	private function clampDistance(dist:Float):Float {
		return Math.max(this.minDistance, Math.min(this.maxDistance, dist));
	}

	// event callbacks - update the object state

	private function handleMouseDownRotate(event:Dynamic) {
		this._rotateStart.set(event.clientX, event.clientY);
	}

	private function handleMouseDownDolly(event:Dynamic) {
		updateZoomParameters(event.clientX, event.clientX);
		this._dollyStart.set(event.clientX, event.clientY);
	}

	private function handleMouseDownPan(event:Dynamic) {
		this._panStart.set(event.clientX, event.clientY);
	}

	private function handleMouseMoveRotate(event:Dynamic) {
		this._rotateEnd.set(event.clientX, event.clientY);
		this._rotateDelta.subVectors(this._rotateEnd, this._rotateStart).multiplyScalar(this.rotateSpeed);
		var element = this.domElement;
		rotateLeft(2 * Math.PI * this._rotateDelta.x / element.clientHeight);
		rotateUp(2 * Math.PI * this._rotateDelta.y / element.clientHeight);
		this._rotateStart.copy(this._rotateEnd);
		this.update();
	}

	private function handleMouseMoveDolly(event:Dynamic) {
		this._dollyEnd.set(event.clientX, event.clientY);
		this._dollyDelta.subVectors(this._dollyEnd, this._dollyStart);
		if (this._dollyDelta.y > 0) {
			dollyOut(getZoomScale(this._dollyDelta.y));
		} else if (this._dollyDelta.y < 0) {
			dollyIn(getZoomScale(this._dollyDelta.y));
		}
		this._dollyStart.copy(this._dollyEnd);
		this.update();
	}

	private function handleMouseMovePan(event:Dynamic) {
		this._panEnd.set(event.clientX, event.clientY);
		this._panDelta.subVectors(this._panEnd, this._panStart).multiplyScalar(this.panSpeed);
		pan(this._panDelta.x, this._panDelta.y);
		this._panStart.copy(this._panEnd);
		this.update();
	}

	private function handleMouseWheel(event:Dynamic) {
		if (this.enabled == false || this.enableZoom == false || state != STATE.NONE) return;
		event.preventDefault();
		this.dispatchEvent({type: 'start'});
		handleMouseWheel(customWheelEvent(event));
		this.dispatchEvent({type: 'end'});
	}

	private function handleKeyDown(event:Dynamic) {
		var needsUpdate = false;
		switch (event.code) {
			case this.keys.UP:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateUp(2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(0, this.keyPanSpeed);
				}
				needsUpdate = true;
				break;
			case this.keys.BOTTOM:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateUp(-2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(0, -this.keyPanSpeed);
				}
				needsUpdate = true;
				break;
			case this.keys.LEFT:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateLeft(2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(this.keyPanSpeed, 0);
				}
				needsUpdate = true;
				break;
			case this.keys.RIGHT:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					rotateLeft(-2 * Math.PI * this.rotateSpeed / this.domElement.clientHeight);
				} else {
					pan(-this.keyPanSpeed, 0);
				}
				needsUpdate = true;
				break;
		}
		if (needsUpdate) {
			event.preventDefault();
			this.update();
		}
	}

	private function handleTouchStartRotate(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._rotateStart.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._rotateStart.set(x, y);
		}
	}

	private function handleTouchStartPan(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._panStart.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._panStart.set(x, y);
		}
	}

	private function handleTouchStartDolly(event:Dynamic) {
		var position = getSecondPointerPosition(event);
		var dx = event.pageX - position.x;
		var dy = event.pageY - position.y;
		var distance = Math.sqrt(dx * dx + dy * dy);
		this._dollyStart.set(0, distance);
	}

	private function handleTouchStartDollyPan(event:Dynamic) {
		if (this.enableZoom) handleTouchStartDolly(event);
		if (this.enablePan) handleTouchStartPan(event);
	}

	private function handleTouchStartDollyRotate(event:Dynamic) {
		if (this.enableZoom) handleTouchStartDolly(event);
		if (this.enableRotate) handleTouchStartRotate(event);
	}

	private function handleTouchMoveRotate(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._rotateEnd.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._rotateEnd.set(x, y);
		}
		this._rotateDelta.subVectors(this._rotateEnd, this._rotateStart).multiplyScalar(this.rotateSpeed);
		var element = this.domElement;
		rotateLeft(2 * Math.PI * this._rotateDelta.x / element.clientHeight);
		rotateUp(2 * Math.PI * this._rotateDelta.y / element.clientHeight);
		this._rotateStart.copy(this._rotateEnd);
	}

	private function handleTouchMovePan(event:Dynamic) {
		if (this._pointers.length == 1) {
			this._panEnd.set(event.pageX, event.pageY);
		} else {
			var position = getSecondPointerPosition(event);
			var x = 0.5 * (event.pageX + position.x);
			var y = 0.5 * (event.pageY + position.y);
			this._panEnd.set(x, y);
		}
		this._panDelta.subVectors(this._panEnd, this._panStart).multiplyScalar(this.panSpeed);
		pan(this._panDelta.x, this._panDelta.y);
		this._panStart.copy(this._panEnd);
	}

	private function handleTouchMoveDolly(event:Dynamic) {
		var position = getSecondPointerPosition(event);
		var dx = event.pageX - position.x;
		var dy = event.pageY - position.y;
		var distance = Math.sqrt(dx * dx + dy * dy);
		this._dollyEnd.set(0, distance);
		this._dollyDelta.set(0, Math.pow(this._dollyEnd.y / this._dollyStart.y, this.zoomSpeed));
		dollyOut(this._dollyDelta.y);
		this._dollyStart.copy(this._dollyEnd);
		var centerX = (event.pageX + position.x) * 0.5;
		var centerY = (event.pageY + position.y) * 0.5;
		updateZoomParameters(centerX, centerY);
	}

	private function handleTouchMoveDollyPan(event:Dynamic) {
		if (this.enableZoom) handleTouchMoveDolly(event);
		if (this.enablePan) handleTouchMovePan(event);
	}

	private function handleTouchMoveDollyRotate(event:Dynamic) {
		if (this.enableZoom) handleTouchMoveDolly(event);
		if (this.enableRotate) handleTouchMoveRotate(event);
	}

	// event handlers - FSM: listen for events and reset state

	private function onPointerDown(event:Dynamic) {
		if (this.enabled == false) return;
		if (this._pointers.length == 0) {
			this.domElement.setPointerCapture(event.pointerId);
			this.domElement.addEventListener('pointermove', this.onPointerMove);
			this.domElement.addEventListener('pointerup', this.onPointerUp);
		}
		if (isTrackingPointer(event)) return;
		addPointer(event);
		if (event.pointerType == 'touch') {
			onTouchStart(event);
		} else {
			onMouseDown(event);
		}
	}

	private function onPointerMove(event:Dynamic) {
		if (this.enabled == false) return;
		if (event.pointerType == 'touch') {
			onTouchMove(event);
		} else {
			onMouseMove(event);
		}
	}

	private function onPointerUp(event:Dynamic) {
		removePointer(event);
		switch (this._pointers.length) {
			case 0:
				this.domElement.releasePointerCapture(event.pointerId);
				this.domElement.removeEventListener('pointermove', this.onPointerMove);
				this.domElement.removeEventListener('pointerup', this.onPointerUp);
				this.dispatchEvent({type: 'end'});
				state = STATE.NONE;
				break;
			case 1:
				var pointerId = this._pointers[0];
				var position = this._pointerPositions[pointerId];
				onTouchStart({pointerId: pointerId, pageX: position.x, pageY: position.y});
				break;
		}
	}

	private function onMouseDown(event:Dynamic) {
		var mouseAction:Int;
		switch (event.button) {
			case 0:
				mouseAction = this.mouseButtons.LEFT;
				break;
			case 1:
				mouseAction = this.mouseButtons.MIDDLE;
				break;
			case 2:
				mouseAction = this.mouseButtons.RIGHT;
				break;
			default:
				mouseAction = -1;
		}
		switch (mouseAction) {
			case 0:
				if (this.enableZoom == false) return;
				handleMouseDownDolly(event);
				state = STATE.DOLLY;
				break;
			case 1:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (this.enablePan == false) return;
					handleMouseDownPan(event);
					state = STATE.PAN;
				} else {
					if (this.enableRotate == false) return;
					handleMouseDownRotate(event);
					state = STATE.ROTATE;
				}
				break;
			case 2:
				if (event.ctrlKey || event.metaKey || event.shiftKey) {
					if (this.enableRotate == false) return;
					handleMouseDownRotate(event);
					state = STATE.ROTATE;
				} else {
					if (this.enablePan == false) return;
					handleMouseDownPan(event);
					state = STATE.PAN;
				}
				break;
			default:
				state = STATE.NONE;
		}
		if (state != STATE.NONE) {
			this.dispatchEvent({type: 'start'});
		}
	}

	private function onMouseMove(event:Dynamic) {
		switch (state) {
			case STATE.ROTATE:
				if (this.enableRotate == false) return;
				handleMouseMoveRotate(event);
				break;
			case STATE.DOLLY:
				if (this.enableZoom == false) return;
				handleMouseMoveDolly(event);
				break;
			case STATE.PAN:
				if (this.enablePan == false) return;
				handleMouseMovePan(event);
				break;
		}
	}

	private function onMouseWheel(event:Dynamic) {
		if (this.enabled == false || this.enableZoom == false || state != STATE.NONE) return;
		event.preventDefault();
		this.dispatchEvent({type: 'start'});
		handleMouseWheel(customWheelEvent(event));
		this.dispatchEvent({type: 'end