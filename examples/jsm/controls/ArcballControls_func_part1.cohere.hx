import js.three.Box3;
import js.three.Camera;
import js.three.EllipseCurve;
import js.three.EventDispatcher;
import js.three.Group;
import js.three.Line;
import js.three.LineBasicMaterial;
import js.three.Matrix4;
import js.three.Quaternion;
import js.three.Raycaster;
import js.three.Scene;
import js.three.Sphere;
import js.three.Vector2;
import js.three.Vector3;

enum STATE {
	IDLE,
	ROTATE,
	PAN,
	SCALE,
	FOV,
	FOCUS,
	ZROTATE,
	TOUCH_MULTI,
	ANIMATION_FOCUS,
	ANIMATION_ROTATE,
}

enum INPUT {
	NONE,
	ONE_FINGER,
	ONE_FINGER_SWITCHED,
	TWO_FINGER,
	MULT_FINGER,
	CURSOR,
}

class ArcballControls extends EventDispatcher {
	private static var _center:Vector2;
	private static var _transformation:Array<Matrix4>;
	private static var _changeEvent:Dynamic;
	private static var _startEvent:Dynamic;
	private static var _endEvent:Dynamic;
	private static var _raycaster:Raycaster;
	private static var _offset:Vector3;
	private static var _gizmoMatrixStateTemp:Matrix4;
	private static var _cameraMatrixStateTemp:Matrix4;
	private static var _scalePointTemp:Vector3;

	public var camera:Camera;
	public var domElement:HtmlElement;
	public var scene:Scene;
	public var target:Vector3;
	private var _currentTarget:Vector3;
	public var radiusFactor:Float;
	public var mouseActions:Array<Dynamic>;
	private var _mouseOp:Dynamic;
	private var _v2_1:Vector2;
	private var _v3_1:Vector3;
	private var _v3_2:Vector3;
	private var _m4_1:Matrix4;
	private var _m4_2:Matrix4;
	private var _quat:Quaternion;
	private var _translationMatrix:Matrix4;
	private var _rotationMatrix:Matrix4;
	private var _scaleMatrix:Matrix4;
	private var _rotationAxis:Vector3;
	private var _cameraMatrixState:Matrix4;
	private var _cameraProjectionState:Matrix4;
	private var _fovState:Int;
	private var _upState:Vector3;
	private var _zoomState:Int;
	private var _nearPos:Int;
	private var _farPos:Int;
	private var _gizmoMatrixState:Matrix4;
	private var _up0:Vector3;
	private var _zoom0:Int;
	private var _fov0:Int;
	private var _initialNear:Int;
	private var _nearPos0:Int;
	private var _initialFar:Int;
	private var _farPos0:Int;
	private var _cameraMatrixState0:Matrix4;
	private var _gizmoMatrixState0:Matrix4;
	private var _button:Int;
	private var _touchStart:Array<Dynamic>;
	private var _touchCurrent:Array<Dynamic>;
	private var _input:INPUT;
	private var _switchSensibility:Int;
	private var _startFingerDistance:Int;
	private var _currentFingerDistance:Int;
	private var _startFingerRotation:Int;
	private var _currentFingerRotation:Int;
	private var _devPxRatio:Int;
	private var _downValid:Bool;
	private var _nclicks:Int;
	private var _downEvents:Array<Dynamic>;
	private var _downStart:Int;
	private var _clickStart:Int;
	private var _maxDownTime:Int;
	private var _maxInterval:Int;
	private var _posThreshold:Int;
	private var _movementThreshold:Int;
	private var _currentCursorPosition:Vector3;
	private var _startCursorPosition:Vector3;
	private var _grid:Dynamic;
	private var _gridPosition:Vector3;
	private var _gizmos:Group;
	private var _curvePts:Int;
	private var _timeStart:Int;
	private var _animationId:Int;
	public var focusAnimationTime:Int;
	private var _timePrev:Int;
	private var _timeCurrent:Int;
	private var _anglePrev:Int;
	private var _angleCurrent:Int;
	private var _cursorPosPrev:Vector3;
	private var _cursorPosCurr:Vector3;
	private var _wPrev:Int;
	private var _wCurr:Int;
	public var adjustNearFar:Bool;
	public var scaleFactor:Int;
	public var dampingFactor:Int;
	public var wMax:Int;
	public var enableAnimations:Bool;
	public var enableGrid:Bool;
	public var cursorZoom:Bool;
	public var minFov:Int;
	public var maxFov:Int;
	public var rotateSpeed:Int;
	public var enabled:Bool;
	public var enablePan:Bool;
	public var enableRotate:Bool;
	public var enableZoom:Bool;
	public var enableGizmos:Bool;
	public var minDistance:Int;
	public var maxDistance:Int;
	public var minZoom:Int;
	public var maxZoom:Int;
	private var _tbRadius:Int;
	private var _state:STATE;

