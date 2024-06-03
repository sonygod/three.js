import three.core.GridHelper;
import three.extras.curves.EllipseCurve;
import three.core.BufferGeometry;
import three.objects.Line;
import three.materials.LineBasicMaterial;
import three.core.Raycaster;
import three.objects.Group;
import three.math.Box3;
import three.math.Sphere;
import three.math.Quaternion;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Matrix4;
import three.math.MathUtils;
import three.core.EventDispatcher;
import three.cameras.Camera;
import three.scenes.Scene;
import three.core.Object3D;

//trackball state
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
	ANIMATION_ROTATE
}

enum INPUT {
	NONE,
	ONE_FINGER,
	ONE_FINGER_SWITCHED,
	TWO_FINGER,
	MULT_FINGER,
	CURSOR
}

//cursor center coordinates
class Center {
	public var x:Float;
	public var y:Float;
	public function new() {
		this.x = 0;
		this.y = 0;
	}
}

//transformation matrices for gizmos and camera
class Transformation {
	public var camera:Matrix4;
	public var gizmos:Matrix4;
	public function new() {
		this.camera = new Matrix4();
		this.gizmos = new Matrix4();
	}
}

//events
var _changeEvent = { type: "change" };
var _startEvent = { type: "start" };
var _endEvent = { type: "end" };

var _raycaster = new Raycaster();
var _offset = new Vector3();

var _gizmoMatrixStateTemp = new Matrix4();
var _cameraMatrixStateTemp = new Matrix4();
var _scalePointTemp = new Vector3();

/**
 *
 * @param {Camera} camera Virtual camera used in the scene
 * @param {HTMLElement} domElement Renderer's dom element
 * @param {Scene} scene The scene to be rendered
 */
class ArcballControls extends EventDispatcher {
	public var camera:Camera;
	public var domElement:Dynamic;
	public var scene:Scene;
	public var target:Vector3;
	private var _currentTarget:Vector3;
	public var radiusFactor:Float;
	public var mouseActions:Array<{ operation:String, mouse:Dynamic, key:Dynamic, state:STATE }>;
	private var _mouseOp:String;
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
	private var _fovState:Float;
	private var _upState:Vector3;
	private var _zoomState:Float;
	private var _nearPos:Float;
	private var _farPos:Float;
	private var _gizmoMatrixState:Matrix4;
	private var _up0:Vector3;
	private var _zoom0:Float;
	private var _fov0:Float;
	private var _initialNear:Float;
	private var _nearPos0:Float;
	private var _initialFar:Float;
	private var _farPos0:Float;
	private var _cameraMatrixState0:Matrix4;
	private var _gizmoMatrixState0:Matrix4;
	private var _button:Int;
	private var _touchStart:Array<Dynamic>;
	private var _touchCurrent:Array<Dynamic>;
	private var _input:INPUT;
	private var _switchSensibility:Float;
	private var _startFingerDistance:Float;
	private var _currentFingerDistance:Float;
	private var _startFingerRotation:Float;
	private var _currentFingerRotation:Float;
	private var _devPxRatio:Float;
	private var _downValid:Bool;
	private var _nclicks:Int;
	private var _downEvents:Array<Dynamic>;
	private var _downStart:Float;
	private var _clickStart:Float;
	private var _maxDownTime:Float;
	private var _maxInterval:Float;
	private var _posThreshold:Float;
	private var _movementThreshold:Float;
	private var _currentCursorPosition:Vector3;
	private var _startCursorPosition:Vector3;
	private var _grid:GridHelper;
	private var _gridPosition:Vector3;
	private var _gizmos:Group;
	private var _curvePts:Int;
	private var _timeStart:Float;
	private var _animationId:Int;
	public var focusAnimationTime:Float;
	private var _timePrev:Float;
	private var _timeCurrent:Float;
	private var _anglePrev:Float;
	private var _angleCurrent:Float;
	private var _cursorPosPrev:Vector3;
	private var _cursorPosCurr:Vector3;
	private var _wPrev:Float;
	private var _wCurr:Float;
	public var adjustNearFar:Bool;
	public var scaleFactor:Float;
	public var dampingFactor:Float;
	public var wMax:Float;
	public var enableAnimations:Bool;
	public var enableGrid:Bool;
	public var cursorZoom:Bool;
	public var minFov:Float;
	public var maxFov:Float;
	public var rotateSpeed:Float;
	public var enabled:Bool;
	public var enablePan:Bool;
	public var enableRotate:Bool;
	public var enableZoom:Bool;
	public var enableGizmos:Bool;
	public var minDistance:Float;
	public var maxDistance:Float;
	public var minZoom:Float;
	public var maxZoom:Float;
	private var _tbRadius:Float;
	private var _state:STATE;
	private var _onContextMenu:Dynamic;
	private var _onWheel:Dynamic;
	private var _onPointerUp:Dynamic;
	private var _onPointerMove:Dynamic;
	private var _onPointerDown:Dynamic;
	private var _onPointerCancel:Dynamic;
	private var _onWindowResize:Dynamic;
	public function new(camera:Camera, domElement:Dynamic, scene:Scene = null) {
		super();
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
		this._button = - 1;
		this._touchStart = [];
		this._touchCurrent = [];
		this._input = INPUT.NONE;
		this._switchSensibility = 32;
		this._startFingerDistance = 0;
		this._currentFingerDistance = 0;
		this._startFingerRotation = 0;
		this._currentFingerRotation = 0;
		this._devPxRatio = 0;
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
		this._timeStart = - 1;
		this._animationId = - 1;
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
		this.maxDistance = Math.POSITIVE_INFINITY;
		this.minZoom = 0;
		this.maxZoom = Math.POSITIVE_INFINITY;
		this._tbRadius = 1;
		this._state = STATE.IDLE;
		this.setCamera(camera);
		if (this.scene != null) {
			this.scene.add(this._gizmos);
		}
		this.domElement.style.touchAction = "none";
		this._devPxRatio = window.devicePixelRatio;
		this.initializeMouseActions();
		this._onContextMenu = onContextMenu.bind(this);
		this._onWheel = onWheel.bind(this);
		this._onPointerUp = onPointerUp.bind(this);
		this._onPointerMove = onPointerMove.bind(this);
		this._onPointerDown = onPointerDown.bind(this);
		this._onPointerCancel = onPointerCancel.bind(this);
		this._onWindowResize = onWindowResize.bind(this);
		this.domElement.addEventListener("contextmenu", this._onContextMenu);
		this.domElement.addEventListener("wheel", this._onWheel);
		this.domElement.addEventListener("pointerdown", this._onPointerDown);
		this.domElement.addEventListener("pointercancel", this._onPointerCancel);
		window.addEventListener("resize", this._onWindowResize);
	}

	public function onSinglePanStart(event:Dynamic, operation:String) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this.setCenter(event.clientX, event.clientY);
			switch (operation) {
			case "PAN":
				if (!this.enablePan) {
					return;
				}
				if (this._animationId != - 1) {
					cancelAnimationFrame(this._animationId);
					this._animationId = - 1;
					this._timeStart = - 1;
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
			case "ROTATE":
				if (!this.enableRotate) {
					return;
				}
				if (this._animationId != - 1) {
					cancelAnimationFrame(this._animationId);
					this._animationId = - 1;
					this._timeStart = - 1;
				}
				this.updateTbState(STATE.ROTATE, true);
				this._startCursorPosition.copy(this.unprojectOnTbSurface(this.camera, _center.x, _center.y, this.domElement, this._tbRadius));
				this.activateGizmos(true);
				if (this.enableAnimations) {
					this._timePrev = this._timeCurrent = window.performance.now();
					this._angleCurrent = this._anglePrev = 0;
					this._cursorPosPrev.copy(this._startCursorPosition);
					this._cursorPosCurr.copy(this._cursorPosPrev);
					this._wCurr = 0;
					this._wPrev = this._wCurr;
				}
				this.dispatchEvent(_changeEvent);
				break;
			case "FOV":
				if (!this.camera.isPerspectiveCamera || !this.enableZoom) {
					return;
				}
				if (this._animationId != - 1) {
					cancelAnimationFrame(this._animationId);
					this._animationId = - 1;
					this._timeStart = - 1;
					this.activateGizmos(false);
					this.dispatchEvent(_changeEvent);
				}
				this.updateTbState(STATE.FOV, true);
				this._startCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
				this._currentCursorPosition.copy(this._startCursorPosition);
				break;
			case "ZOOM":
				if (!this.enableZoom) {
					return;
				}
				if (this._animationId != - 1) {
					cancelAnimationFrame(this._animationId);
					this._animationId = - 1;
					this._timeStart = - 1;
					this.activateGizmos(false);
					this.dispatchEvent(_changeEvent);
				}
				this.updateTbState(STATE.SCALE, true);
				this._startCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
				this._currentCursorPosition.copy(this._startCursorPosition);
				break;
			}
		}
	}

	public function onSinglePanMove(event:Dynamic, opState:STATE) {
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
							this._timeCurrent = window.performance.now();
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
						this._startCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
						this._currentCursorPosition.copy(this._startCursorPosition);
						if (this.enableGrid) {
							this.disposeGrid();
						}
						this.activateGizmos(false);
					} else {
						var screenNotches = 8;
						this._currentCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
						var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
						var size = 1;
						if (movement < 0) {
							size = 1 / Math.pow(this.scaleFactor, - movement * screenNotches);
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
						this._startCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
						this._currentCursorPosition.copy(this._startCursorPosition);
						if (this.enableGrid) {
							this.disposeGrid();
						}
						this.activateGizmos(false);
					} else {
						var screenNotches = 8;
						this._currentCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
						var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
						var size = 1;
						if (movement < 0) {
							size = 1 / Math.pow(this.scaleFactor, - movement * screenNotches);
						} else if (movement > 0) {
							size = Math.pow(this.scaleFactor, movement * screenNotches);
						}
						this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
						var x = this._v3_1.distanceTo(this._gizmos.position);
						var xNew = x / size;
						xNew = MathUtils.clamp(xNew, this.minDistance, this.maxDistance);
						var y = x * Math.tan(MathUtils.DEG2RAD * this._fovState * 0.5);
						var newFov = MathUtils.RAD2DEG * (Math.atan(y / xNew) * 2);
						newFov = MathUtils.clamp(newFov, this.minFov, this.maxFov);
						var newDistance = y / Math.tan(MathUtils.DEG2RAD * (newFov / 2));
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

	public function onSinglePanEnd() {
		if (this._state == STATE.ROTATE) {
			if (!this.enableRotate) {
				return;
			}
			if (this.enableAnimations) {
				var deltaTime = (window.performance.now() - this._timeCurrent);
				if (deltaTime < 120) {
					var w = Math.abs((this._wPrev + this._wCurr) / 2);
					var self = this;
					this._animationId = window.requestAnimationFrame(function(t) {
						self.updateTbState(STATE.ANIMATION_ROTATE, true);
						var rotationAxis = self.calculateRotationAxis(self._cursorPosPrev, self._cursorPosCurr);
						self.onRotationAnim(t, rotationAxis, Math.min(w, self.wMax));
					});
				} else {
					this.updateTbState(STATE.IDLE, false);
					this.activateGizmos(false);
					this.dispatchEvent(_changeEvent);
				}
			} else {
				this.updateTbState(STATE.IDLE, false);
				this.activateGizmos(false);
				this.dispatchEvent(_changeEvent);
			}
		} else if (this._state == STATE.PAN || this._state == STATE.IDLE) {
			this.updateTbState(STATE.IDLE, false);
			if (this.enableGrid) {
				this.disposeGrid();
			}
			this.activateGizmos(false);
			this.dispatchEvent(_changeEvent);
		}
		this.dispatchEvent(_endEvent);
	}

	public function onDoubleTap(event:Dynamic) {
		if (this.enabled && this.enablePan && this.scene != null) {
			this.dispatchEvent(_startEvent);
			this.setCenter(event.clientX, event.clientY);
			var hitP = this.unprojectOnObj(this.getCursorNDC(_center.x, _center.y, this.domElement), this.camera);
			if (hitP != null && this.enableAnimations) {
				var self = this;
				if (this._animationId != - 1) {
					window.cancelAnimationFrame(this._animationId);
				}
				this._timeStart = - 1;
				this._animationId = window.requestAnimationFrame(function(t) {
					self.updateTbState(STATE.ANIMATION_FOCUS, true);
					self.onFocusAnim(t, hitP, self._cameraMatrixState, self._gizmoMatrixState);
				});
			} else if (hitP != null && !this.enableAnimations) {
				this.updateTbState(STATE.FOCUS, true);
				this.focus(hitP, this.scaleFactor);
				this.updateTbState(STATE.IDLE, false);
				this.dispatchEvent(_changeEvent);
			}
		}
		this.dispatchEvent(_endEvent);
	}

	public function onDoublePanStart() {
		if (this.enabled && this.enablePan) {
			this.dispatchEvent(_startEvent);
			this.updateTbState(STATE.PAN, true);
			this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			this.activateGizmos(false);
		}
	}

	public function onDoublePanMove() {
		if (this.enabled && this.enablePan) {
			this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);
			if (this._state != STATE.PAN) {
				this.updateTbState(STATE.PAN, true);
				this._startCursorPosition.copy(this._currentCursorPosition);
			}
			this._currentCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this.applyTransformMatrix(this.pan(this._startCursorPosition, this._currentCursorPosition, true));
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onDoublePanEnd() {
		this.updateTbState(STATE.IDLE, false);
		this.dispatchEvent(_endEvent);
	}

	public function onRotateStart() {
		if (this.enabled && this.enableRotate) {
			this.dispatchEvent(_startEvent);
			this.updateTbState(STATE.ZROTATE, true);
			this._startFingerRotation = this.getAngle(this._touchCurrent[1], this._touchCurrent[0]) + this.getAngle(this._touchStart[1], this._touchStart[0]);
			this._currentFingerRotation = this._startFingerRotation;
			this.camera.getWorldDirection(this._rotationAxis);
			if (!this.enablePan && !this.enableZoom) {
				this.activateGizmos(true);
			}
		}
	}

	public function onRotateMove() {
		if (this.enabled && this.enableRotate) {
			this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);
			var rotationPoint:Vector3;
			if (this._state != STATE.ZROTATE) {
				this.updateTbState(STATE.ZROTATE, true);
				this._startFingerRotation = this._currentFingerRotation;
			}
			this._currentFingerRotation = this.getAngle(this._touchCurrent[1], this._touchCurrent[0]) + this.getAngle(this._touchStart[1], this._touchStart[0]);
			if (!this.enablePan) {
				rotationPoint = new Vector3().setFromMatrixPosition(this._gizmoMatrixState);
			} else {
				this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
				rotationPoint = this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement).applyQuaternion(this.camera.quaternion).multiplyScalar(1 / this.camera.zoom).add(this._v3_2);
			}
			var amount = MathUtils.DEG2RAD * (this._startFingerRotation - this._currentFingerRotation);
			this.applyTransformMatrix(this.zRotate(rotationPoint, amount));
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onRotateEnd() {
		this.updateTbState(STATE.IDLE, false);
		this.activateGizmos(false);
		this.dispatchEvent(_endEvent);
	}

	public function onPinchStart() {
		if (this.enabled && this.enableZoom) {
			this.dispatchEvent(_startEvent);
			this.updateTbState(STATE.SCALE, true);
			this._startFingerDistance = this.calculatePointersDistance(this._touchCurrent[0], this._touchCurrent[1]);
			this._currentFingerDistance = this._startFingerDistance;
			this.activateGizmos(false);
		}
	}

	public function onPinchMove() {
		if (this.enabled && this.enableZoom) {
			this.setCenter((this._touchCurrent[0].clientX + this._touchCurrent[1].clientX) / 2, (this._touchCurrent[0].clientY + this._touchCurrent[1].clientY) / 2);
			var minDistance = 12;
			if (this._state != STATE.SCALE) {
				this._startFingerDistance = this._currentFingerDistance;
				this.updateTbState(STATE.SCALE, true);
			}
			this._currentFingerDistance = Math.max(this.calculatePointersDistance(this._touchCurrent[0], this._touchCurrent[1]), minDistance * this._devPxRatio);
			var amount = this._currentFingerDistance / this._startFingerDistance;
			var scalePoint:Vector3;
			if (!this.enablePan) {
				scalePoint = this._gizmos.position;
			} else {
				if (this.camera.isOrthographicCamera) {
					scalePoint = this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement)
						.applyQuaternion(this.camera.quaternion)
						.multiplyScalar(1 / this.camera.zoom)
						.add(this._gizmos.position);
				} else if (this.camera.isPerspectiveCamera) {
					scalePoint = this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement)
						.applyQuaternion(this.camera.quaternion)
						.add(this._gizmos.position);
				}
			}
			this.applyTransformMatrix(this.scale(amount, scalePoint));
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onPinchEnd() {
		this.updateTbState(STATE.IDLE, false);
		this.dispatchEvent(_endEvent);
	}

	public function onTriplePanStart() {
		if (this.enabled && this.enableZoom) {
			this.dispatchEvent(_startEvent);
			this.updateTbState(STATE.SCALE, true);
			var clientX = 0;
			var clientY = 0;
			var nFingers = this._touchCurrent.length;
			for (var i in 0...nFingers) {
				clientX += this._touchCurrent[i].clientX;
				clientY += this._touchCurrent[i].clientY;
			}
			this.setCenter(clientX / nFingers, clientY / nFingers);
			this._startCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
			this._currentCursorPosition.copy(this._startCursorPosition);
		}
	}

	public function onTriplePanMove() {
		if (this.enabled && this.enableZoom) {
			var clientX = 0;
			var clientY = 0;
			var nFingers = this._touchCurrent.length;
			for (var i in 0...nFingers) {
				clientX += this._touchCurrent[i].clientX;
				clientY += this._touchCurrent[i].clientY;
			}
			this.setCenter(clientX / nFingers, clientY / nFingers);
			var screenNotches = 8;
			this._currentCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
			var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
			var size = 1;
			if (movement < 0) {
				size = 1 / Math.pow(this.scaleFactor, - movement * screenNotches);
			} else if (movement > 0) {
				size = Math.pow(this.scaleFactor, movement * screenNotches);
			}
			this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
			var x = this._v3_1.distanceTo(this._gizmos.position);
			var xNew = x / size;
			xNew = MathUtils.clamp(xNew, this.minDistance, this.maxDistance);
			var y = x * Math.tan(MathUtils.DEG2RAD * this._fovState * 0.5);
			var newFov = MathUtils.RAD2DEG * (Math.atan(y / xNew) * 2);
			newFov = MathUtils.clamp(newFov, this.minFov, this.maxFov);
			var newDistance = y / Math.tan(MathUtils.DEG2RAD * (newFov / 2));
			size = x / newDistance;
			this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
			this.setFov(newFov);
			this.applyTransformMatrix(
			this.scale(size, this._v3_2, false));
			_offset.copy(this._gizmos.position).sub(this.camera.position).normalize().multiplyScalar(newDistance / x);
			this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onTriplePanEnd() {
		this.updateTbState(STATE.IDLE, false);
		this.dispatchEvent(_endEvent);
		//this.dispatchEvent(_changeEvent);
	}

	/**
	 * Set _center's x/y coordinates
	 * @param {Number} clientX
	 * @param {Number} clientY
	 */
	public function setCenter(clientX:Float, clientY:Float) {
		_center.x = clientX;
		_center.y = clientY;
	}

	/**
	 * Set default mouse actions
	 */
	public function initializeMouseActions() {
		this.setMouseAction("PAN", 0, "CTRL");
		this.setMouseAction("PAN", 2);
		this.setMouseAction("ROTATE", 0);
		this.setMouseAction("ZOOM", "WHEEL");
		this.setMouseAction("ZOOM", 1);
		this.setMouseAction("FOV", "WHEEL", "SHIFT");
		this.setMouseAction("FOV", 1, "SHIFT");
	}

	/**
	 * Compare two mouse actions
	 * @param {Object} action1
	 * @param {Object} action2
	 * @returns {Boolean} True if action1 and action 2 are the same mouse action, false otherwise
	 */
	public function compareMouseAction(action1:{ operation:String, mouse:Dynamic, key:Dynamic, state:STATE }, action2:{ operation:String, mouse:Dynamic, key:Dynamic, state:STATE }):Bool {
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

	/**
	 * Set a new mouse action by specifying the operation to be performed and a mouse/key combination. In case of conflict, replaces the existing one
	 * @param {String} operation The operation to be performed ('PAN', 'ROTATE', 'ZOOM', 'FOV)
	 * @param {*} mouse A mouse button (0, 1, 2) or 'WHEEL' for wheel notches
	 * @param {*} key The keyboard modifier ('CTRL', 'SHIFT') or null if key is not needed
	 * @returns {Boolean} True if the mouse action has been successfully added, false otherwise
	 */
	public function setMouseAction(operation:String, mouse:Dynamic, key:Dynamic = null):Bool {
		var operationInput = ["PAN", "ROTATE", "ZOOM", "FOV"];
		var mouseInput = [0, 1, 2, "WHEEL"];
		var keyInput = ["CTRL", "SHIFT", null];
		var state:STATE;
		if (!operationInput.contains(operation) || !mouseInput.contains(mouse) || !keyInput.contains(key)) {
			return false;
		}
		if (mouse == "WHEEL") {
			if (operation != "ZOOM" && operation != "FOV") {
				return false;
			}
		}
		switch (operation) {
		case "PAN":
			state = STATE.PAN;
			break;
		case "ROTATE":
			state = STATE.ROTATE;
			break;
		case "ZOOM":
			state = STATE.SCALE;
			break;
		case "FOV":
			state = STATE.FOV;
			break;
		}
		var action = {
			operation: operation,
			mouse: mouse,
			key: key,
			state: state
		};
		for (var i in 0...this.mouseActions.length) {
			if (this.mouseActions[i].mouse == action.mouse && this.mouseActions[i].key == action.key) {
				this.mouseActions.splice(i, 1, action);
				return true;
			}
		}
		this.mouseActions.push(action);
		return true;
	}

	/**
	 * Remove a mouse action by specifying its mouse/key combination
	 * @param {*} mouse A mouse button (0, 1, 2) or 'WHEEL' for wheel notches
	 * @param {*} key The keyboard modifier ('CTRL', 'SHIFT') or null if key is not needed
	 * @returns {Boolean} True if the operation has been succesfully removed, false otherwise
	 */
	public function unsetMouseAction(mouse:Dynamic, key:Dynamic = null):Bool {
		for (var i in 0...this.mouseActions.length) {
			if (this.mouseActions[i].mouse == mouse && this.mouseActions[i].key == key) {
				this.mouseActions.splice(i, 1);
				return true;
			}
		}
		return false;
	}

	/**
	 * Return the operation associated to a mouse/keyboard combination
	 * @param {*} mouse A mouse button (0, 1, 2) or 'WHEEL' for wheel notches
	 * @param {*} key The keyboard modifier ('CTRL', 'SHIFT') or null if key is not needed
	 * @returns The operation if it has been found, null otherwise
	 */
	public function getOpFromAction(mouse:Dynamic, key:Dynamic):String {
		var action:Dynamic;
		for (var i in 0...this.mouseActions.length) {
			action = this.mouseActions[i];
			if (action.mouse == mouse && action.key == key) {
				return action.operation;
			}
		}
		if (key != null) {
			for (var i in 0...this.mouseActions.length) {
				action = this.mouseActions[i];
				if (action.mouse == mouse && action.key == null) {
					return action.operation;
				}
			}
		}
		return null;
	}

	/**
	 * Get the operation associated to mouse and key combination and returns the corresponding FSA state
	 * @param {Number} mouse Mouse button
	 * @param {String} key Keyboard modifier
	 * @returns The FSA state obtained from the operation associated to mouse/keyboard combination
	 */
	public function getOpStateFromAction(mouse:Dynamic, key:Dynamic):STATE {
		var action:Dynamic;
		for (var i in 0...this.mouseActions.length) {
			action = this.mouseActions[i];
			if (action.mouse == mouse && action.key == key) {
				return action.state;
			}
		}
		if (key != null) {
			for (var i in 0...this.mouseActions.length) {
				action = this.mouseActions[i];
				if (action.mouse == mouse && action.key == null) {
					return action.state;
				}
			}
		}
		return null;
	}

	/**
	 * Calculate the angle between two pointers
	 * @param {PointerEvent} p1
	 * @param {PointerEvent} p2
	 * @returns {Number} The angle between two pointers in degrees
	 */
	public function getAngle(p1:Dynamic, p2:Dynamic):Float {
		return Math.atan2(p2.clientY - p1.clientY, p2.clientX - p1.clientX) * 180 / Math.PI;
	}

	/**
	 * Update a PointerEvent inside current pointerevents array
	 * @param {PointerEvent} event
	 */
	public function updateTouchEvent(event:Dynamic) {
		for (var i in 0...this._touchCurrent.length) {
			if (this._touchCurrent[i].pointerId == event.pointerId) {
				this._touchCurrent.splice(i, 1, event);
				break;
			}
		}
	}

	/**
	 * Apply a transformation matrix, to the camera and gizmos
	 * @param {Object} transformation Object containing matrices to apply to camera and gizmos
	 */
	public function applyTransformMatrix(transformation:Transformation) {
		if (transformation.camera != null) {
			this._m4_1.copy(this._cameraMatrixState).premultiply(transformation.camera);
			this._m4_1.decompose(this.camera.position, this.camera.quaternion, this.camera.scale);
			this.camera.updateMatrix();
			if (this._state == STATE.ROTATE || this._state == STATE.ZROTATE || this._state == STATE.ANIMATION_ROTATE) {
				this.camera.up.copy(this._upState).applyQuaternion(this.camera.quaternion);
			}
		}
		if (transformation.gizmos != null) {
			this._m4_1.copy(this._gizmoMatrixState).premultiply(transformation.gizmos);
			this._m4_1.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
			this._gizmos.updateMatrix();
		}
		if (this._state == STATE.SCALE || this._state == STATE.FOCUS || this._state == STATE.ANIMATION_FOCUS) {
			this._tbRadius = this.calculateTbRadius(this.camera);
			if (this.adjustNearFar) {
				var cameraDistance = this.camera.position.distanceTo(this._gizmos.position);
				var bb = new Box3();
				bb.setFromObject(this._gizmos);
				var sphere = new Sphere();
				bb.getBoundingSphere(sphere);
				var adjustedNearPosition = Math.max(this._nearPos0, sphere.radius + sphere.center.length());
				var regularNearPosition = cameraDistance - this._initialNear;
				var minNearPos = Math.min(adjustedNearPosition, regularNearPosition);
				this.camera.near = cameraDistance - minNearPos;
				var adjustedFarPosition = Math.min(this._farPos0, -sphere.radius + sphere.center.length());
				var regularFarPosition = cameraDistance - this._initialFar;
				var minFarPos = Math.min(adjustedFarPosition, regularFarPosition);
				this.camera.far = cameraDistance - minFarPos;
				this.camera.updateProjectionMatrix();
			} else {
				var update = false;
				if (this.camera.near != this._initialNear) {
					this.camera.near = this._initialNear;
					update = true;
				}
				if (this.camera.far != this._initialFar) {
					this.camera.far = this._initialFar;
					update = true;
				}
				if (update) {
					this.camera.updateProjectionMatrix();
				}
			}
		}
	}

	/**
	 * Calculate the angular speed
	 * @param {Number} p0 Position at t0
	 * @param {Number} p1 Position at t1
	 * @param {Number} t0 Initial time in milliseconds
	 * @param {Number} t1 Ending time in milliseconds
	 */
	public function calculateAngularSpeed(p0:Float, p1:Float, t0:Float, t1:Float):Float {
		var s = p1 - p0;
		var t = (t1 - t0) / 1000;
		if (t == 0) {
			return 0;
		}
		return s / t;
	}

	/**
	 * Calculate the distance between two pointers
	 * @param {PointerEvent} p0 The first pointer
	 * @param {PointerEvent} p1 The second pointer
	 * @returns {number} The distance between the two pointers
	 */
	public function calculatePointersDistance(p0:Dynamic, p1:Dynamic):Float {
		return Math.sqrt(Math.pow(p1.clientX - p0.clientX, 2) + Math.pow(p1.clientY - p0.clientY, 2));
	}

	/**
	 * Calculate the rotation axis as the vector perpendicular between two vectors
	 * @param {Vector3} vec1 The first vector
	 * @param {Vector3} vec2 The second vector
	 * @returns {Vector3} The normalized rotation axis
	 */
	public function calculateRotationAxis(vec1:Vector3, vec2:Vector3):Vector3 {
		this._rotationMatrix.extractRotation(this._cameraMatrixState);
		this._quat.setFromRotationMatrix(this._rotationMatrix);
		this._rotationAxis.crossVectors(vec1, vec2).applyQuaternion(this._quat);
		return this._rotationAxis.normalize().clone();
	}

	/**
	 * Calculate the trackball radius so that gizmo's diamater will be 2/3 of the minimum side of the camera frustum
	 * @param {Camera} camera
	 * @returns {Number} The trackball radius
	 */
	public function calculateTbRadius(camera:Camera):Float {
		var distance = camera.position.distanceTo(this._gizmos.position);
		if (camera.type == "PerspectiveCamera") {
			var halfFovV = MathUtils.DEG2RAD * camera.fov * 0.5;
			var halfFovH = Math.atan((camera.aspect) * Math.tan(halfFovV));
			return Math.tan(Math.min(halfFovV, halfFovH)) * distance * this.radiusFactor;
		} else if (camera.type == "OrthographicCamera") {
			return Math.min(camera.top, camera.right) * this.radiusFactor;
		}
		return 0;
	}

	/**
	 * Focus operation consist of positioning the point of interest in front of the camera and a slightly zoom in
	 * @param {Vector3} point The point of interest
	 * @param {Number} size Scale factor
	 * @param {Number} amount Amount of operation to be completed (used for focus animations, default is complete full operation)
	 */
	public function focus(point:Vector3, size:Float, amount:Float = 1) {
		_offset.copy(point).sub(this._gizmos.position).multiplyScalar(amount);
		this._translationMatrix.makeTranslation(_offset.x, _offset.y, _offset.z);
		_gizmoMatrixStateTemp.copy(this._gizmoMatrixState);
		this._gizmoMatrixState.premultiply(this._translationMatrix);
		this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
		_cameraMatrixStateTemp.copy(this._cameraMatrixState);
		this._cameraMatrixState.premultiply(this._translationMatrix);
		this._cameraMatrixState.decompose(this.camera.position, this.camera.quaternion, this.camera.scale);
		if (this.enableZoom) {
			this.applyTransformMatrix(this.scale(size, this._gizmos.position));
		}
		this._gizmoMatrixState.copy(_gizmoMatrixStateTemp);
		this._cameraMatrixState.copy(_cameraMatrixStateTemp);
	}

	/**
	 * Draw a grid and add it to the scene
	 */
	public function drawGrid() {
		if (this.scene != null) {
			var color = 0x888888;
			var multiplier = 3;
			var size:Float, divisions:Float, maxLength:Float, tick:Float;
			if (this.camera.isOrthographicCamera) {
				var width = this.camera.right - this.camera.left;
				var height = this.camera.bottom - this.camera.top;
				maxLength = Math.max(width, height);
				tick = maxLength / 20;
				size = maxLength / this.camera.zoom * multiplier;
				divisions = size / tick * this.camera.zoom;
			} else if (this.camera.isPerspectiveCamera) {
				var distance = this.camera.position.distanceTo(this._gizmos.position);
				var halfFovV = MathUtils.DEG2RAD * this.camera.fov * 0.5;
				var halfFovH = Math.atan((this.camera.aspect) * Math.tan(halfFovV));
				maxLength = Math.tan(Math.max(halfFovV, halfFovH)) * distance * 2;
				tick = maxLength / 20;
				size = maxLength * multiplier;
				divisions = size / tick;
			}
			if (this._grid == null) {
				this._grid = new GridHelper(size, divisions, color, color);
				this._grid.position.copy(this._gizmos.position);
				this._gridPosition.copy(this._grid.position);
				this._grid.quaternion.copy(this.camera.quaternion);
				this._grid.rotateX(Math.PI * 0.5);
				this.scene.add(this._grid);
			}
		}
	}

	/**
	 * Remove all listeners, stop animations and clean scene
	 */
	public function dispose() {
		if (this._animationId != - 1) {
			window.cancelAnimationFrame(this._animationId);
		}
		this.domElement.removeEventListener("pointerdown", this._onPointerDown);
		this.domElement.removeEventListener("pointercancel", this._onPointerCancel);
		this.domElement.removeEventListener("wheel", this._onWheel);
		this.domElement.removeEventListener("contextmenu", this._onContextMenu);
		window.removeEventListener("pointermove", this._onPointerMove);
		window.removeEventListener("pointerup", this._onPointerUp);
		window.removeEventListener("resize", this._onWindowResize);
		if (this.scene != null) this.scene.remove(this._gizmos);
		this.disposeGrid();
	}

	/**
	 * remove the grid from the scene
	 */
	public function disposeGrid() {
		if (this._grid != null && this.scene != null) {
			this.scene.remove(this._grid);
			this._grid = null;
		}
	}

	/**
	 * Compute the easing out cubic function for ease out effect in animation
	 * @param {Number} t The absolute progress of the animation in the bound of 0 (beginning of the) and 1 (ending of animation)
	 * @returns {Number} Result of easing out cubic at time t
	 */
	public function easeOutCubic(t:Float):Float {
		return 1 - Math.pow(1 - t, 3);
	}

	/**
	 * Make rotation gizmos more or less visible
	 * @param {Boolean} isActive If true, make gizmos more visible
	 */
	public function activateGizmos(isActive:Bool) {
		var gizmoX = this._gizmos.children[0];
		var gizmoY = this._gizmos.children[1];
		var gizmoZ = this._gizmos.children[2];
		if (isActive) {
			gizmoX.material.setValues({ opacity: 1 });
			gizmoY.material.setValues({ opacity: 1 });
			gizmoZ.material.setValues({ opacity: 1 });
		} else {
			gizmoX.material.setValues({ opacity: 0.6 });
			gizmoY.material.setValues({ opacity: 0.6 });
			gizmoZ.material.setValues({ opacity: 0.6 });
		}
	}

	/**
	 * Calculate the cursor position in NDC
	 * @param {number} x Cursor horizontal coordinate within the canvas
	 * @param {number} y Cursor vertical coordinate within the canvas
	 * @param {HTMLElement} canvas The canvas where the renderer draws its output
	 * @returns {Vector2} Cursor normalized position inside the canvas
	 */
	public function getCursorNDC(cursorX:Float, cursorY:Float, canvas:Dynamic):Vector2 {
		var canvasRect = canvas.getBoundingClientRect();
		this._v2_1.setX(((cursorX - canvasRect.left) / canvasRect.width) * 2 - 1);
		this._v2_1.setY(((canvasRect.bottom - cursorY) / canvasRect.height) * 2 - 1);
		return this._v2_1.clone();
	}

	/**
	 * Calculate the cursor position inside the canvas x/y coordinates with the origin being in the center of the canvas
	 * @param {Number} x Cursor horizontal coordinate within the canvas
	 * @param {Number} y Cursor vertical coordinate within the canvas
	 * @param {HTMLElement} canvas The canvas where the renderer draws its output
	 * @returns {Vector2} Cursor position inside the canvas
	 */
	public function getCursorPosition(cursorX:Float, cursorY:Float, canvas:Dynamic):Vector2 {
		this._v2_1.copy(this.getCursorNDC(cursorX, cursorY, canvas));
		this._v2_1.x *= (this.camera.right - this.camera.left) * 0.5;
		this._v2_1.y *= (this.camera.top - this.camera.bottom) * 0.5;
		return this._v2_1.clone();
	}

	/**
	 * Set the camera to be controlled
	 * @param {Camera} camera The virtual camera to be controlled
	 */
	public function setCamera(camera:Camera) {
		camera.lookAt(this.target);
		camera.updateMatrix();
		if (camera.type == "PerspectiveCamera") {
			this._fov0 = camera.fov;
			this._fovState = camera.fov;
		}
		this._cameraMatrixState0.copy(camera.matrix);
		this._cameraMatrixState.copy(this._cameraMatrixState0);
		this._cameraProjectionState.copy(camera.projectionMatrix);
		this._zoom0 = camera.zoom;
		this._zoomState = this._zoom0;
		this._initialNear = camera.near;
		this._nearPos0 = camera.position.distanceTo(this.target) - camera.near;
		this._nearPos = this._initialNear;
		this._initialFar = camera.far;
		this._farPos0 = camera.position.distanceTo(this.target) - camera.far;
		this._farPos = this._initialFar;
		this._up0.copy(camera.up);
		this._upState.copy(camera.up);
		this.camera = camera;
		this.camera.updateProjectionMatrix();
		this._tbRadius = this.calculateTbRadius(camera);
		this.makeGizmos(this.target, this._tbRadius);
	}

	/**
	 * Set gizmos visibility
	 * @param {Boolean} value Value of gizmos visibility
	 */
	public function setGizmosVisible(value:Bool) {
		this._gizmos.visible = value;
		this.dispatchEvent(_changeEvent);
	}

	/**
	 * Set gizmos radius factor and redraws gizmos
	 * @param {Float} value Value of radius factor
	 */
	public function setTbRadius(value:Float) {
		this.radiusFactor = value;
		this._tbRadius = this.calculateTbRadius(this.camera);
		var curve = new EllipseCurve(0, 0, this._tbRadius, this._tbRadius);
		var points = curve.getPoints(this._curvePts);
		var curveGeometry = new BufferGeometry().setFromPoints(points);
		for (var gizmo in this._gizmos.children) {
			this._gizmos.children[gizmo].geometry = curveGeometry;
		}
		this.dispatchEvent(_changeEvent);
	}

	/**
	 * Creates the rotation gizmos matching trackball center and radius
	 * @param {Vector3} tbCenter The trackball center
	 * @param {number} tbRadius The trackball radius
	 */
	public function makeGizmos(tbCenter:Vector3, tbRadius:Float) {
		var curve = new EllipseCurve(0, 0, tbRadius, tbRadius);
		var points = curve.getPoints(this._curvePts);
		var curveGeometry = new BufferGeometry().setFromPoints(points);
		var curveMaterialX = new LineBasicMaterial({ color: 0xff8080, fog: false, transparent: true, opacity: 0.6 });
		var curveMaterialY = new LineBasicMaterial({ color: 0x80ff80, fog: false, transparent: true, opacity: 0.6 });
		var curveMaterialZ = new LineBasicMaterial({ color: 0x8080ff, fog: false, transparent: true, opacity: 0.6 });
		var gizmoX = new Line(curveGeometry, curveMaterialX);
		var gizmoY = new Line(curveGeometry, curveMaterialY);
		var gizmoZ = new Line(curveGeometry, curveMaterialZ);
		var rotation = Math.PI * 0.5;
		gizmoX.rotation.x = rotation;
		gizmoY.rotation.y = rotation;
		this._gizmoMatrixState0.identity().setPosition(tbCenter);
		this._gizmoMatrixState.copy(this._gizmoMatrixState0);
		if (this.camera.zoom != 1) {
			var size = 1 / this.camera.zoom;
			this._scaleMatrix.makeScale(size, size, size);
			this._translationMatrix.makeTranslation(-tbCenter.x, -tbCenter.y, -tbCenter.z);
			this._gizmoMatrixState.premultiply(this._translationMatrix).premultiply(this._scaleMatrix);
			this._translationMatrix.makeTranslation(tbCenter.x, tbCenter.y, tbCenter.z);
			this._gizmoMatrixState.premultiply(this._translationMatrix);
		}
		this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
		this._gizmos.traverse(function(object:Object3D) {
			if (object.isLine) {
				object.geometry.dispose();
				object.material.dispose();
			}
		});
		this._gizmos.clear();
		this._gizmos.add(gizmoX);
		this._gizmos.add(gizmoY);
		this._gizmos.add(gizmoZ);
	}

	/**
	 * Perform animation for focus operation
	 * @param {Number} time Instant in which this function is called as performance.now()
	 * @param {Vector3} point Point of interest for focus operation
	 * @param {Matrix4} cameraMatrix Camera matrix
	 * @param {Matrix4} gizmoMatrix Gizmos matrix
	 */
	public function onFocusAnim(time:Float, point:Vector3, cameraMatrix:Matrix4, gizmoMatrix:Matrix4) {
		if (this._timeStart == - 1) {
			this._timeStart = time;
		}
		if (this._state == STATE.ANIMATION_FOCUS) {
			var deltaTime = time - this._timeStart;
			var animTime = deltaTime / this.focusAnimationTime;
			this._gizmoMatrixState.copy(gizmoMatrix);
			if (animTime >= 1) {
				this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
				this.focus(point, this.scaleFactor);
				this._timeStart = - 1;
				this.updateTbState(STATE.IDLE, false);
				this.activateGizmos(false);
				this.dispatchEvent(_changeEvent);
			} else {
				var amount = this.easeOutCubic(animTime);
				var size = ((1 - amount) + (this.scaleFactor * amount));
				this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
				this.focus(point, size, amount);
				this.dispatchEvent(_changeEvent);
				var self = this;
				this._animationId = window.requestAnimationFrame(function(t) {
					self.onFocusAnim(t, point, cameraMatrix, gizmoMatrix.clone());
				});
			}
		} else {
			this._animationId = - 1;
			this._timeStart = - 1;
		}
	}

	/**
	 * Perform animation for rotation operation
	 * @param {Number} time Instant in which this function is called as performance.now()
	 * @param {Vector3} rotationAxis Rotation axis
	 * @param {number} w0 Initial angular velocity
	 */
	public function onRotationAnim(time:Float, rotationAxis:Vector3, w0:Float) {
		if (this._timeStart == - 1) {
			this._anglePrev = 0;
			this._angleCurrent = 0;
			this._timeStart = time;
		}
		if (this._state == STATE.ANIMATION_ROTATE) {
			var deltaTime = (time - this._timeStart) / 1000;
			var w = w0 + ((-this.dampingFactor) * deltaTime);
			if (w > 0) {
				this._angleCurrent = 0.5 * (-this.dampingFactor) * Math.pow(deltaTime, 2) + w0 * deltaTime + 0;
				this.applyTransformMatrix(this.rotate(rotationAxis, this._angleCurrent));
				this.dispatchEvent(_changeEvent);
				var self = this;
				this._animationId = window.requestAnimationFrame(function(t) {
					self.onRotationAnim(t, rotationAxis, w0);
				});
			} else {
				this._animationId = - 1;
				this._timeStart = - 1;
				this.updateTbState(STATE.IDLE, false);
				this.activateGizmos(false);
				this.dispatchEvent(_changeEvent);
			}
		} else {
			this._animationId = - 1;
			this._timeStart = - 1;
			if (this._state != STATE.ROTATE) {
				this.activateGizmos(false);
				this.dispatchEvent(_changeEvent);
			}
		}
	}

	/**
	 * Perform pan operation moving camera between two points
	 * @param {Vector3} p0 Initial point
	 * @param {Vector3} p1 Ending point
	 * @param {Boolean} adjust If movement should be adjusted considering camera distance (Perspective only)
	 */
	public function pan(p0:Vector3, p1:Vector3, adjust:Bool = false):Transformation {
		var movement = p0.clone().sub(p1);
		if (this.camera.isOrthographicCamera) {
			movement.multiplyScalar(1 / this.camera.zoom);
		} else if (this.camera.isPerspectiveCamera && adjust) {
			this._v3_1.setFromMatrixPosition(this._cameraMatrixState0);
			this._v3_2.setFromMatrixPosition(this._gizmoMatrixState0);
			var distanceFactor = this._v3_1.distanceTo(this._v3_2) / this.camera.position.distanceTo(this._gizmos.position);
			movement.multiplyScalar(1 / distanceFactor);
		}
		this._v3_1.set(movement.x, movement.y, 0).applyQuaternion(this.camera.quaternion);
		this._m4_1.makeTranslation(this._v3_1.x, this._v3_1.y, this._v3_1.z);
		this.setTransformationMatrices(this._m4_1, this._m4_1);
		return _transformation;
	}

	/**
	 * Reset trackball
	 */
	public function reset() {
		this.camera.zoom = this._zoom0;
		if (this.camera.isPerspectiveCamera) {
			this.camera.fov = this._fov0;
		}
		this.camera.near = this._nearPos;
		this.camera.far = this._farPos;
		this._cameraMatrixState.copy(this._cameraMatrixState0);
		this._cameraMatrixState.decompose(this.camera.position, this.camera.quaternion, this.camera.scale);
		this.camera.up.copy(this._up0);
		this.camera.updateMatrix();
		this.camera.updateProjectionMatrix();
		this._gizmoMatrixState.copy(this._gizmoMatrixState0);
		this._gizmoMatrixState0.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
		this._gizmos.updateMatrix();
		this._tbRadius = this.calculateTbRadius(this.camera);
		this.makeGizmos(this._gizmos.position, this._tbRadius);
		this.camera.lookAt(this._gizmos.position);
		this.updateTbState(STATE.IDLE, false);
		this.dispatchEvent(_changeEvent);
	}

	/**
	 * Rotate the camera around an axis passing by trackball's center
	 * @param {Vector3} axis Rotation axis
	 * @param {number} angle Angle in radians
	 * @returns {Object} Object with 'camera' field containing transformation matrix resulting from the operation to be applied to the camera
	 */
	public function rotate(axis:Vector3, angle:Float):Transformation {
		var point = this._gizmos.position;
		this._translationMatrix.makeTranslation(-point.x, -point.y, -point.z);
		this._rotationMatrix.makeRotationAxis(axis, -angle);
		this._m4_1.makeTranslation(point.x, point.y, point.z);
		this._m4_1.multiply(this._rotationMatrix);
		this._m4_1.multiply(this._translationMatrix);
		this.setTransformationMatrices(this._m4_1);
		return _transformation;
	}

	public function copyState() {
		var state:String;
		if (this.camera.isOrthographicCamera) {
			state = JSON.stringify({ arcballState: {
				cameraFar: this.camera.far,
				cameraMatrix: this.camera.matrix,
				cameraNear: this.camera.near,
				cameraUp: this.camera.up,
				cameraZoom: this.camera.zoom,
				gizmoMatrix: this._gizmos.matrix
			} });
		} else if (this.camera.isPerspectiveCamera) {
			state = JSON.stringify({ arcballState: {
				cameraFar: this.camera.far,
				cameraFov: this.camera.fov,

				cameraMatrix: this.camera.matrix,
				cameraNear: this.camera.near,
				cameraUp: this.camera.up,
				cameraZoom: this.camera.zoom,
				gizmoMatrix: this._gizmos.matrix
			} });
		}
		navigator.clipboard.writeText(state);
	}

	public function pasteState() {
		var self = this;
		navigator.clipboard.readText().then(function(value:String) {
			self.setStateFromJSON(value);
		});
	}

	/**
	 * Save the current state of the control. This can later be recover with .reset
	 */
	public function saveState() {
		this._cameraMatrixState0.copy(this.camera.matrix);
		this._gizmoMatrixState0.copy(this._gizmos.matrix);
		this._nearPos = this.camera.near;
		this._farPos = this.camera.far;
		this._zoom0 = this.camera.zoom;
		this._up0.copy(this.camera.up);
		if (this.camera.isPerspectiveCamera) {
			this._fov0 = this.camera.fov;
		}
	}

	/**
	 * Perform uniform scale operation around a given point
	 * @param {Number} size Scale factor
	 * @param {Vector3} point Point around which scale
	 * @param {Boolean} scaleGizmos If gizmos should be scaled (Perspective only)
	 * @returns {Object} Object with 'camera' and 'gizmo' fields containing transformation matrices resulting from the operation to be applied to the camera and gizmos
	 */
	public function scale(size:Float, point:Vector3, scaleGizmos:Bool = true):Transformation {
		_scalePointTemp.copy(point);
		var sizeInverse = 1 / size;
		if (this.camera.isOrthographicCamera) {
			this.camera.zoom = this._zoomState;
			this.camera.zoom *= size;
			if (this.camera.zoom > this.maxZoom) {
				this.camera.zoom = this.maxZoom;
				sizeInverse = this._zoomState / this.maxZoom;
			} else if (this.camera.zoom < this.minZoom) {
				this.camera.zoom = this.minZoom;
				sizeInverse = this._zoomState / this.minZoom;
			}
			this.camera.updateProjectionMatrix();
			this._v3_1.setFromMatrixPosition(this._gizmoMatrixState);
			this._scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);
			this._translationMatrix.makeTranslation(-this._v3_1.x, -this._v3_1.y, -this._v3_1.z);
			this._m4_2.makeTranslation(this._v3_1.x, this._v3_1.y, this._v3_1.z).multiply(this._scaleMatrix);
			this._m4_2.multiply(this._translationMatrix);
			_scalePointTemp.sub(this._v3_1);
			var amount = _scalePointTemp.clone().multiplyScalar(sizeInverse);
			_scalePointTemp.sub(amount);
			this._m4_1.makeTranslation(_scalePointTemp.x, _scalePointTemp.y, _scalePointTemp.z);
			this._m4_2.premultiply(this._m4_1);
			this.setTransformationMatrices(this._m4_1, this._m4_2);
			return _transformation;
		} else if (this.camera.isPerspectiveCamera) {
			this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
			this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
			var distance = this._v3_1.distanceTo(_scalePointTemp);
			var amount = distance - (distance * sizeInverse);
			var newDistance = distance - amount;
			if (newDistance < this.minDistance) {
				sizeInverse = this.minDistance / distance;
				amount = distance - (distance * sizeInverse);
			} else if (newDistance > this.maxDistance) {
				sizeInverse = this.maxDistance / distance;
				amount = distance - (distance * sizeInverse);
			}
			_offset.copy(_scalePointTemp).sub(this._v3_1).normalize().multiplyScalar(amount);
			this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
			if (scaleGizmos) {
				var pos = this._v3_2;
				distance = pos.distanceTo(_scalePointTemp);
				amount = distance - (distance * sizeInverse);
				_offset.copy(_scalePointTemp).sub(this._v3_2).normalize().multiplyScalar(amount);
				this._translationMatrix.makeTranslation(pos.x, pos.y, pos.z);
				this._scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);
				this._m4_2.makeTranslation(_offset.x, _offset.y, _offset.z).multiply(this._translationMatrix);
				this._m4_2.multiply(this._scaleMatrix);
				this._translationMatrix.makeTranslation(-pos.x, -pos.y, -pos.z);
				this._m4_2.multiply(this._translationMatrix);
				this.setTransformationMatrices(this._m4_1, this._m4_2);
			} else {
				this.setTransformationMatrices(this._m4_1);
			}
			return _transformation;
		}
		return null;
	}

	/**
	 * Set camera fov
	 * @param {Number} value fov to be setted
	 */
	public function setFov(value:Float) {
		if (this.camera.isPerspectiveCamera) {
			this.camera.fov = MathUtils.clamp(value, this.minFov, this.maxFov);
			this.camera.updateProjectionMatrix();
		}
	}

	/**
	 * Set values in transformation object
	 * @param {Matrix4} camera Transformation to be applied to the camera
	 * @param {Matrix4} gizmos Transformation to be applied to gizmos
	 */
	public function setTransformationMatrices(camera:Matrix4 = null, gizmos:Matrix4 = null) {
		if (camera != null) {
			if (_transformation.camera != null) {
				_transformation.camera.copy(camera);
			} else {
				_transformation.camera = camera.clone();
			}
		} else {
			_transformation.camera = null;
		}
		if (gizmos != null) {
			if (_transformation.gizmos != null) {
				_transformation.gizmos.copy(gizmos);
			} else {
				_transformation.gizmos = gizmos.clone();
			}
		} else {
			_transformation.gizmos = null;
		}
	}

	/**
	 * Rotate camera around its direction axis passing by a given point by a given angle
	 * @param {Vector3} point The point where the rotation axis is passing trough
	 * @param {Number} angle Angle in radians
	 * @returns The computed transormation matix
	 */
	public function zRotate(point:Vector3, angle:Float):Transformation {
		this._rotationMatrix.makeRotationAxis(this._rotationAxis, angle);
		this._translationMatrix.makeTranslation(-point.x, -point.y, -point.z);
		this._m4_1.makeTranslation(point.x, point.y, point.z);
		this._m4_1.multiply(this._rotationMatrix);
		this._m4_1.multiply(this._translationMatrix);
		this._v3_1.setFromMatrixPosition(this._gizmoMatrixState).sub(point);
		this._v3_2.copy(this._v3_1).applyAxisAngle(this._rotationAxis, angle);
		this._v3_2.sub(this._v3_1);
		this._m4_2.makeTranslation(this._v3_2.x, this._v3_2.y, this._v3_2.z);
		this.setTransformationMatrices(this._m4_1, this._m4_2);
		return _transformation;
	}

	public function getRaycaster():Raycaster {
		return _raycaster;
	}

	/**
	 * Unproject the cursor on the 3D object surface
	 * @param {Vector2} cursor Cursor coordinates in NDC
	 * @param {Camera} camera Virtual camera
	 * @returns {Vector3} The point of intersection with the model, if exist, null otherwise
	 */
	public function unprojectOnObj(cursor:Vector2, camera:Camera):Vector3 {
		var raycaster = this.getRaycaster();
		raycaster.near = camera.near;
		raycaster.far = camera.far;
		raycaster.setFromCamera(cursor, camera);
		var intersect = raycaster.intersectObjects(this.scene.children, true);
		for (var i in 0...intersect.length) {
			if (intersect[i].object.uuid != this._gizmos.uuid && intersect[i].face != null) {
				return intersect[i].point.clone();
			}
		}
		return null;
	}

	/**
	 * Unproject the cursor on the trackball surface
	 * @param {Camera} camera The virtual camera
	 * @param {Number} cursorX Cursor horizontal coordinate on screen
	 * @param {Number} cursorY Cursor vertical coordinate on screen
	 * @param {HTMLElement} canvas The canvas where the renderer draws its output
	 * @param {number} tbRadius The trackball radius
	 * @returns {Vector3} The unprojected point on the trackball surface
	 */
	public function unprojectOnTbSurface(camera:Camera, cursorX:Float, cursorY:Float, canvas:Dynamic, tbRadius:Float):Vector3 {
		if (camera.type == "OrthographicCamera") {
			this._v2_1.copy(this.getCursorPosition(cursorX, cursorY, canvas));
			this._v3_1.set(this._v2_1.x, this._v2_1.y, 0);
			var x2 = Math.pow(this._v2_1.x, 2);
			var y2 = Math.pow(this._v2_1.y, 2);
			var r2 = Math.pow(this._tbRadius, 2);
			if (x2 + y2 <= r2 * 0.5) {
				this._v3_1.setZ(Math.sqrt(r2 - (x2 + y2)));
			} else {
				this._v3_1.setZ((r2 * 0.5) / (Math.sqrt(x2 + y2)));
			}
			return this._v3_1;
		} else if (camera.type == "PerspectiveCamera") {
			this._v2_1.copy(this.getCursorNDC(cursorX, cursorY, canvas));
			this._v3_1.set(this._v2_1.x, this._v2_1.y, -1);
			this._v3_1.applyMatrix4(camera.projectionMatrixInverse);
			var rayDir = this._v3_1.clone().normalize();
			var cameraGizmoDistance = camera.position.distanceTo(this._gizmos.position);
			var radius2 = Math.pow(tbRadius, 2);
			var h = this._v3_1.z;
			var l = Math.sqrt(Math.pow(this._v3_1.x, 2) + Math.pow(this._v3_1.y, 2));
			if (l == 0) {
				rayDir.set(this._v3_1.x, this._v3_1.y, tbRadius);
				return rayDir;
			}
			var m = h / l;
			var q = cameraGizmoDistance;
			var a = Math.pow(m, 2) + 1;
			var b = 2 * m * q;
			var c = Math.pow(q, 2) - radius2;
			var delta = Math.pow(b, 2) - (4 * a * c);
			if (delta >= 0) {
				this._v2_1.setX((-b - Math.sqrt(delta)) / (2 * a));
				this._v2_1.setY(m * this._v2_1.x + q);
				var angle = MathUtils.RAD2DEG * this._v2_1.angle();
				if (angle >= 45) {
					var rayLength = Math.sqrt(Math.pow(this._v2_1.x, 2) + Math.pow((cameraGizmoDistance - this._v2_1.y), 2));
					rayDir.multiplyScalar(rayLength);
					rayDir.z += cameraGizmoDistance;
					return rayDir;
				}
			}
			a = m;
			b = q;
			c = -radius2 * 0.5;
			delta = Math.pow(b, 2) - (4 * a * c);
			this._v2_1.setX((-b - Math.sqrt(delta)) / (2 * a));
			this._v2_1.setY(m * this._v2_1.x + q);
			var rayLength = Math.sqrt(Math.pow(this._v2_1.x, 2) + Math.pow((cameraGizmoDistance - this._v2_1.y), 2));
			rayDir.multiplyScalar(rayLength);
			rayDir.z += cameraGizmoDistance;
			return rayDir;
		}
		return null;
	}

	/**
	 * Unproject the cursor on the plane passing through the center of the trackball orthogonal to the camera
	 * @param {Camera} camera The virtual camera
	 * @param {Number} cursorX Cursor horizontal coordinate on screen
	 * @param {Number} cursorY Cursor vertical coordinate on screen
	 * @param {HTMLElement} canvas The canvas where the renderer draws its output
	 * @param {Boolean} initialDistance If initial distance between camera and gizmos should be used for calculations instead of current (Perspective only)
	 * @returns {Vector3} The unprojected point on the trackball plane
	 */
	public function unprojectOnTbPlane(camera:Camera, cursorX:Float, cursorY:Float, canvas:Dynamic, initialDistance:Bool = false):Vector3 {
		if (camera.type == "OrthographicCamera") {
			this._v2_1.copy(this.getCursorPosition(cursorX, cursorY, canvas));
			this._v3_1.set(this._v2_1.x, this._v2_1.y, 0);
			return this._v3_1.clone();
		} else if (camera.type == "PerspectiveCamera") {
			this._v2_1.copy(this.getCursorNDC(cursorX, cursorY, canvas));
			this._v3_1.set(this._v2_1.x, this._v2_1.y, -1);
			this._v3_1.applyMatrix4(camera.projectionMatrixInverse);
			var rayDir = this._v3_1.clone().normalize();
			var cameraGizmoDistance:Float;
			if (initialDistance) {
				cameraGizmoDistance = this._v3_1.setFromMatrixPosition(this._cameraMatrixState0).distanceTo(this._v3_2.setFromMatrixPosition(this._gizmoMatrixState0));
			} else {
				cameraGizmoDistance = camera.position.distanceTo(this._gizmos.position);
			}
			var h = this._v3_1.z;
			var l = Math.sqrt(Math.pow(this._v3_1.x, 2) + Math.pow(this._v3_1.y, 2));
			if (l == 0) {
				rayDir.set(0, 0, 0);
				return rayDir;
			}
			var m = h / l;
			var q = cameraGizmoDistance;
			var x = -q / m;
			var rayLength = Math.sqrt(Math.pow(q, 2) + Math.pow(x, 2));
			rayDir.multiplyScalar(rayLength);
			rayDir.z = 0;
			return rayDir;
		}
		return null;
	}

	/**
	 * Update camera and gizmos state
	 */
	public function updateMatrixState() {
		this._cameraMatrixState.copy(this.camera.matrix);
		this._gizmoMatrixState.copy(this._gizmos.matrix);
		if (this.camera.isOrthographicCamera) {
			this._cameraProjectionState.copy(this.camera.projectionMatrix);
			this.camera.updateProjectionMatrix();
			this._zoomState = this.camera.zoom;
		} else if (this.camera.isPerspectiveCamera) {
			this._fovState = this.camera.fov;
		}
	}

	/**
	 * Update the trackball FSA
	 * @param {STATE} newState New state of the FSA
	 * @param {Boolean} updateMatrices If matriices state should be updated
	 */
	public function updateTbState(newState:STATE, updateMatrices:Bool) {
		this._state = newState;
		if (updateMatrices) {
			this.updateMatrixState();
		}
	}

	public function update() {
		var EPS = 0.000001;
		if (this.target.equals(this._currentTarget) == false) {
			this._gizmos.position.copy(this.target);
			this._tbRadius = this.calculateTbRadius(this.camera);
			this.makeGizmos(this.target, this._tbRadius);
			this._currentTarget.copy(this.target);
		}
		if (this.camera.isOrthographicCamera) {
			if (this.camera.zoom > this.maxZoom || this.camera.zoom < this.minZoom) {
				var newZoom = MathUtils.clamp(this.camera.zoom, this.minZoom, this.maxZoom);
				this.applyTransformMatrix(this.scale(newZoom / this.camera.zoom, this._gizmos.position, true));
			}
		} else if (this.camera.isPerspectiveCamera) {
			var distance = this.camera.position.distanceTo(this._gizmos.position);
			if (distance > this.maxDistance + EPS || distance < this.minDistance - EPS) {
				var newDistance = MathUtils.clamp(distance, this.minDistance, this.maxDistance);
				this.applyTransformMatrix(this.scale(newDistance / distance, this._gizmos.position));
				this.updateMatrixState();
			}
			if (this.camera.fov < this.minFov || this.camera.fov > this.maxFov) {
				this.camera.fov = MathUtils.clamp(this.camera.fov, this.minFov, this.maxFov);
				this.camera.updateProjectionMatrix();
			}
			var oldRadius = this._tbRadius;
			this._tbRadius = this.calculateTbRadius(this.camera);
			if (oldRadius < this._tbRadius - EPS || oldRadius > this._tbRadius + EPS) {
				var scale = (this._gizmos.scale.x + this._gizmos.scale.y + this._gizmos.scale.z) / 3;
				var newRadius = this._tbRadius / scale;
				var curve = new EllipseCurve(0, 0, newRadius, newRadius);
				var points = curve.getPoints(this._curvePts);
				var curveGeometry = new BufferGeometry().setFromPoints(points);
				for (var gizmo in this._gizmos.children) {
					this._gizmos.children[gizmo].geometry = curveGeometry;
				}
			}
		}
		this.camera.lookAt(this._gizmos.position);
	}

	public function setStateFromJSON(json:String) {
		var state = JSON.parse(json);
		if (state.arcballState != null) {
			this._cameraMatrixState.fromArray(state.arcballState.cameraMatrix.elements);
			this._cameraMatrixState.decompose(this.camera.position, this.camera.quaternion, this.camera.scale);
			this.camera.up.copy(state.arcballState.cameraUp);
			this.camera.near = state.arcballState.cameraNear;
			this.camera.far = state.arcballState.cameraFar;
			this.camera.zoom = state.arcballState.cameraZoom;
			if (this.camera.isPerspectiveCamera) {
				this.camera.fov = state.arcballState.cameraFov;
			}
			this._gizmoMatrixState.fromArray(state.arcballState.gizmoMatrix.elements);
			this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
			this.camera.updateMatrix();
			this.camera.updateProjectionMatrix();
			this._gizmos.updateMatrix();
			this._tbRadius = this.calculateTbRadius(this.camera);
			var gizmoTmp = new Matrix4().copy(this._gizmoMatrixState0);
			this.makeGizmos(this._gizmos.position, this._tbRadius);
			this._gizmoMatrixState0.copy(gizmoTmp);
			this.camera.lookAt(this._gizmos.position);
			this.updateTbState(STATE.IDLE, false);
			this.dispatchEvent(_changeEvent);
		}
	}

}

//listeners
function onWindowResize() {
	var scale = (this._gizmos.scale.x + this._gizmos.scale.y + this._gizmos.scale.z) / 3;
	this._tbRadius = this.calculateTbRadius(this.camera);
	var newRadius = this._tbRadius / scale;
	var curve = new EllipseCurve(0, 0, newRadius, newRadius);
	var points = curve.getPoints(this._curvePts);
	var curveGeometry = new BufferGeometry().setFromPoints(points);
	for (var gizmo in this._gizmos.children) {
		this._gizmos.children[gizmo].geometry = curveGeometry;
	}
	this.dispatchEvent(_changeEvent);
}

function onContextMenu(event:Dynamic) {
	if (!this.enabled) {
		return;
	}
	for (var i in 0...this.mouseActions.length) {
		if (this.mouseActions[i].mouse == 2) {
			event.preventDefault();
			break;
		}
	}
}

function onPointerCancel() {
	this._touchStart.splice(0, this._touchStart.length);
	this._touchCurrent.splice(0, this._touchCurrent.length);
	this._input = INPUT.NONE;
}

function onPointerDown(event:Dynamic) {
	if (event.button == 0 && event.isPrimary) {
		this._downValid = true;
		this._downEvents.push(event);
		this._downStart = window.performance.now();
	} else {
		this._downValid = false;
	}
	if (event.pointerType == "touch" && this._input != INPUT.CURSOR) {
		this._touchStart.push(event);
		this._touchCurrent.push(event);
		switch (this._input) {
		case INPUT.NONE:
			this._input = INPUT.ONE_FINGER;
			this.onSinglePanStart(event, "ROTATE");
			window.addEventListener("pointermove", this._onPointerMove);
			window.addEventListener("pointerup", this._onPointerUp);
			break;
		case INPUT.ONE_FINGER:
		case INPUT.ONE_FINGER_SWITCHED:
			this._input = INPUT.TWO_FINGER;
			this.onRotateStart();
			this.onPinchStart();
			this.onDoublePanStart();
			break;
		case INPUT.TWO_FINGER:
			this._input = INPUT.MULT_FINGER;
			this.onTriplePanStart(event);
			break;
		}
	} else if (event.pointerType != "touch" && this._input == INPUT.NONE) {
		var modifier:String = null;
		if (event.ctrlKey || event.metaKey) {
			modifier = "CTRL";
		} else if (event.shiftKey) {
			modifier = "SHIFT";
		}
		this._mouseOp = this.getOpFromAction(event.button, modifier);
		if (this._mouseOp != null) {
			window.addEventListener("pointermove", this._onPointerMove);
			window.addEventListener("pointerup", this._onPointerUp);
			this._input = INPUT.CURSOR;
			this._button = event.button;
			this.onSinglePanStart(event, this._mouseOp);
		}
	}
}

function onPointerMove(event:Dynamic) {
	if (event.pointerType == "touch" && this._input != INPUT.CURSOR) {
		switch (this._input) {
		case INPUT.ONE_FINGER:
			this.updateTouchEvent(event);
			this.onSinglePanMove(event, STATE.ROTATE);
			break;
		case INPUT.ONE_FINGER_SWITCHED:
			var movement = this.calculatePointersDistance(this._touchCurrent[0], event) * this._devPxRatio;
			if (movement >= this._switchSensibility) {
				this._input = INPUT.ONE_FINGER;
				this.updateTouchEvent(event);
				this.onSinglePanStart(event, "ROTATE");
				break;
			}
			break;
		case INPUT.TWO_FINGER:
			this.updateTouchEvent(event);
			this.onRotateMove();
			this.onPinchMove();
			this.onDoublePanMove();
			break;
		case INPUT.MULT_FINGER:
			this.updateTouchEvent(event);
			this.onTriplePanMove(event);
			break;
		}
	} else if (event.pointerType != "touch" && this._input == INPUT.CURSOR) {
		var modifier:String = null;
		if (event.ctrlKey || event.metaKey) {
			modifier = "CTRL";
		} else if (event.shiftKey) {
			modifier = "SHIFT";
		}
		var mouseOpState = this.getOpStateFromAction(this._button, modifier);
		if (mouseOpState != null) {
			this.onSinglePanMove(event, mouseOpState);
		}
	}
	if (this._downValid) {
		var movement = this.calculatePointersDistance(this._downEvents[this._downEvents.length - 1], event) * this._devPxRatio;
		if (movement > this._movementThreshold) {
			this._downValid = false;
		}
	}
}

function onPointerUp(event:Dynamic) {
	if (event.pointerType == "touch" && this._input != INPUT.CURSOR) {
		var nTouch = this._touchCurrent.length;
		for (var i in 0...nTouch) {
			if (this._touchCurrent[i].pointerId == event.pointerId) {
				this._touchCurrent.splice(i, 1);
				this._touchStart.splice(i, 1);
				break;
			}
		}
		switch (this._input) {
		case INPUT.ONE_FINGER:
		case INPUT.ONE_FINGER_SWITCHED:
			window.removeEventListener("pointermove", this._onPointerMove);
			window.removeEventListener("pointerup", this._onPointerUp);
			this._input = INPUT.NONE;
			this.onSinglePanEnd();
			break;
		case INPUT.TWO_FINGER:
			this.onDoublePanEnd(event);
			this.onPinchEnd(event);
			this.onRotateEnd(event);
			this._input = INPUT.ONE_FINGER_SWITCHED;
			break;
		case INPUT.MULT_FINGER:
			if (this._touchCurrent.length == 0) {
				window.removeEventListener("pointermove", this._onPointerMove);
				window.removeEventListener("pointerup", this._onPointerUp);
				this._input = INPUT.NONE;
				this.onTriplePanEnd();
			}
			break;
		}
	} else if (event.pointerType != "touch" && this._input == INPUT.CURSOR) {
		window.removeEventListener("pointermove", this._onPointerMove);
		window.removeEventListener("pointerup", this._onPointerUp);
		this._input = INPUT.NONE;
		this.onSinglePanEnd();
		this._button = - 1;
	}
	if (event.isPrimary) {
		if (this._downValid) {
			var downTime = event.timeStamp - this._downEvents[this._downEvents.length - 1].timeStamp;
			if (downTime <= this._maxDownTime) {
				if (this._nclicks == 0) {
					this._nclicks = 1;
					this._clickStart = window.performance.now();
				} else {
					var clickInterval = event.timeStamp - this._clickStart;
					var movement = this.calculatePointersDistance(this._downEvents[1], this._downEvents[0]) * this._devPxRatio;
					if (clickInterval <= this._maxInterval && movement <= this._posThreshold) {
						this._nclicks = 0;
						this._downEvents.splice(0, this._downEvents.length);
						this.onDoubleTap(event);
					} else {
						this._nclicks = 1;
						this._downEvents.shift();
						this._clickStart = window.performance.now();
					}
				}
			} else {
				this._downValid = false;
				this._nclicks = 0;
				this._downEvents.splice(0, this._downEvents.length);
			}
		} else {
			this._nclicks = 0;
			this._downEvents.splice(0, this._downEvents.length);
		}
	}
}

function onWheel(event:Dynamic) {
	if (this.enabled && this.enableZoom) {
		var modifier:String = null;
		if (event.ctrlKey || event.metaKey) {
			modifier = "CTRL";
		} else if (event.shiftKey) {
			modifier = "SHIFT";
		}
		var mouseOp = this.getOpFromAction("WHEEL", modifier);
		if (mouseOp != null) {
			event.preventDefault();
			this.dispatchEvent(_startEvent);
			var notchDeltaY = 125;
			var sgn = event.deltaY / notchDeltaY;
			var size = 1;
			if (sgn > 0) {
				size = 1 / this.scaleFactor;
			} else if (sgn < 0) {
				size = this.scaleFactor;
			}
			switch (mouseOp) {
			case "ZOOM":
				this.updateTbState(STATE.SCALE, true);
				if (sgn > 0) {
					size = 1 / Math.pow(this.scaleFactor, sgn);
				} else if (sgn < 0) {
					size = Math.pow(this.scaleFactor, -sgn);
				}
				if (this.cursorZoom && this.enablePan) {
					var scalePoint:Vector3;
					if (this.camera.isOrthographicCamera) {
						scalePoint = this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement).applyQuaternion(this.camera.quaternion).multiplyScalar(1 / this.camera.zoom).add(this._gizmos.position);
					} else if (this.camera.isPerspectiveCamera) {
						scalePoint = this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement).applyQuaternion(this.camera.quaternion).add(this._gizmos.position);
					}
					this.applyTransformMatrix(this.scale(size, scalePoint));
				} else {
					this.applyTransformMatrix(this.scale(size, this._gizmos.position));
				}
				if (this._grid != null) {
					this.disposeGrid();
					this.drawGrid();
				}
				this.updateTbState(STATE.IDLE, false);
				this.dispatchEvent(_changeEvent);
				this.dispatchEvent(_endEvent);
				break;
			case "FOV":
				if (this.camera.isPerspectiveCamera) {
					this.updateTbState(STATE.FOV, true);
					if (event.deltaX != 0) {
						sgn = event.deltaX / notchDeltaY;
						size = 1;
						if (sgn > 0) {
							size = 1 / Math.pow(this.scaleFactor, sgn);
						} else if (sgn < 0) {
							size = Math.pow(this.scaleFactor, -sgn);
						}
					}
					this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
					var x = this._v3_1.distanceTo(this._gizmos.position);
					var xNew = x / size;
					xNew = MathUtils.clamp(xNew, this.minDistance, this.maxDistance);
					var y = x * Math.tan(MathUtils.DEG2RAD * this.camera.fov * 0.5);
					var newFov = MathUtils.RAD2DEG * (Math.atan(y / xNew) * 2);
					newFov = MathUtils.clamp(newFov, this.minFov, this.maxFov);
					var newDistance = y / Math.tan(MathUtils.DEG2RAD * (newFov / 2));
					size = x / newDistance;
					this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
					this.setFov(newFov);
					this.applyTransformMatrix(this.scale(size, this._gizmos.position, false));
				}
				if (this._grid != null) {
					this.disposeGrid();
					this.drawGrid();
				}
				this.updateTbState(STATE.
					size = x / newDistance;
					this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
					this.setFov(newFov);
					this.applyTransformMatrix(this.scale(size, this._gizmos.position, false));
				}
				if (this._grid != null) {
					this.disposeGrid();
					this.drawGrid();
				}
				this.updateTbState(STATE.IDLE, false);
				this.dispatchEvent(_changeEvent);
				this.dispatchEvent(_endEvent);
				break;
			}
		}
	}
}

export { ArcballControls };