	public function new(camera:Camera, domElement:HtmlElement, ?scene:Scene) {
		super();
		_center = new Vector2();
		_transformation = [new Matrix4(), new Matrix4()];
		_changeEvent = { type: 'change' };
		_startEvent = { type: 'start' };
		_endEvent = { type: 'end' };
		_raycaster = new Raycaster();
		_offset = new Vector3();
		_gizmoMatrixStateTemp = new Matrix4();
		_cameraMatrixStateTemp = new Matrix4();
		_scalePointTemp = new Vector3();
		this.camera = null;
		this.domElement = domElement;
		this.scene = scene;
		this.target = new Vector3();
		this._currentTarget = new Vector3();
		this.radiusFactor = 0.67;
		this.mouseActions = [];
		this._mouseOp = null;
		this._v2_1 = new Vector2();
		this._v3_1 = new Vector3();
		this._v3_2 = new Vector3();
		this._m4_1 = new Matrix4();
		this._m4_2 = new Matrix4();
		this._quat = new Quaternion();
		this._translationMatrix = new Matrix4();
		this._rotationMatrix = new Matrix4();
		this._scaleMatrix = new Matrix4();
		this._rotationAxis = new Vector3();
		this._cameraMatrixState = new Matrix4();
		this._cameraProjectionState = new Matrix4();
		this._fovState = 1;
		this._upState = new Vector3();
		this._zoomState = 1;
		this._nearPos = 0;
		this._farPos = 0;
		this._gizmoMatrixState = new Matrix4();
		this._up0 = new Vector3();
		this._zoom0 = 1;
		this._fov0 = 0;
		this._initialNear = 0;
		this._nearPos0 = 0;
		this._initialFar = 0;
		this._farPos0 = 0;
		this._cameraMatrixState0 = new Matrix4();
		this._gizmoMatrixState0 = new Matrix4();
		this._button = -1;
		this._touchStart = [];
		this._touchCurrent = [];
		this._input = INPUT.NONE;
		this._switchSensibility = 32;
		this._startFingerDistance = 0;
		this._currentFingerDistance = 0;
		this._startFingerRotation = 0;
		this._currentFingerRotation = 0;
		this._devPxRatio = Std.int(window.devicePixelRatio);
		this._downValid = true;
		this._nclicks = 0;
		this._downEvents = [];
		this._downStart = 0;
		this._clickStart = 0;
		this._maxDownTime = 250;
		this._maxInterval = 300;
		this._posThreshold = 24;
		this._movementThreshold = 24;
		this._currentCursorPosition = new Vector3();
		this._startCursorPosition = new Vector3();
		this._grid = null;
		this._gridPosition = new Vector3();
		this._gizmos = new Group();
		this._curvePts = 128;
		this._timeStart = -1;
		this.focusAnimationTime = 500;
		this._timePrev = 0;
		this._timeCurrent = 0;
		this._anglePrev = 0;
		this._angleCurrent = 0;
		this._cursorPosPrev = new Vector3();
		this._cursorPosCurr = new Vector3();
		this._wPrev = 0;
		this._wCurr = 0;
		this.adjustNearFar = false;
		this.scaleFactor = 1.1;
		this.dampingFactor = 25;
		this.wMax = 20;
		this.enableAnimations = true;
		this.enableGrid = false;
		this.cursorZoom = false;
		this.minFov = 5;
		this.maxFov = 90;
		this.rotateSpeed = 1;
		this.enabled = true;
		this.enablePan = true;
		this.enableRotate = true;
		this.enableZoom = true;
		this.enableGizmos = true;
		this.minDistance = 0;
		this.maxDistance = Int.POSITIVE_INFINITY;
		this.minZoom = 0;
		this.maxZoom = Int.POSITIVE_INFINITY;
		this._tbRadius = 1;
		this._state = STATE.IDLE;
		this.setCamera(camera);
		if (this.scene != null) {
			this.scene.add(this._gizmos);
		}
		this.domElement.style.touchAction = 'none';
		this.initializeMouseActions();
		this._onContextMenu = bind(this, this.onContextMenu);
		this._onWheel = bind(this, this.onWheel);
		this._onPointerUp = bind(this, this.onPointerUp);
		this._onPointerMove = bind(this, this.onPointerMove);
		this._onPointerDown = bind(this, this.onPointerDown);
		this._onPointerCancel = bind(this, this.onPointerCancel);
		this._onWindowResize = bind(this, this.onWindowResize);
		this.domElement.addEventListener('contextmenu', this._onContextMenu);
		this.domElement.addEventListener('wheel', this._onWheel);
		this.domElement.addEventListener('pointerdown', this._onPointerDown);
		this.domElement.addEventListener('pointercancel', this._onPointerCancel);
		window.addEventListener('resize', this._onWindowResize);
	}

	private function onSinglePanStart(event:Dynamic, operation:String) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this.setCenter(event.clientX, event.clientY);
			switch (operation) {
				case 'PAN':
					if (!this.enablePan) {
						return;
					}
					if (this._animationId != -1) {
						js.Browser.window.cancelAnimationFrame(this._animationId);
						this._animationId = -1;
						this._timeStart = -1;
						this.activateGizmos(false);
						this.dispatchEvent(_changeEvent);
					}
					this.updateTbState(STATE.PAN, true);
					this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement));
					if (this.enableGrid) {
						this.drawGrid();
						this.dispatchEvent(_changeEvent);
					}
					break;
				case 'ROTATE':
					if (!this.enableRotate) {
						return;
					}
					if (this._animationId != -1) {
						js.Browser.window.cancelAnimationFrame(this._animationId);
						this._animationId = -1;
						this._timeStart = -1;
					}
					this.updateTbState(STATE.ROTATE, true);
					this._startCursorPosition.copy(this.unprojectOnTbSurface(this.camera, _center.x, _center.y, this.domElement, this._tbRadius));
					this.activateGizmos(true);
					if (this.enableAnimations) {
						this._timePrev = this._timeCurrent = js.Browser.performance.now();
						this._angleCurrent = this._anglePrev = 0;
						this._cursorPosPrev.copy(this._startCursorPosition);
						this._cursorPosCurr.copy(this._cursorPosPrev);
						this._wCurr = 0;
						this._wPrev = this._wCurr;
					}
					this.dispatchEvent(_changeEvent);
					break;
				case 'FOV':
					if (!this.camera.isPerspectiveCamera || !this.enableZoom) {
						return;
					}
					if (this._animationId != -1) {
						js.Browser.window.cancelAnimationFrame(this._animationId);
						this._animationId = -1;
						this._timeStart = -1;
						this.activateGizmos(false);
						this.dispatchEvent(_changeEvent);
					}
					this.updateTbState(STATE.FOV, true);
					this._startCursorPosition.y = this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5;
					this._currentCursorPosition.copy(this._startCursorPosition);
					break;
				case 'ZOOM':
					if (!this.enableZoom) {
						return;
					}
					if (this._animationId != -1) {
						js.Browser.window.cancelAnimationFrame(this._animationId);
						this._animationId = -1;
						this._timeStart = -1;
						this.activateGizmos(false);
						this.dispatchEvent(_changeEvent);
					}
					this.updateTbState(STATE.SCALE, true);
					this._startCursorPosition.y = this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5;
					this._currentCursorPosition.copy(this._startCursorPosition);
					break;
			}
		}
	}

	private function onSinglePanMove(event:Dynamic, opState:STATE) {
		if (this.enabled) {
			var restart = opState != this._state;
			this.setCenter(event.clientX, event.clientY);
			switch (opState) {
				case STATE.PAN:
					if (this.enablePan) {
						if (restart) {
							this.dispatchEvent(_endEvent);
							this.dispatchEvent(_startEvent);
							this.updateTbState(opState, true);
							this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement));
							if (this.enableGrid) {
								this.drawGrid();
							}
							this.activateGizmos(false);
						} else {
							this._currentCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement));
							this.applyTransformMatrix(this.pan(this._startCursorPosition, this._currentCursorPosition));
						}
					}
					break;
				case STATE.ROTATE:
					if (this.enableRotate) {
						if (restart) {
							this.dispatchEvent(_endEvent);
							this.dispatchEvent(_startEvent);
							this.updateTbState(opState, true);
							this._startCursorPosition.copy(this.unprojectOnTbSurface(this.camera, _center.x, _center.y, this.domElement, this._tbRadius));
							if (this.enableGrid) {
								this.disposeGrid();
							}
							this.activateGizmos(true);
						} else {
							this._currentCursorPosition.copy(this.unprojectOnTbSurface(this.camera, _center.x, _center.y, this.domElement, this._tbRadius));
							var distance = this._startCursorPosition.distanceTo(this._currentCursorPosition);
							var angle = this._startCursorPosition.angleTo(this._currentCursorPosition);
							var amount = Math.max(distance / this._tbRadius, angle) * this.rotateSpeed;
							this.applyTransformMatrix(this.rotate(this.calculateRotationAxis(this._startCursorPosition, this._currentCursorPosition), amount));
							if (this.enableAnimations) {
								this._timePrev = this._timeCurrent;
								this._timeCurrent = js.Browser.performance.now();
								this._anglePrev = this._angleCurrent;
								this._angleCurrent = amount;
								this._cursorPosPrev.copy(this._cursorPosCurr);
								this._cursorPosCurr.copy(this._currentCursorPosition);
								this._wPrev = this._wCurr;
								this._wCurr = this.calculateAngularSpeed(this._anglePrev, this._angleCurrent, this._timePrev, this._timeCurrent);
							}
						}
					}
					break;
				case STATE.SCALE:
					if (this.enableZoom) {
						if (restart) {
							this.dispatchEvent(_endEvent);
							this.dispatchEvent(_startEvent);
							this.updateTbState(opState, true);
							this._startCursorPosition.y = this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5;
							this._currentCursorPosition.copy(this._startCursorPosition);
							if (this.enableGrid) {
								this.disposeGrid();
							}
							this.activateGizmos(false);
						} else {
							var screenNotches = 8;
							this._currentCursorPosition.y = this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5;
							var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
							var size = 1;
							if (movement < 0) {
								size = 1 / Math.pow(this.scaleFactor, -movement * screenNotches);
							} else if (movement > 0) {
								size = Math.pow(this.scaleFactor, movement * screenNotches);
							}
							this._v3_1.setFromMatrixPosition(this._gizmoMatrixState);
							this.applyTransformMatrix(this.scale(size, this._v3_1));
						}
					}
					break;
				case STATE.FOV:
					if (this.enableZoom && this.camera.isPerspectiveCamera) {
						if (restart) {
							this.dispatchEvent(_endEvent);
							this.dispatchEvent(_startEvent);
							this.updateTbState(opState, true);
							this._startCursorPosition.y = this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5;
							this._currentCursorPosition.copy(this._startCursorPosition);
							if (this.enableGrid) {
								this.disposeGrid();
							}
							this.activateGizmos(false);
						} else {
							var screenNotches = 8;
							this._currentCursorPosition.y = this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5;
							var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
							var size = 1;
							if (movement < 0) {
								size = 1 / Math.pow(this.scaleFactor, -movement * screenNotches);
							} else if (movement > 0) {
								size = Math.pow(this.scaleFactor, movement * screenNotches);
							}
							this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
							var x = this._v3_1.distanceTo(this._gizmos.position);
							var xNew = x / size;
							xNew = Math.clamp(xNew, this.minDistance, this.maxDistance);
							var y = x * Math.tan(Math.DEG2RAD * this._fovState * 0.5);
							var newFov = Math.RAD2DEG * (Math.atan(y / xNew) * 2);
							newFov = Math.clamp(newFov, this.minFov, this.maxFov);
							var newDistance = y / Math.tan(Math.DEG2RAD * (newFov / 2));
							size = x / newDistance;
							this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
							this.setFov(newFov);
							this.applyTransformMatrix(this.scale(size, this._v3_2, false));
							_offset.copy(this._gizmos.position).sub(this.camera.position).normalize().multiplyScalar(newDistance / x);
							this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
						}
					}
					break;
			}
			this.dispatchEvent(_changeEvent);
		}
	}