import haxe.ui.Event;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.TouchEvent;
import haxe.ui.components.Component;
import haxe.ui.Toolkit;
import haxe.ui.backend.Backend;
import haxe.ui.backend.dom.DOMBackend;
import haxe.ui.backend.dom.DOMComponent;
import haxe.ui.backend.dom.DOMElement;
import haxe.ui.backend.dom.DOMEvent;
import haxe.ui.backend.dom.DOMEventHandler;
import haxe.ui.backend.dom.DOMMouseEventHandler;
import haxe.ui.backend.dom.DOMTouchEvent;
import haxe.ui.backend.dom.DOMTouchEventHandler;
import haxe.ui.backend.dom.DOMWheelEventHandler;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.ComponentBase;
import haxe.ui.core.EventDispatcher;
import haxe.ui.core.ICloneable;
import haxe.ui.core.IEventDispatcher;
import haxe.ui.core.IPositionable;
import haxe.ui.core.ISizeable;
import haxe.ui.core.ITransformable;
import haxe.ui.core.MeasuredSize;
import haxe.ui.core.Rectangle;
import haxe.ui.core.Size;
import haxe.ui.core.Style;
import haxe.ui.core.Transform;
import haxe.ui.core.Vector3;
import haxe.ui.core.Matrix4;
import haxe.ui.effects.Animation;
import haxe.ui.effects.AnimationType;
import haxe.ui.effects.EasingType;
import haxe.ui.effects.IEasing;
import haxe.ui.effects.InterpolationType;
import haxe.ui.effects.Tween;
import haxe.ui.focus.IFocusable;
import haxe.ui.focus.IFocusManager;
import haxe.ui.focus.FocusManager;
import haxe.ui.graphics.Color;
import haxe.ui.graphics.Graphics;
import haxe.ui.graphics.GraphicsStyle;
import haxe.ui.graphics.GraphicsTools;
import haxe.ui.graphics.LineStyle;
import haxe.ui.graphics.RectangleStyle;
import haxe.ui.graphics.Shape;
import haxe.ui.graphics.Sprite;
import haxe.ui.graphics.Text;
import haxe.ui.graphics.TextFormat;
import haxe.ui.graphics.Texture;
import haxe.ui.graphics.TextureFormat;
import haxe.ui.graphics.TextureTools;
import haxe.ui.layout.Layout;
import haxe.ui.layout.LayoutManager;
import haxe.ui.layout.Padding;
import haxe.ui.layout.SizeConstraint;
import haxe.ui.layout.Spacing;
import haxe.ui.layout.VerticalLayout;
import haxe.ui.loaders.ImageLoader;
import haxe.ui.loaders.Loader;
import haxe.ui.loaders.LoaderEvent;
import haxe.ui.loaders.SoundLoader;
import haxe.ui.loaders.TextLoader;
import haxe.ui.loaders.URLRequest;
import haxe.ui.media.Sound;
import haxe.ui.media.SoundChannel;
import haxe.ui.media.SoundTransform;
import haxe.ui.media.Video;
import haxe.ui.media.VideoEvent;
import haxe.ui.media.VideoPlayer;
import haxe.ui.misc.BitmapData;
import haxe.ui.misc.Clipboard;
import haxe.ui.misc.DisplayObject;
import haxe.ui.misc.DisplayObjectContainer;
import haxe.ui.misc.InteractiveObject;
import haxe.ui.misc.Mouse;
import haxe.ui.misc.MouseCursor;
import haxe.ui.misc.MouseState;
import haxe.ui.misc.Point;
import haxe.ui.misc.Rectangle;
import haxe.ui.misc.Stage;
import haxe.ui.misc.StageAlign;
import haxe.ui.misc.StageScaleMode;
import haxe.ui.misc.TouchEvent;
import haxe.ui.misc.TouchState;
import haxe.ui.text.TextField;
import haxe.ui.text.TextInput;
import haxe.ui.text.TextFormat;
import haxe.ui.text.TextArea;
import haxe.ui.text.TextEvent;
import haxe.ui.text.TextFormatAlign;
import haxe.ui.text.TextFormatBlock;
import haxe.ui.text.TextFormatFont;
import haxe.ui.text.TextFormatSize;
import haxe.ui.text.TextFormatWeight;
import haxe.ui.util.Console;
import haxe.ui.util.Debug;
import haxe.ui.util.EventTools;
import haxe.ui.util.Hash;
import haxe.ui.util.JSON;
import haxe.ui.util.MathTools;
import haxe.ui.util.Timer;
import haxe.ui.util.URLTools;
import haxe.ui.util.Utils;
import haxe.ui.util.XMLTools;
import haxe.ui.view.View;
import haxe.ui.view.ViewEvent;
import haxe.ui.view.ViewManager;
import haxe.ui.view.ViewTransition;
import haxe.ui.view.ViewTransitionEvent;
import haxe.ui.view.ViewTransitionType;

class TouchControls extends ComponentBase {

	public var enabled:Bool = true;
	public var enablePan:Bool = true;
	public var enableRotate:Bool = true;
	public var enableZoom:Bool = true;
	public var enableGrid:Bool = true;
	public var enableAnimations:Bool = true;
	public var enableGizmos:Bool = false;

	public var scene:Dynamic = null;
	public var camera:Dynamic = null;
	public var domElement:DOMElement = null;
	public var gizmos:Dynamic = null;
	public var scaleFactor:Float = 1.2;
	public var wMax:Float = 100;
	public var minFov:Float = 1;
	public var maxFov:Float = 179;
	public var minDistance:Float = 0.1;
	public var maxDistance:Float = 1000;
	public var _fovState:Float = 0;
	public var _cameraMatrixState:Matrix4 = new Matrix4();
	public var _gizmoMatrixState:Matrix4 = new Matrix4();
	public var _startCursorPosition:Vector3 = new Vector3();
	public var _currentCursorPosition:Vector3 = new Vector3();
	public var _touchStart:Array<TouchEvent> = [];
	public var _touchCurrent:Array<TouchEvent> = [];
	public var _startFingerDistance:Float = 0;
	public var _currentFingerDistance:Float = 0;
	public var _startFingerRotation:Float = 0;
	public var _currentFingerRotation:Float = 0;
	public var _wPrev:Float = 0;
	public var _wCurr:Float = 0;
	public var _timeCurrent:Float = 0;
	public var _timeStart:Float = -1;
	public var _animationId:Int = -1;
	public var _rotationAxis:Vector3 = new Vector3();
	public var _center:Point = new Point();
	public var _v3_1:Vector3 = new Vector3();
	public var _v3_2:Vector3 = new Vector3();
	public var _m4_1:Matrix4 = new Matrix4();
	public var _offset:Vector3 = new Vector3();
	public var _devPxRatio:Float = 1;

	public var _state:STATE = STATE.IDLE;

	public var _startEvent:Event = new Event("onStart");
	public var _endEvent:Event = new Event("onEnd");
	public var _changeEvent:Event = new Event("onChange");


	public function new(scene:Dynamic, camera:Dynamic, domElement:DOMElement, gizmos:Dynamic) {
		super();
		this.scene = scene;
		this.camera = camera;
		this.domElement = domElement;
		this.gizmos = gizmos;
		this._devPxRatio = Toolkit.backend.getPixelRatio();
		this.initializeMouseActions();
		this.domElement.addEventListener(DOMEvent.TOUCH_START, this.onTouchStart);
		this.domElement.addEventListener(DOMEvent.TOUCH_MOVE, this.onTouchMove);
		this.domElement.addEventListener(DOMEvent.TOUCH_END, this.onTouchEnd);
		this.domElement.addEventListener(DOMEvent.TOUCH_CANCEL, this.onTouchEnd);
		this.domElement.addEventListener(DOMEvent.DOUBLE_TAP, this.onDoubleTap);
		this.domElement.addEventListener(DOMEvent.MOUSE_DOWN, this.onMouseDown);
		this.domElement.addEventListener(DOMEvent.MOUSE_UP, this.onMouseUp);
		this.domElement.addEventListener(DOMEvent.MOUSE_MOVE, this.onMouseMove);
		this.domElement.addEventListener(DOMEvent.MOUSE_WHEEL, this.onMouseWheel);
		this.domElement.addEventListener(DOMEvent.MOUSE_OUT, this.onMouseOut);
		this.domElement.addEventListener(DOMEvent.MOUSE_OVER, this.onMouseOver);
	}

	public function dispose() {
		this.domElement.removeEventListener(DOMEvent.TOUCH_START, this.onTouchStart);
		this.domElement.removeEventListener(DOMEvent.TOUCH_MOVE, this.onTouchMove);
		this.domElement.removeEventListener(DOMEvent.TOUCH_END, this.onTouchEnd);
		this.domElement.removeEventListener(DOMEvent.TOUCH_CANCEL, this.onTouchEnd);
		this.domElement.removeEventListener(DOMEvent.DOUBLE_TAP, this.onDoubleTap);
		this.domElement.removeEventListener(DOMEvent.MOUSE_DOWN, this.onMouseDown);
		this.domElement.removeEventListener(DOMEvent.MOUSE_UP, this.onMouseUp);
		this.domElement.removeEventListener(DOMEvent.MOUSE_MOVE, this.onMouseMove);
		this.domElement.removeEventListener(DOMEvent.MOUSE_WHEEL, this.onMouseWheel);
		this.domElement.removeEventListener(DOMEvent.MOUSE_OUT, this.onMouseOut);
		this.domElement.removeEventListener(DOMEvent.MOUSE_OVER, this.onMouseOver);
	}

	public function onTouchStart(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchStart = event.touches;
			this._touchCurrent = event.touches;
			this.dispatchEvent(_startEvent);
			if (event.touches.length == 1) {
				this.onSinglePanStart();
			} else if (event.touches.length == 2) {
				this.onDoublePanStart();
			} else if (event.touches.length == 3) {
				this.onTriplePanStart();
			}
		}
	}

	public function onTouchMove(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchCurrent = event.touches;
			if (event.touches.length == 1) {
				this.onSinglePanMove();
			} else if (event.touches.length == 2) {
				this.onDoublePanMove();
			} else if (event.touches.length == 3) {
				this.onTriplePanMove();
			}
		}
	}

	public function onTouchEnd(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchCurrent = event.touches;
			this.dispatchEvent(_endEvent);
			if (this._state == STATE.PAN || this._state == STATE.ROTATE || this._state == STATE.SCALE) {
				this.onSinglePanEnd();
			} else if (this._state == STATE.ZROTATE) {
				this.onRotateEnd();
			}
		}
	}

	public function onMouseDown(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this.onSinglePanStart();
		}
	}

	public function onMouseUp(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_endEvent);
			this.onSinglePanEnd();
		}
	}

	public function onMouseMove(event:MouseEvent) {
		if (this.enabled) {
			if (this._state == STATE.PAN) {
				this.onSinglePanMove();
			} else if (this._state == STATE.ROTATE) {
				this.onRotateMove();
			}
		}
	}

	public function onMouseWheel(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			if (this.enableZoom) {
				this.onPinchMove();
			}
			if (this.enableGrid) {
				this.disposeGrid();
			}
			this.dispatchEvent(_endEvent);
		}
	}

	public function onMouseOver(event:MouseEvent) {
		if (this.enabled) {
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
		}
	}

	public function onMouseOut(event:MouseEvent) {
		if (this.enabled) {
			if (this._state == STATE.ROTATE) {
				this.onRotateEnd();
			}
		}
	}

	public function onSinglePanStart() {
		if (this.enabled && this.enablePan) {
			this.dispatchEvent(_startEvent);
			this.updateTbState(STATE.PAN, true);
			this.setCenter(Toolkit.backend.getMouseX(), Toolkit.backend.getMouseY());
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			this.activateGizmos(false);
		}
	}

	public function onSinglePanMove() {
		if (this.enabled && this.enablePan) {
			this.setCenter(Toolkit.backend.getMouseX(), Toolkit.backend.getMouseY());
			if (this._state != STATE.PAN) {
				this.updateTbState(STATE.PAN, true);
				this._startCursorPosition.copy(this._currentCursorPosition);
			}
			this._currentCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this.applyTransformMatrix(this.pan(this._startCursorPosition, this._currentCursorPosition, true));
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onSinglePanEnd() {
		if (this._state == STATE.ROTATE) {
			if (!this.enableRotate) {
				return;
			}
			if (this.enableAnimations) {
				//perform rotation animation
				var deltaTime = (haxe.Timer.stamp() - this._timeCurrent);
				if (deltaTime < 120) {
					var w = Math.abs((this._wPrev + this._wCurr) / 2);
					var self = this;
					this._animationId = haxe.Timer.delay(function() {
						self.updateTbState(STATE.ANIMATION_ROTATE, true);
						var rotationAxis = self.calculateRotationAxis(self._cursorPosPrev, self._cursorPosCurr);
						self.onRotationAnim(haxe.Timer.stamp(), rotationAxis, Math.min(w, self.wMax));
					}, 10);
				} else {
					//cursor has been standing still for over 120 ms since last movement
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

	public function onDoubleTap(event:DOMTouchEvent) {
		if (this.enabled && this.enablePan && this.scene != null) {
			this.dispatchEvent(_startEvent);
			this.setCenter(event.clientX, event.clientY);
			var hitP = this.unprojectOnObj(this.getCursorNDC(_center.x, _center.y, this.domElement), this.camera);
			if (hitP != null && this.enableAnimations) {
				var self = this;
				if (this._animationId != -1) {
					haxe.Timer.clearTimeout(this._animationId);
				}
				this._timeStart = -1;
				this._animationId = haxe.Timer.delay(function(t) {
					self.updateTbState(STATE.ANIMATION_FOCUS, true);
					self.onFocusAnim(t, hitP, self._cameraMatrixState, self._gizmoMatrixState);
				}, 10);
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
			this.camera.getWorldDirection(this._rotationAxis); //rotation axis
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
			var amount = MathTools.DEG2RAD * (this._startFingerRotation - this._currentFingerRotation);
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
			var minDistance = 12; //minimum distance between fingers (in css pixels)
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
			for (var i = 0; i < nFingers; i++) {
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
			for (var i = 0; i < nFingers; i++) {
				clientX += this._touchCurrent[i].clientX;
				clientY += this._touchCurrent[i].clientY;
			}
			this.setCenter(clientX / nFingers, clientY / nFingers);
			var screenNotches = 8;	//how many wheel notches corresponds to a full screen pan
			this._currentCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
			var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
			var size = 1;
			if (movement < 0) {
				size = 1 / (Math.pow(this.scaleFactor, -movement * screenNotches));
			} else if (movement > 0) {
				size = Math.pow(this.scaleFactor, movement * screenNotches);
			}
			this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
			var x = this._v3_1.distanceTo(this._gizmos.position);
			var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed
			//check min and max distance
			xNew = MathTools.clamp(xNew, this.minDistance, this.maxDistance);
			var y = x * Math.tan(MathTools.DEG2RAD * this._fovState * 0.5);
			//calculate new fov
			var newFov = MathTools.RAD2DEG * (Math.atan(y / xNew) * 2);
			//check min and max fov
			newFov = MathTools.clamp(newFov, this.minFov, this.maxFov);
			var newDistance = y / Math.tan(MathTools.DEG2RAD * (newFov / 2));
			size = x / newDistance;
			this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
			this.setFov(newFov);
			this.applyTransformMatrix(this.scale(size, this._v3_2, false));
			//adjusting distance
			_offset.copy(this._gizmos.position).sub(this.camera.position).normalize().multiplyScalar(newDistance / x);
			this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onTriplePanEnd() {
		this.updateTbState(STATE.IDLE, false);
		this.dispatchEvent(_endEvent);
	}

	public function setCenter(clientX:Float, clientY:Float) {
		_center.x = clientX;
		_center.y = clientY;
	}

	public function setFov(fov:Float) {
		this._fovState = fov;
		this.camera.fov = fov;
		this.camera.updateProjectionMatrix();
	}

	public function initializeMouseActions() {
		this.setMouseAction("PAN", 0, "CTRL");
		this.setMouseAction("PAN", 2);
		this.setMouseAction("ROTATE", 0);
		this.setMouseAction("ZOOM", "WHEEL");
		this.setMouseAction("ZOOM", 1);
		this.setMouseAction("FOV", "WHEEL", "SHIFT");
		this.setMouseAction("FOV", 1, "SHIFT");
	}

	public function compareMouseAction(action1:MouseAction, action2:MouseAction):Bool {
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

	public function setMouseAction(operation:String, mouse:Int = -1, key:String = null) {
		var mouseAction = new MouseAction(operation, mouse, key);
		this._mouseActions.push(mouseAction);
	}

	public function activateGizmos(active:Bool) {
		if (active && this.enableGizmos) {
			this.gizmos.visible = true;
		} else {
			this.gizmos.visible = false;
		}
	}

	public function disposeGrid() {
		if (this.enableGrid) {
			this.scene.remove(this._grid);
			this._grid = null;
		}
	}

	public function updateTbState(newState:STATE, active:Bool) {
		if (active) {
			this._state = newState;
		} else {
			if (this._state == newState) {
				this._state = STATE.IDLE;
			}
		}
	}

	public function getAngle(p1:TouchEvent, p2:TouchEvent):Float {
		return Math.atan2(p2.clientY - p1.clientY, p2.clientX - p1.clientX);
	}

	public function calculatePointersDistance(p1:TouchEvent, p2:TouchEvent):Float {
		return Math.sqrt(Math.pow(p2.clientX - p1.clientX, 2) + Math.pow(p2.clientY - p1.clientY, 2));
	}

	public function getCursorNDC(x:Float, y:Float, domElement:DOMElement):Vector3 {
		return new Vector3((x / domElement.width) * 2 - 1, -(y / domElement.height) * 2 + 1, 0.5);
	}

	public function unprojectOnObj(ndc:Vector3, camera:Dynamic):Vector3 {
		var invMatrix = new Matrix4().getInverse(camera.matrixWorld);
		var vector = ndc.applyMatrix4(invMatrix);
		return vector;
	}

	public function unprojectOnTbPlane(camera:Dynamic, x:Float, y:Float, domElement:DOMElement, world:Bool = false):Vector3 {
		var ndc = this.getCursorNDC(x, y, domElement);
		var vector = new Vector3();
		var invMatrix = new Matrix4();
		if (world) {
			invMatrix = new Matrix4().getInverse(camera.matrixWorld);
		} else {
			invMatrix = new Matrix4().getInverse(camera.matrix);
		}
		vector.applyMatrix4(invMatrix);
		return vector;
	}

	public function applyTransformMatrix(matrix:Matrix4) {
		this._cameraMatrixState.multiplyMatrices(matrix, this._cameraMatrixState);
		this.camera.matrix.copy(this._cameraMatrixState);
		this.camera.updateProjectionMatrix();
		this._gizmoMatrixState.multiplyMatrices(matrix, this._gizmoMatrixState);
		this.gizmos.matrix.copy(this._gizmoMatrixState);
	}

	public function pan(start:Vector3, end:Vector3, world:Bool = false):Matrix4 {
		var v3 = end.sub(start);
		var m4 = new Matrix4();
		if (world) {
			m4.makeTranslation(-v3.x, -v3.y, -v3.z);
		} else {
			m4.makeTranslation(v3.x, v3.y, v3.z);
		}
		return m4;
	}

	public function scale(amount:Float, scalePoint:Vector3, world:Bool = true):Matrix4 {
		var m4 = new Matrix4();
		if (world) {
			m4.makeTranslation(scalePoint.x, scalePoint.y, scalePoint.z);
			m4.scale(new Vector3(amount, amount, amount));
			m4.makeTranslation(-scalePoint.x, -scalePoint.y, -scalePoint.z);
		} else {
			m4.makeTranslation(-scalePoint.x, -scalePoint.y, -scalePoint.z);
			m4.scale(new Vector3(amount, amount, amount));
			m4.makeTranslation(scalePoint.x, scalePoint.y, scalePoint.z);
		}
		return m4;
	}

	public function zRotate(rotationPoint:Vector3, amount:Float):Matrix4 {
		var m4 = new Matrix4();
		m4.makeTranslation(rotationPoint.x, rotationPoint.y, rotationPoint.z);
		m4.makeRotationAxis(this._rotationAxis, amount);
		m4.makeTranslation(-rotationPoint.x, -rotationPoint.y, -rotationPoint.z);
		return m4;
	}

	public
import haxe.ui.Event;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.TouchEvent;
import haxe.ui.components.Component;
import haxe.ui.Toolkit;
import haxe.ui.backend.Backend;
import haxe.ui.backend.dom.DOMBackend;
import haxe.ui.backend.dom.DOMComponent;
import haxe.ui.backend.dom.DOMElement;
import haxe.ui.backend.dom.DOMEvent;
import haxe.ui.backend.dom.DOMEventHandler;
import haxe.ui.backend.dom.DOMMouseEventHandler;
import haxe.ui.backend.dom.DOMTouchEvent;
import haxe.ui.backend.dom.DOMTouchEventHandler;
import haxe.ui.backend.dom.DOMWheelEventHandler;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.ComponentBase;
import haxe.ui.core.EventDispatcher;
import haxe.ui.core.ICloneable;
import haxe.ui.core.IEventDispatcher;
import haxe.ui.core.IPositionable;
import haxe.ui.core.ISizeable;
import haxe.ui.core.ITransformable;
import haxe.ui.core.MeasuredSize;
import haxe.ui.core.Rectangle;
import haxe.ui.core.Size;
import haxe.ui.core.Style;
import haxe.ui.core.Transform;
import haxe.ui.core.Vector3;
import haxe.ui.core.Matrix4;
import haxe.ui.effects.Animation;
import haxe.ui.effects.AnimationType;
import haxe.ui.effects.EasingType;
import haxe.ui.effects.IEasing;
import haxe.ui.effects.InterpolationType;
import haxe.ui.effects.Tween;
import haxe.ui.focus.IFocusable;
import haxe.ui.focus.IFocusManager;
import haxe.ui.focus.FocusManager;
import haxe.ui.graphics.Color;
import haxe.ui.graphics.Graphics;
import haxe.ui.graphics.GraphicsStyle;
import haxe.ui.graphics.GraphicsTools;
import haxe.ui.graphics.LineStyle;
import haxe.ui.graphics.RectangleStyle;
import haxe.ui.graphics.Shape;
import haxe.ui.graphics.Sprite;
import haxe.ui.graphics.Text;
import haxe.ui.graphics.TextFormat;
import haxe.ui.graphics.Texture;
import haxe.ui.graphics.TextureFormat;
import haxe.ui.graphics.TextureTools;
import haxe.ui.layout.Layout;
import haxe.ui.layout.LayoutManager;
import haxe.ui.layout.Padding;
import haxe.ui.layout.SizeConstraint;
import haxe.ui.layout.Spacing;
import haxe.ui.layout.VerticalLayout;
import haxe.ui.loaders.ImageLoader;
import haxe.ui.loaders.Loader;
import haxe.ui.loaders.LoaderEvent;
import haxe.ui.loaders.SoundLoader;
import haxe.ui.loaders.TextLoader;
import haxe.ui.loaders.URLRequest;
import haxe.ui.media.Sound;
import haxe.ui.media.SoundChannel;
import haxe.ui.media.SoundTransform;
import haxe.ui.media.Video;
import haxe.ui.media.VideoEvent;
import haxe.ui.media.VideoPlayer;
import haxe.ui.misc.BitmapData;
import haxe.ui.misc.Clipboard;
import haxe.ui.misc.DisplayObject;
import haxe.ui.misc.DisplayObjectContainer;
import haxe.ui.misc.InteractiveObject;
import haxe.ui.misc.Mouse;
import haxe.ui.misc.MouseCursor;
import haxe.ui.misc.MouseState;
import haxe.ui.misc.Point;
import haxe.ui.misc.Rectangle;
import haxe.ui.misc.Stage;
import haxe.ui.misc.StageAlign;
import haxe.ui.misc.StageScaleMode;
import haxe.ui.misc.TouchEvent;
import haxe.ui.misc.TouchState;
import haxe.ui.text.TextField;
import haxe.ui.text.TextInput;
import haxe.ui.text.TextFormat;
import haxe.ui.text.TextArea;
import haxe.ui.text.TextEvent;
import haxe.ui.text.TextFormatAlign;
import haxe.ui.text.TextFormatBlock;
import haxe.ui.text.TextFormatFont;
import haxe.ui.text.TextFormatSize;
import haxe.ui.text.TextFormatWeight;
import haxe.ui.util.Console;
import haxe.ui.util.Debug;
import haxe.ui.util.EventTools;
import haxe.ui.util.Hash;
import haxe.ui.util.JSON;
import haxe.ui.util.MathTools;
import haxe.ui.util.Timer;
import haxe.ui.util.URLTools;
import haxe.ui.util.Utils;
import haxe.ui.util.XMLTools;
import haxe.ui.view.View;
import haxe.ui.view.ViewEvent;
import haxe.ui.view.ViewManager;
import haxe.ui.view.ViewTransition;
import haxe.ui.view.ViewTransitionEvent;
import haxe.ui.view.ViewTransitionType;

class TouchControls extends ComponentBase {

	public var enabled:Bool = true;
	public var enablePan:Bool = true;
	public var enableRotate:Bool = true;
	public var enableZoom:Bool = true;
	public var enableGrid:Bool = true;
	public var enableAnimations:Bool = true;
	public var enableGizmos:Bool = false;

	public var scene:Dynamic = null;
	public var camera:Dynamic = null;
	public var domElement:DOMElement = null;
	public var gizmos:Dynamic = null;
	public var scaleFactor:Float = 1.2;
	public var wMax:Float = 100;
	public var minFov:Float = 1;
	public var maxFov:Float = 179;
	public var minDistance:Float = 0.1;
	public var maxDistance:Float = 1000;
	public var _fovState:Float = 0;
	public var _cameraMatrixState:Matrix4 = new Matrix4();
	public var _gizmoMatrixState:Matrix4 = new Matrix4();
	public var _startCursorPosition:Vector3 = new Vector3();
	public var _currentCursorPosition:Vector3 = new Vector3();
	public var _touchStart:Array<TouchEvent> = [];
	public var _touchCurrent:Array<TouchEvent> = [];
	public var _startFingerDistance:Float = 0;
	public var _currentFingerDistance:Float = 0;
	public var _startFingerRotation:Float = 0;
	public var _currentFingerRotation:Float = 0;
	public var _wPrev:Float = 0;
	public var _wCurr:Float = 0;
	public var _timeCurrent:Float = 0;
	public var _timeStart:Float = -1;
	public var _animationId:Int = -1;
	public var _rotationAxis:Vector3 = new Vector3();
	public var _center:Point = new Point();
	public var _v3_1:Vector3 = new Vector3();
	public var _v3_2:Vector3 = new Vector3();
	public var _m4_1:Matrix4 = new Matrix4();
	public var _offset:Vector3 = new Vector3();
	public var _devPxRatio:Float = 1;

	public var _state:STATE = STATE.IDLE;

	public var _startEvent:Event = new Event("onStart");
	public var _endEvent:Event = new Event("onEnd");
	public var _changeEvent:Event = new Event("onChange");


	public function new(scene:Dynamic, camera:Dynamic, domElement:DOMElement, gizmos:Dynamic) {
		super();
		this.scene = scene;
		this.camera = camera;
		this.domElement = domElement;
		this.gizmos = gizmos;
		this._devPxRatio = Toolkit.backend.getPixelRatio();
		this.initializeMouseActions();
		this.domElement.addEventListener(DOMEvent.TOUCH_START, this.onTouchStart);
		this.domElement.addEventListener(DOMEvent.TOUCH_MOVE, this.onTouchMove);
		this.domElement.addEventListener(DOMEvent.TOUCH_END, this.onTouchEnd);
		this.domElement.addEventListener(DOMEvent.TOUCH_CANCEL, this.onTouchEnd);
		this.domElement.addEventListener(DOMEvent.DOUBLE_TAP, this.onDoubleTap);
		this.domElement.addEventListener(DOMEvent.MOUSE_DOWN, this.onMouseDown);
		this.domElement.addEventListener(DOMEvent.MOUSE_UP, this.onMouseUp);
		this.domElement.addEventListener(DOMEvent.MOUSE_MOVE, this.onMouseMove);
		this.domElement.addEventListener(DOMEvent.MOUSE_WHEEL, this.onMouseWheel);
		this.domElement.addEventListener(DOMEvent.MOUSE_OUT, this.onMouseOut);
		this.domElement.addEventListener(DOMEvent.MOUSE_OVER, this.onMouseOver);
	}

	public function dispose() {
		this.domElement.removeEventListener(DOMEvent.TOUCH_START, this.onTouchStart);
		this.domElement.removeEventListener(DOMEvent.TOUCH_MOVE, this.onTouchMove);
		this.domElement.removeEventListener(DOMEvent.TOUCH_END, this.onTouchEnd);
		this.domElement.removeEventListener(DOMEvent.TOUCH_CANCEL, this.onTouchEnd);
		this.domElement.removeEventListener(DOMEvent.DOUBLE_TAP, this.onDoubleTap);
		this.domElement.removeEventListener(DOMEvent.MOUSE_DOWN, this.onMouseDown);
		this.domElement.removeEventListener(DOMEvent.MOUSE_UP, this.onMouseUp);
		this.domElement.removeEventListener(DOMEvent.MOUSE_MOVE, this.onMouseMove);
		this.domElement.removeEventListener(DOMEvent.MOUSE_WHEEL, this.onMouseWheel);
		this.domElement.removeEventListener(DOMEvent.MOUSE_OUT, this.onMouseOut);
		this.domElement.removeEventListener(DOMEvent.MOUSE_OVER, this.onMouseOver);
	}

	public function onTouchStart(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchStart = event.touches;
			this._touchCurrent = event.touches;
			this.dispatchEvent(_startEvent);
			if (event.touches.length == 1) {
				this.onSinglePanStart();
			} else if (event.touches.length == 2) {
				this.onDoublePanStart();
			} else if (event.touches.length == 3) {
				this.onTriplePanStart();
			}
		}
	}

	public function onTouchMove(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchCurrent = event.touches;
			if (event.touches.length == 1) {
				this.onSinglePanMove();
			} else if (event.touches.length == 2) {
				this.onDoublePanMove();
			} else if (event.touches.length == 3) {
				this.onTriplePanMove();
			}
		}
	}

	public function onTouchEnd(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchCurrent = event.touches;
			this.dispatchEvent(_endEvent);
			if (this._state == STATE.PAN || this._state == STATE.ROTATE || this._state == STATE.SCALE) {
				this.onSinglePanEnd();
			} else if (this._state == STATE.ZROTATE) {
				this.onRotateEnd();
			}
		}
	}

	public function onMouseDown(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this.onSinglePanStart();
		}
	}

	public function onMouseUp(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_endEvent);
			this.onSinglePanEnd();
		}
	}

	public function onMouseMove(event:MouseEvent) {
		if (this.enabled) {
			if (this._state == STATE.PAN) {
				this.onSinglePanMove();
			} else if (this._state == STATE.ROTATE) {
				this.onRotateMove();
			}
		}
	}

	public function onMouseWheel(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			if (this.enableZoom) {
				this.onPinchMove();
			}
			if (this.enableGrid) {
				this.disposeGrid();
			}
			this.dispatchEvent(_endEvent);
		}
	}

	public function onMouseOver(event:MouseEvent) {
		if (this.enabled) {
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
		}
	}

	public function onMouseOut(event:MouseEvent) {
		if (this.enabled) {
			if (this._state == STATE.ROTATE) {
				this.onRotateEnd();
			}
		}
	}

	public function onSinglePanStart() {
		if (this.enabled && this.enablePan) {
			this.dispatchEvent(_startEvent);
			this.updateTbState(STATE.PAN, true);
			this.setCenter(Toolkit.backend.getMouseX(), Toolkit.backend.getMouseY());
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			this.activateGizmos(false);
		}
	}

	public function onSinglePanMove() {
		if (this.enabled && this.enablePan) {
			this.setCenter(Toolkit.backend.getMouseX(), Toolkit.backend.getMouseY());
			if (this._state != STATE.PAN) {
				this.updateTbState(STATE.PAN, true);
				this._startCursorPosition.copy(this._currentCursorPosition);
			}
			this._currentCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this.applyTransformMatrix(this.pan(this._startCursorPosition, this._currentCursorPosition, true));
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onSinglePanEnd() {
		if (this._state == STATE.ROTATE) {
			if (!this.enableRotate) {
				return;
			}
			if (this.enableAnimations) {
				//perform rotation animation
				var deltaTime = (haxe.Timer.stamp() - this._timeCurrent);
				if (deltaTime < 120) {
					var w = Math.abs((this._wPrev + this._wCurr) / 2);
					var self = this;
					this._animationId = haxe.Timer.delay(function() {
						self.updateTbState(STATE.ANIMATION_ROTATE, true);
						var rotationAxis = self.calculateRotationAxis(self._cursorPosPrev, self._cursorPosCurr);
						self.onRotationAnim(haxe.Timer.stamp(), rotationAxis, Math.min(w, self.wMax));
					}, 10);
				} else {
					//cursor has been standing still for over 120 ms since last movement
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

	public function onDoubleTap(event:DOMTouchEvent) {
		if (this.enabled && this.enablePan && this.scene != null) {
			this.dispatchEvent(_startEvent);
			this.setCenter(event.clientX, event.clientY);
			var hitP = this.unprojectOnObj(this.getCursorNDC(_center.x, _center.y, this.domElement), this.camera);
			if (hitP != null && this.enableAnimations) {
				var self = this;
				if (this._animationId != -1) {
					haxe.Timer.clearTimeout(this._animationId);
				}
				this._timeStart = -1;
				this._animationId = haxe.Timer.delay(function(t) {
					self.updateTbState(STATE.ANIMATION_FOCUS, true);
					self.onFocusAnim(t, hitP, self._cameraMatrixState, self._gizmoMatrixState);
				}, 10);
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
			this.camera.getWorldDirection(this._rotationAxis); //rotation axis
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
			var amount = MathTools.DEG2RAD * (this._startFingerRotation - this._currentFingerRotation);
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
			var minDistance = 12; //minimum distance between fingers (in css pixels)
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
			for (var i = 0; i < nFingers; i++) {
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
			for (var i = 0; i < nFingers; i++) {
				clientX += this._touchCurrent[i].clientX;
				clientY += this._touchCurrent[i].clientY;
			}
			this.setCenter(clientX / nFingers, clientY / nFingers);
			var screenNotches = 8;	//how many wheel notches corresponds to a full screen pan
			this._currentCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
			var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
			var size = 1;
			if (movement < 0) {
				size = 1 / (Math.pow(this.scaleFactor, -movement * screenNotches));
			} else if (movement > 0) {
				size = Math.pow(this.scaleFactor, movement * screenNotches);
			}
			this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
			var x = this._v3_1.distanceTo(this._gizmos.position);
			var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed
			//check min and max distance
			xNew = MathTools.clamp(xNew, this.minDistance, this.maxDistance);
			var y = x * Math.tan(MathTools.DEG2RAD * this._fovState * 0.5);
			//calculate new fov
			var newFov = MathTools.RAD2DEG * (Math.atan(y / xNew) * 2);
			//check min and max fov
			newFov = MathTools.clamp(newFov, this.minFov, this.maxFov);
			var newDistance = y / Math.tan(MathTools.DEG2RAD * (newFov / 2));
			size = x / newDistance;
			this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
			this.setFov(newFov);
			this.applyTransformMatrix(this.scale(size, this._v3_2, false));
			//adjusting distance
			_offset.copy(this._gizmos.position).sub(this.camera.position).normalize().multiplyScalar(newDistance / x);
			this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onTriplePanEnd() {
		this.updateTbState(STATE.IDLE, false);
		this.dispatchEvent(_endEvent);
	}

	public function setCenter(clientX:Float, clientY:Float) {
		_center.x = clientX;
		_center.y = clientY;
	}

	public function setFov(fov:Float) {
		this._fovState = fov;
		this.camera.fov = fov;
		this.camera.updateProjectionMatrix();
	}

	public function initializeMouseActions() {
		this.setMouseAction("PAN", 0, "CTRL");
		this.setMouseAction("PAN", 2);
		this.setMouseAction("ROTATE", 0);
		this.setMouseAction("ZOOM", "WHEEL");
		this.setMouseAction("ZOOM", 1);
		this.setMouseAction("FOV", "WHEEL", "SHIFT");
		this.setMouseAction("FOV", 1, "SHIFT");
	}

	public function compareMouseAction(action1:MouseAction, action2:MouseAction):Bool {
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

	public function setMouseAction(operation:String, mouse:Int = -1, key:String = null) {
		var mouseAction = new MouseAction(operation, mouse, key);
		this._mouseActions.push(mouseAction);
	}

	public function activateGizmos(active:Bool) {
		if (active && this.enableGizmos) {
			this.gizmos.visible = true;
		} else {
			this.gizmos.visible = false;
		}
	}

	public function disposeGrid() {
		if (this.enableGrid) {
			this.scene.remove(this._grid);
			this._grid = null;
		}
	}

	public function updateTbState(newState:STATE, active:Bool) {
		if (active) {
			this._state = newState;
		} else {
			if (this._state == newState) {
				this._state = STATE.IDLE;
			}
		}
	}

	public function getAngle(p1:TouchEvent, p2:TouchEvent):Float {
		return Math.atan2(p2.clientY - p1.clientY, p2.clientX - p1.clientX);
	}

	public function calculatePointersDistance(p1:TouchEvent, p2:TouchEvent):Float {
		return Math.sqrt(Math.pow(p2.clientX - p1.clientX, 2) + Math.pow(p2.clientY - p1.clientY, 2));
	}

	public function getCursorNDC(x:Float, y:Float, domElement:DOMElement):Vector3 {
		return new Vector3((x / domElement.width) * 2 - 1, -(y / domElement.height) * 2 + 1, 0.5);
	}

	public function unprojectOnObj(ndc:Vector3, camera:Dynamic):Vector3 {
		var invMatrix = new Matrix4().getInverse(camera.matrixWorld);
		var vector = ndc.applyMatrix4(invMatrix);
		return vector;
	}

	public function unprojectOnTbPlane(camera:Dynamic, x:Float, y:Float, domElement:DOMElement, world:Bool = false):Vector3 {
		var ndc = this.getCursorNDC(x, y, domElement);
		var vector = new Vector3();
		var invMatrix = new Matrix4();
		if (world) {
			invMatrix = new Matrix4().getInverse(camera.matrixWorld);
		} else {
			invMatrix = new Matrix4().getInverse(camera.matrix);
		}
		vector.applyMatrix4(invMatrix);
		return vector;
	}

	public function applyTransformMatrix(matrix:Matrix4) {
		this._cameraMatrixState.multiplyMatrices(matrix, this._cameraMatrixState);
		this.camera.matrix.copy(this._cameraMatrixState);
		this.camera.updateProjectionMatrix();
		this._gizmoMatrixState.multiplyMatrices(matrix, this._gizmoMatrixState);
		this.gizmos.matrix.copy(this._gizmoMatrixState);
	}

	public function pan(start:Vector3, end:Vector3, world:Bool = false):Matrix4 {
		var v3 = end.sub(start);
		var m4 = new Matrix4();
		if (world) {
			m4.makeTranslation(-v3.x, -v3.y, -v3.z);
		} else {
			m4.makeTranslation(v3.x, v3.y, v3.z);
		}
		return m4;
	}

	public function scale(amount:Float, scalePoint:Vector3, world:Bool = true):Matrix4 {
		var m4 = new Matrix4();
		if (world) {
			m4.makeTranslation(scalePoint.x, scalePoint.y, scalePoint.z);
			m4.scale(new Vector3(amount, amount, amount));
			m4.makeTranslation(-scalePoint.x, -scalePoint.y, -scalePoint.z);
		} else {
			m4.makeTranslation(-scalePoint.x, -scalePoint.y, -scalePoint.z);
			m4.scale(new Vector3(amount, amount, amount));
			m4.makeTranslation(scalePoint.x, scalePoint.y, scalePoint.z);
		}
		return m4;
	}

	public function zRotate(rotationPoint:Vector3, amount:Float):Matrix4 {
		var m4 = new Matrix4();
		m4.makeTranslation(rotationPoint.x, rotationPoint.y, rotationPoint.z);
		m4.makeRotationAxis(this._rotationAxis, amount);
		m4.makeTranslation(-rotationPoint.x, -rotationPoint.y, -rotationPoint.z);
		return m4;
	}

	public
import haxe.ui.Event;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.TouchEvent;
import haxe.ui.components.Component;
import haxe.ui.Toolkit;
import haxe.ui.backend.Backend;
import haxe.ui.backend.dom.DOMBackend;
import haxe.ui.backend.dom.DOMComponent;
import haxe.ui.backend.dom.DOMElement;
import haxe.ui.backend.dom.DOMEvent;
import haxe.ui.backend.dom.DOMEventHandler;
import haxe.ui.backend.dom.DOMMouseEventHandler;
import haxe.ui.backend.dom.DOMTouchEvent;
import haxe.ui.backend.dom.DOMTouchEventHandler;
import haxe.ui.backend.dom.DOMWheelEventHandler;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.ComponentBase;
import haxe.ui.core.EventDispatcher;
import haxe.ui.core.ICloneable;
import haxe.ui.core.IEventDispatcher;
import haxe.ui.core.IPositionable;
import haxe.ui.core.ISizeable;
import haxe.ui.core.ITransformable;
import haxe.ui.core.MeasuredSize;
import haxe.ui.core.Rectangle;
import haxe.ui.core.Size;
import haxe.ui.core.Style;
import haxe.ui.core.Transform;
import haxe.ui.core.Vector3;
import haxe.ui.core.Matrix4;
import haxe.ui.effects.Animation;
import haxe.ui.effects.AnimationType;
import haxe.ui.effects.EasingType;
import haxe.ui.effects.IEasing;
import haxe.ui.effects.InterpolationType;
import haxe.ui.effects.Tween;
import haxe.ui.focus.IFocusable;
import haxe.ui.focus.IFocusManager;
import haxe.ui.focus.FocusManager;
import haxe.ui.graphics.Color;
import haxe.ui.graphics.Graphics;
import haxe.ui.graphics.GraphicsStyle;
import haxe.ui.graphics.GraphicsTools;
import haxe.ui.graphics.LineStyle;
import haxe.ui.graphics.RectangleStyle;
import haxe.ui.graphics.Shape;
import haxe.ui.graphics.Sprite;
import haxe.ui.graphics.Text;
import haxe.ui.graphics.TextFormat;
import haxe.ui.graphics.Texture;
import haxe.ui.graphics.TextureFormat;
import haxe.ui.graphics.TextureTools;
import haxe.ui.layout.Layout;
import haxe.ui.layout.LayoutManager;
import haxe.ui.layout.Padding;
import haxe.ui.layout.SizeConstraint;
import haxe.ui.layout.Spacing;
import haxe.ui.layout.VerticalLayout;
import haxe.ui.loaders.ImageLoader;
import haxe.ui.loaders.Loader;
import haxe.ui.loaders.LoaderEvent;
import haxe.ui.loaders.SoundLoader;
import haxe.ui.loaders.TextLoader;
import haxe.ui.loaders.URLRequest;
import haxe.ui.media.Sound;
import haxe.ui.media.SoundChannel;
import haxe.ui.media.SoundTransform;
import haxe.ui.media.Video;
import haxe.ui.media.VideoEvent;
import haxe.ui.media.VideoPlayer;
import haxe.ui.misc.BitmapData;
import haxe.ui.misc.Clipboard;
import haxe.ui.misc.DisplayObject;
import haxe.ui.misc.DisplayObjectContainer;
import haxe.ui.misc.InteractiveObject;
import haxe.ui.misc.Mouse;
import haxe.ui.misc.MouseCursor;
import haxe.ui.misc.MouseState;
import haxe.ui.misc.Point;
import haxe.ui.misc.Rectangle;
import haxe.ui.misc.Stage;
import haxe.ui.misc.StageAlign;
import haxe.ui.misc.StageScaleMode;
import haxe.ui.misc.TouchEvent;
import haxe.ui.misc.TouchState;
import haxe.ui.text.TextField;
import haxe.ui.text.TextInput;
import haxe.ui.text.TextFormat;
import haxe.ui.text.TextArea;
import haxe.ui.text.TextEvent;
import haxe.ui.text.TextFormatAlign;
import haxe.ui.text.TextFormatBlock;
import haxe.ui.text.TextFormatFont;
import haxe.ui.text.TextFormatSize;
import haxe.ui.text.TextFormatWeight;
import haxe.ui.util.Console;
import haxe.ui.util.Debug;
import haxe.ui.util.EventTools;
import haxe.ui.util.Hash;
import haxe.ui.util.JSON;
import haxe.ui.util.MathTools;
import haxe.ui.util.Timer;
import haxe.ui.util.URLTools;
import haxe.ui.util.Utils;
import haxe.ui.util.XMLTools;
import haxe.ui.view.View;
import haxe.ui.view.ViewEvent;
import haxe.ui.view.ViewManager;
import haxe.ui.view.ViewTransition;
import haxe.ui.view.ViewTransitionEvent;
import haxe.ui.view.ViewTransitionType;

class TouchControls extends ComponentBase {

	public var enabled:Bool = true;
	public var enablePan:Bool = true;
	public var enableRotate:Bool = true;
	public var enableZoom:Bool = true;
	public var enableGrid:Bool = true;
	public var enableAnimations:Bool = true;
	public var enableGizmos:Bool = false;

	public var scene:Dynamic = null;
	public var camera:Dynamic = null;
	public var domElement:DOMElement = null;
	public var gizmos:Dynamic = null;
	public var scaleFactor:Float = 1.2;
	public var wMax:Float = 100;
	public var minFov:Float = 1;
	public var maxFov:Float = 179;
	public var minDistance:Float = 0.1;
	public var maxDistance:Float = 1000;
	public var _fovState:Float = 0;
	public var _cameraMatrixState:Matrix4 = new Matrix4();
	public var _gizmoMatrixState:Matrix4 = new Matrix4();
	public var _startCursorPosition:Vector3 = new Vector3();
	public var _currentCursorPosition:Vector3 = new Vector3();
	public var _touchStart:Array<TouchEvent> = [];
	public var _touchCurrent:Array<TouchEvent> = [];
	public var _startFingerDistance:Float = 0;
	public var _currentFingerDistance:Float = 0;
	public var _startFingerRotation:Float = 0;
	public var _currentFingerRotation:Float = 0;
	public var _wPrev:Float = 0;
	public var _wCurr:Float = 0;
	public var _timeCurrent:Float = 0;
	public var _timeStart:Float = -1;
	public var _animationId:Int = -1;
	public var _rotationAxis:Vector3 = new Vector3();
	public var _center:Point = new Point();
	public var _v3_1:Vector3 = new Vector3();
	public var _v3_2:Vector3 = new Vector3();
	public var _m4_1:Matrix4 = new Matrix4();
	public var _offset:Vector3 = new Vector3();
	public var _devPxRatio:Float = 1;

	public var _state:STATE = STATE.IDLE;

	public var _startEvent:Event = new Event("onStart");
	public var _endEvent:Event = new Event("onEnd");
	public var _changeEvent:Event = new Event("onChange");


	public function new(scene:Dynamic, camera:Dynamic, domElement:DOMElement, gizmos:Dynamic) {
		super();
		this.scene = scene;
		this.camera = camera;
		this.domElement = domElement;
		this.gizmos = gizmos;
		this._devPxRatio = Toolkit.backend.getPixelRatio();
		this.initializeMouseActions();
		this.domElement.addEventListener(DOMEvent.TOUCH_START, this.onTouchStart);
		this.domElement.addEventListener(DOMEvent.TOUCH_MOVE, this.onTouchMove);
		this.domElement.addEventListener(DOMEvent.TOUCH_END, this.onTouchEnd);
		this.domElement.addEventListener(DOMEvent.TOUCH_CANCEL, this.onTouchEnd);
		this.domElement.addEventListener(DOMEvent.DOUBLE_TAP, this.onDoubleTap);
		this.domElement.addEventListener(DOMEvent.MOUSE_DOWN, this.onMouseDown);
		this.domElement.addEventListener(DOMEvent.MOUSE_UP, this.onMouseUp);
		this.domElement.addEventListener(DOMEvent.MOUSE_MOVE, this.onMouseMove);
		this.domElement.addEventListener(DOMEvent.MOUSE_WHEEL, this.onMouseWheel);
		this.domElement.addEventListener(DOMEvent.MOUSE_OUT, this.onMouseOut);
		this.domElement.addEventListener(DOMEvent.MOUSE_OVER, this.onMouseOver);
	}

	public function dispose() {
		this.domElement.removeEventListener(DOMEvent.TOUCH_START, this.onTouchStart);
		this.domElement.removeEventListener(DOMEvent.TOUCH_MOVE, this.onTouchMove);
		this.domElement.removeEventListener(DOMEvent.TOUCH_END, this.onTouchEnd);
		this.domElement.removeEventListener(DOMEvent.TOUCH_CANCEL, this.onTouchEnd);
		this.domElement.removeEventListener(DOMEvent.DOUBLE_TAP, this.onDoubleTap);
		this.domElement.removeEventListener(DOMEvent.MOUSE_DOWN, this.onMouseDown);
		this.domElement.removeEventListener(DOMEvent.MOUSE_UP, this.onMouseUp);
		this.domElement.removeEventListener(DOMEvent.MOUSE_MOVE, this.onMouseMove);
		this.domElement.removeEventListener(DOMEvent.MOUSE_WHEEL, this.onMouseWheel);
		this.domElement.removeEventListener(DOMEvent.MOUSE_OUT, this.onMouseOut);
		this.domElement.removeEventListener(DOMEvent.MOUSE_OVER, this.onMouseOver);
	}

	public function onTouchStart(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchStart = event.touches;
			this._touchCurrent = event.touches;
			this.dispatchEvent(_startEvent);
			if (event.touches.length == 1) {
				this.onSinglePanStart();
			} else if (event.touches.length == 2) {
				this.onDoublePanStart();
			} else if (event.touches.length == 3) {
				this.onTriplePanStart();
			}
		}
	}

	public function onTouchMove(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchCurrent = event.touches;
			if (event.touches.length == 1) {
				this.onSinglePanMove();
			} else if (event.touches.length == 2) {
				this.onDoublePanMove();
			} else if (event.touches.length == 3) {
				this.onTriplePanMove();
			}
		}
	}

	public function onTouchEnd(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchCurrent = event.touches;
			this.dispatchEvent(_endEvent);
			if (this._state == STATE.PAN || this._state == STATE.ROTATE || this._state == STATE.SCALE) {
				this.onSinglePanEnd();
			} else if (this._state == STATE.ZROTATE) {
				this.onRotateEnd();
			}
		}
	}

	public function onMouseDown(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this.onSinglePanStart();
		}
	}

	public function onMouseUp(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_endEvent);
			this.onSinglePanEnd();
		}
	}

	public function onMouseMove(event:MouseEvent) {
		if (this.enabled) {
			if (this._state == STATE.PAN) {
				this.onSinglePanMove();
			} else if (this._state == STATE.ROTATE) {
				this.onRotateMove();
			}
		}
	}

	public function onMouseWheel(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			if (this.enableZoom) {
				this.onPinchMove();
			}
			if (this.enableGrid) {
				this.disposeGrid();
			}
			this.dispatchEvent(_endEvent);
		}
	}

	public function onMouseOver(event:MouseEvent) {
		if (this.enabled) {
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
		}
	}

	public function onMouseOut(event:MouseEvent) {
		if (this.enabled) {
			if (this._state == STATE.ROTATE) {
				this.onRotateEnd();
			}
		}
	}

	public function onSinglePanStart() {
		if (this.enabled && this.enablePan) {
			this.dispatchEvent(_startEvent);
			this.updateTbState(STATE.PAN, true);
			this.setCenter(Toolkit.backend.getMouseX(), Toolkit.backend.getMouseY());
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			this.activateGizmos(false);
		}
	}

	public function onSinglePanMove() {
		if (this.enabled && this.enablePan) {
			this.setCenter(Toolkit.backend.getMouseX(), Toolkit.backend.getMouseY());
			if (this._state != STATE.PAN) {
				this.updateTbState(STATE.PAN, true);
				this._startCursorPosition.copy(this._currentCursorPosition);
			}
			this._currentCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this.applyTransformMatrix(this.pan(this._startCursorPosition, this._currentCursorPosition, true));
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onSinglePanEnd() {
		if (this._state == STATE.ROTATE) {
			if (!this.enableRotate) {
				return;
			}
			if (this.enableAnimations) {
				//perform rotation animation
				var deltaTime = (haxe.Timer.stamp() - this._timeCurrent);
				if (deltaTime < 120) {
					var w = Math.abs((this._wPrev + this._wCurr) / 2);
					var self = this;
					this._animationId = haxe.Timer.delay(function() {
						self.updateTbState(STATE.ANIMATION_ROTATE, true);
						var rotationAxis = self.calculateRotationAxis(self._cursorPosPrev, self._cursorPosCurr);
						self.onRotationAnim(haxe.Timer.stamp(), rotationAxis, Math.min(w, self.wMax));
					}, 10);
				} else {
					//cursor has been standing still for over 120 ms since last movement
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

	public function onDoubleTap(event:DOMTouchEvent) {
		if (this.enabled && this.enablePan && this.scene != null) {
			this.dispatchEvent(_startEvent);
			this.setCenter(event.clientX, event.clientY);
			var hitP = this.unprojectOnObj(this.getCursorNDC(_center.x, _center.y, this.domElement), this.camera);
			if (hitP != null && this.enableAnimations) {
				var self = this;
				if (this._animationId != -1) {
					haxe.Timer.clearTimeout(this._animationId);
				}
				this._timeStart = -1;
				this._animationId = haxe.Timer.delay(function(t) {
					self.updateTbState(STATE.ANIMATION_FOCUS, true);
					self.onFocusAnim(t, hitP, self._cameraMatrixState, self._gizmoMatrixState);
				}, 10);
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
			this.camera.getWorldDirection(this._rotationAxis); //rotation axis
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
			var amount = MathTools.DEG2RAD * (this._startFingerRotation - this._currentFingerRotation);
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
			var minDistance = 12; //minimum distance between fingers (in css pixels)
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
			for (var i = 0; i < nFingers; i++) {
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
			for (var i = 0; i < nFingers; i++) {
				clientX += this._touchCurrent[i].clientX;
				clientY += this._touchCurrent[i].clientY;
			}
			this.setCenter(clientX / nFingers, clientY / nFingers);
			var screenNotches = 8;	//how many wheel notches corresponds to a full screen pan
			this._currentCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
			var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
			var size = 1;
			if (movement < 0) {
				size = 1 / (Math.pow(this.scaleFactor, -movement * screenNotches));
			} else if (movement > 0) {
				size = Math.pow(this.scaleFactor, movement * screenNotches);
			}
			this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
			var x = this._v3_1.distanceTo(this._gizmos.position);
			var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed
			//check min and max distance
			xNew = MathTools.clamp(xNew, this.minDistance, this.maxDistance);
			var y = x * Math.tan(MathTools.DEG2RAD * this._fovState * 0.5);
			//calculate new fov
			var newFov = MathTools.RAD2DEG * (Math.atan(y / xNew) * 2);
			//check min and max fov
			newFov = MathTools.clamp(newFov, this.minFov, this.maxFov);
			var newDistance = y / Math.tan(MathTools.DEG2RAD * (newFov / 2));
			size = x / newDistance;
			this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
			this.setFov(newFov);
			this.applyTransformMatrix(this.scale(size, this._v3_2, false));
			//adjusting distance
			_offset.copy(this._gizmos.position).sub(this.camera.position).normalize().multiplyScalar(newDistance / x);
			this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onTriplePanEnd() {
		this.updateTbState(STATE.IDLE, false);
		this.dispatchEvent(_endEvent);
	}

	public function setCenter(clientX:Float, clientY:Float) {
		_center.x = clientX;
		_center.y = clientY;
	}

	public function setFov(fov:Float) {
		this._fovState = fov;
		this.camera.fov = fov;
		this.camera.updateProjectionMatrix();
	}

	public function initializeMouseActions() {
		this.setMouseAction("PAN", 0, "CTRL");
		this.setMouseAction("PAN", 2);
		this.setMouseAction("ROTATE", 0);
		this.setMouseAction("ZOOM", "WHEEL");
		this.setMouseAction("ZOOM", 1);
		this.setMouseAction("FOV", "WHEEL", "SHIFT");
		this.setMouseAction("FOV", 1, "SHIFT");
	}

	public function compareMouseAction(action1:MouseAction, action2:MouseAction):Bool {
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

	public function setMouseAction(operation:String, mouse:Int = -1, key:String = null) {
		var mouseAction = new MouseAction(operation, mouse, key);
		this._mouseActions.push(mouseAction);
	}

	public function activateGizmos(active:Bool) {
		if (active && this.enableGizmos) {
			this.gizmos.visible = true;
		} else {
			this.gizmos.visible = false;
		}
	}

	public function disposeGrid() {
		if (this.enableGrid) {
			this.scene.remove(this._grid);
			this._grid = null;
		}
	}

	public function updateTbState(newState:STATE, active:Bool) {
		if (active) {
			this._state = newState;
		} else {
			if (this._state == newState) {
				this._state = STATE.IDLE;
			}
		}
	}

	public function getAngle(p1:TouchEvent, p2:TouchEvent):Float {
		return Math.atan2(p2.clientY - p1.clientY, p2.clientX - p1.clientX);
	}

	public function calculatePointersDistance(p1:TouchEvent, p2:TouchEvent):Float {
		return Math.sqrt(Math.pow(p2.clientX - p1.clientX, 2) + Math.pow(p2.clientY - p1.clientY, 2));
	}

	public function getCursorNDC(x:Float, y:Float, domElement:DOMElement):Vector3 {
		return new Vector3((x / domElement.width) * 2 - 1, -(y / domElement.height) * 2 + 1, 0.5);
	}

	public function unprojectOnObj(ndc:Vector3, camera:Dynamic):Vector3 {
		var invMatrix = new Matrix4().getInverse(camera.matrixWorld);
		var vector = ndc.applyMatrix4(invMatrix);
		return vector;
	}

	public function unprojectOnTbPlane(camera:Dynamic, x:Float, y:Float, domElement:DOMElement, world:Bool = false):Vector3 {
		var ndc = this.getCursorNDC(x, y, domElement);
		var vector = new Vector3();
		var invMatrix = new Matrix4();
		if (world) {
			invMatrix = new Matrix4().getInverse(camera.matrixWorld);
		} else {
			invMatrix = new Matrix4().getInverse(camera.matrix);
		}
		vector.applyMatrix4(invMatrix);
		return vector;
	}

	public function applyTransformMatrix(matrix:Matrix4) {
		this._cameraMatrixState.multiplyMatrices(matrix, this._cameraMatrixState);
		this.camera.matrix.copy(this._cameraMatrixState);
		this.camera.updateProjectionMatrix();
		this._gizmoMatrixState.multiplyMatrices(matrix, this._gizmoMatrixState);
		this.gizmos.matrix.copy(this._gizmoMatrixState);
	}

	public function pan(start:Vector3, end:Vector3, world:Bool = false):Matrix4 {
		var v3 = end.sub(start);
		var m4 = new Matrix4();
		if (world) {
			m4.makeTranslation(-v3.x, -v3.y, -v3.z);
		} else {
			m4.makeTranslation(v3.x, v3.y, v3.z);
		}
		return m4;
	}

	public function scale(amount:Float, scalePoint:Vector3, world:Bool = true):Matrix4 {
		var m4 = new Matrix4();
		if (world) {
			m4.makeTranslation(scalePoint.x, scalePoint.y, scalePoint.z);
			m4.scale(new Vector3(amount, amount, amount));
			m4.makeTranslation(-scalePoint.x, -scalePoint.y, -scalePoint.z);
		} else {
			m4.makeTranslation(-scalePoint.x, -scalePoint.y, -scalePoint.z);
			m4.scale(new Vector3(amount, amount, amount));
			m4.makeTranslation(scalePoint.x, scalePoint.y, scalePoint.z);
		}
		return m4;
	}

	public function zRotate(rotationPoint:Vector3, amount:Float):Matrix4 {
		var m4 = new Matrix4();
		m4.makeTranslation(rotationPoint.x, rotationPoint.y, rotationPoint.z);
		m4.makeRotationAxis(this._rotationAxis, amount);
		m4.makeTranslation(-rotationPoint.x, -rotationPoint.y, -rotationPoint.z);
		return m4;
	}

	public
import haxe.ui.Event;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.TouchEvent;
import haxe.ui.components.Component;
import haxe.ui.Toolkit;
import haxe.ui.backend.Backend;
import haxe.ui.backend.dom.DOMBackend;
import haxe.ui.backend.dom.DOMComponent;
import haxe.ui.backend.dom.DOMElement;
import haxe.ui.backend.dom.DOMEvent;
import haxe.ui.backend.dom.DOMEventHandler;
import haxe.ui.backend.dom.DOMMouseEventHandler;
import haxe.ui.backend.dom.DOMTouchEvent;
import haxe.ui.backend.dom.DOMTouchEventHandler;
import haxe.ui.backend.dom.DOMWheelEventHandler;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.ComponentBase;
import haxe.ui.core.EventDispatcher;
import haxe.ui.core.ICloneable;
import haxe.ui.core.IEventDispatcher;
import haxe.ui.core.IPositionable;
import haxe.ui.core.ISizeable;
import haxe.ui.core.ITransformable;
import haxe.ui.core.MeasuredSize;
import haxe.ui.core.Rectangle;
import haxe.ui.core.Size;
import haxe.ui.core.Style;
import haxe.ui.core.Transform;
import haxe.ui.core.Vector3;
import haxe.ui.core.Matrix4;
import haxe.ui.effects.Animation;
import haxe.ui.effects.AnimationType;
import haxe.ui.effects.EasingType;
import haxe.ui.effects.IEasing;
import haxe.ui.effects.InterpolationType;
import haxe.ui.effects.Tween;
import haxe.ui.focus.IFocusable;
import haxe.ui.focus.IFocusManager;
import haxe.ui.focus.FocusManager;
import haxe.ui.graphics.Color;
import haxe.ui.graphics.Graphics;
import haxe.ui.graphics.GraphicsStyle;
import haxe.ui.graphics.GraphicsTools;
import haxe.ui.graphics.LineStyle;
import haxe.ui.graphics.RectangleStyle;
import haxe.ui.graphics.Shape;
import haxe.ui.graphics.Sprite;
import haxe.ui.graphics.Text;
import haxe.ui.graphics.TextFormat;
import haxe.ui.graphics.Texture;
import haxe.ui.graphics.TextureFormat;
import haxe.ui.graphics.TextureTools;
import haxe.ui.layout.Layout;
import haxe.ui.layout.LayoutManager;
import haxe.ui.layout.Padding;
import haxe.ui.layout.SizeConstraint;
import haxe.ui.layout.Spacing;
import haxe.ui.layout.VerticalLayout;
import haxe.ui.loaders.ImageLoader;
import haxe.ui.loaders.Loader;
import haxe.ui.loaders.LoaderEvent;
import haxe.ui.loaders.SoundLoader;
import haxe.ui.loaders.TextLoader;
import haxe.ui.loaders.URLRequest;
import haxe.ui.media.Sound;
import haxe.ui.media.SoundChannel;
import haxe.ui.media.SoundTransform;
import haxe.ui.media.Video;
import haxe.ui.media.VideoEvent;
import haxe.ui.media.VideoPlayer;
import haxe.ui.misc.BitmapData;
import haxe.ui.misc.Clipboard;
import haxe.ui.misc.DisplayObject;
import haxe.ui.misc.DisplayObjectContainer;
import haxe.ui.misc.InteractiveObject;
import haxe.ui.misc.Mouse;
import haxe.ui.misc.MouseCursor;
import haxe.ui.misc.MouseState;
import haxe.ui.misc.Point;
import haxe.ui.misc.Rectangle;
import haxe.ui.misc.Stage;
import haxe.ui.misc.StageAlign;
import haxe.ui.misc.StageScaleMode;
import haxe.ui.misc.TouchEvent;
import haxe.ui.misc.TouchState;
import haxe.ui.text.TextField;
import haxe.ui.text.TextInput;
import haxe.ui.text.TextFormat;
import haxe.ui.text.TextArea;
import haxe.ui.text.TextEvent;
import haxe.ui.text.TextFormatAlign;
import haxe.ui.text.TextFormatBlock;
import haxe.ui.text.TextFormatFont;
import haxe.ui.text.TextFormatSize;
import haxe.ui.text.TextFormatWeight;
import haxe.ui.util.Console;
import haxe.ui.util.Debug;
import haxe.ui.util.EventTools;
import haxe.ui.util.Hash;
import haxe.ui.util.JSON;
import haxe.ui.util.MathTools;
import haxe.ui.util.Timer;
import haxe.ui.util.URLTools;
import haxe.ui.util.Utils;
import haxe.ui.util.XMLTools;
import haxe.ui.view.View;
import haxe.ui.view.ViewEvent;
import haxe.ui.view.ViewManager;
import haxe.ui.view.ViewTransition;
import haxe.ui.view.ViewTransitionEvent;
import haxe.ui.view.ViewTransitionType;

class TouchControls extends ComponentBase {

	public var enabled:Bool = true;
	public var enablePan:Bool = true;
	public var enableRotate:Bool = true;
	public var enableZoom:Bool = true;
	public var enableGrid:Bool = true;
	public var enableAnimations:Bool = true;
	public var enableGizmos:Bool = false;

	public var scene:Dynamic = null;
	public var camera:Dynamic = null;
	public var domElement:DOMElement = null;
	public var gizmos:Dynamic = null;
	public var scaleFactor:Float = 1.2;
	public var wMax:Float = 100;
	public var minFov:Float = 1;
	public var maxFov:Float = 179;
	public var minDistance:Float = 0.1;
	public var maxDistance:Float = 1000;
	public var _fovState:Float = 0;
	public var _cameraMatrixState:Matrix4 = new Matrix4();
	public var _gizmoMatrixState:Matrix4 = new Matrix4();
	public var _startCursorPosition:Vector3 = new Vector3();
	public var _currentCursorPosition:Vector3 = new Vector3();
	public var _touchStart:Array<TouchEvent> = [];
	public var _touchCurrent:Array<TouchEvent> = [];
	public var _startFingerDistance:Float = 0;
	public var _currentFingerDistance:Float = 0;
	public var _startFingerRotation:Float = 0;
	public var _currentFingerRotation:Float = 0;
	public var _wPrev:Float = 0;
	public var _wCurr:Float = 0;
	public var _timeCurrent:Float = 0;
	public var _timeStart:Float = -1;
	public var _animationId:Int = -1;
	public var _rotationAxis:Vector3 = new Vector3();
	public var _center:Point = new Point();
	public var _v3_1:Vector3 = new Vector3();
	public var _v3_2:Vector3 = new Vector3();
	public var _m4_1:Matrix4 = new Matrix4();
	public var _offset:Vector3 = new Vector3();
	public var _devPxRatio:Float = 1;

	public var _state:STATE = STATE.IDLE;

	public var _startEvent:Event = new Event("onStart");
	public var _endEvent:Event = new Event("onEnd");
	public var _changeEvent:Event = new Event("onChange");


	public function new(scene:Dynamic, camera:Dynamic, domElement:DOMElement, gizmos:Dynamic) {
		super();
		this.scene = scene;
		this.camera = camera;
		this.domElement = domElement;
		this.gizmos = gizmos;
		this._devPxRatio = Toolkit.backend.getPixelRatio();
		this.initializeMouseActions();
		this.domElement.addEventListener(DOMEvent.TOUCH_START, this.onTouchStart);
		this.domElement.addEventListener(DOMEvent.TOUCH_MOVE, this.onTouchMove);
		this.domElement.addEventListener(DOMEvent.TOUCH_END, this.onTouchEnd);
		this.domElement.addEventListener(DOMEvent.TOUCH_CANCEL, this.onTouchEnd);
		this.domElement.addEventListener(DOMEvent.DOUBLE_TAP, this.onDoubleTap);
		this.domElement.addEventListener(DOMEvent.MOUSE_DOWN, this.onMouseDown);
		this.domElement.addEventListener(DOMEvent.MOUSE_UP, this.onMouseUp);
		this.domElement.addEventListener(DOMEvent.MOUSE_MOVE, this.onMouseMove);
		this.domElement.addEventListener(DOMEvent.MOUSE_WHEEL, this.onMouseWheel);
		this.domElement.addEventListener(DOMEvent.MOUSE_OUT, this.onMouseOut);
		this.domElement.addEventListener(DOMEvent.MOUSE_OVER, this.onMouseOver);
	}

	public function dispose() {
		this.domElement.removeEventListener(DOMEvent.TOUCH_START, this.onTouchStart);
		this.domElement.removeEventListener(DOMEvent.TOUCH_MOVE, this.onTouchMove);
		this.domElement.removeEventListener(DOMEvent.TOUCH_END, this.onTouchEnd);
		this.domElement.removeEventListener(DOMEvent.TOUCH_CANCEL, this.onTouchEnd);
		this.domElement.removeEventListener(DOMEvent.DOUBLE_TAP, this.onDoubleTap);
		this.domElement.removeEventListener(DOMEvent.MOUSE_DOWN, this.onMouseDown);
		this.domElement.removeEventListener(DOMEvent.MOUSE_UP, this.onMouseUp);
		this.domElement.removeEventListener(DOMEvent.MOUSE_MOVE, this.onMouseMove);
		this.domElement.removeEventListener(DOMEvent.MOUSE_WHEEL, this.onMouseWheel);
		this.domElement.removeEventListener(DOMEvent.MOUSE_OUT, this.onMouseOut);
		this.domElement.removeEventListener(DOMEvent.MOUSE_OVER, this.onMouseOver);
	}

	public function onTouchStart(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchStart = event.touches;
			this._touchCurrent = event.touches;
			this.dispatchEvent(_startEvent);
			if (event.touches.length == 1) {
				this.onSinglePanStart();
			} else if (event.touches.length == 2) {
				this.onDoublePanStart();
			} else if (event.touches.length == 3) {
				this.onTriplePanStart();
			}
		}
	}

	public function onTouchMove(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchCurrent = event.touches;
			if (event.touches.length == 1) {
				this.onSinglePanMove();
			} else if (event.touches.length == 2) {
				this.onDoublePanMove();
			} else if (event.touches.length == 3) {
				this.onTriplePanMove();
			}
		}
	}

	public function onTouchEnd(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchCurrent = event.touches;
			this.dispatchEvent(_endEvent);
			if (this._state == STATE.PAN || this._state == STATE.ROTATE || this._state == STATE.SCALE) {
				this.onSinglePanEnd();
			} else if (this._state == STATE.ZROTATE) {
				this.onRotateEnd();
			}
		}
	}

	public function onMouseDown(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this.onSinglePanStart();
		}
	}

	public function onMouseUp(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_endEvent);
			this.onSinglePanEnd();
		}
	}

	public function onMouseMove(event:MouseEvent) {
		if (this.enabled) {
			if (this._state == STATE.PAN) {
				this.onSinglePanMove();
			} else if (this._state == STATE.ROTATE) {
				this.onRotateMove();
			}
		}
	}

	public function onMouseWheel(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			if (this.enableZoom) {
				this.onPinchMove();
			}
			if (this.enableGrid) {
				this.disposeGrid();
			}
			this.dispatchEvent(_endEvent);
		}
	}

	public function onMouseOver(event:MouseEvent) {
		if (this.enabled) {
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
		}
	}

	public function onMouseOut(event:MouseEvent) {
		if (this.enabled) {
			if (this._state == STATE.ROTATE) {
				this.onRotateEnd();
			}
		}
	}

	public function onSinglePanStart() {
		if (this.enabled && this.enablePan) {
			this.dispatchEvent(_startEvent);
			this.updateTbState(STATE.PAN, true);
			this.setCenter(Toolkit.backend.getMouseX(), Toolkit.backend.getMouseY());
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			this.activateGizmos(false);
		}
	}

	public function onSinglePanMove() {
		if (this.enabled && this.enablePan) {
			this.setCenter(Toolkit.backend.getMouseX(), Toolkit.backend.getMouseY());
			if (this._state != STATE.PAN) {
				this.updateTbState(STATE.PAN, true);
				this._startCursorPosition.copy(this._currentCursorPosition);
			}
			this._currentCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this.applyTransformMatrix(this.pan(this._startCursorPosition, this._currentCursorPosition, true));
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onSinglePanEnd() {
		if (this._state == STATE.ROTATE) {
			if (!this.enableRotate) {
				return;
			}
			if (this.enableAnimations) {
				//perform rotation animation
				var deltaTime = (haxe.Timer.stamp() - this._timeCurrent);
				if (deltaTime < 120) {
					var w = Math.abs((this._wPrev + this._wCurr) / 2);
					var self = this;
					this._animationId = haxe.Timer.delay(function() {
						self.updateTbState(STATE.ANIMATION_ROTATE, true);
						var rotationAxis = self.calculateRotationAxis(self._cursorPosPrev, self._cursorPosCurr);
						self.onRotationAnim(haxe.Timer.stamp(), rotationAxis, Math.min(w, self.wMax));
					}, 10);
				} else {
					//cursor has been standing still for over 120 ms since last movement
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

	public function onDoubleTap(event:DOMTouchEvent) {
		if (this.enabled && this.enablePan && this.scene != null) {
			this.dispatchEvent(_startEvent);
			this.setCenter(event.clientX, event.clientY);
			var hitP = this.unprojectOnObj(this.getCursorNDC(_center.x, _center.y, this.domElement), this.camera);
			if (hitP != null && this.enableAnimations) {
				var self = this;
				if (this._animationId != -1) {
					haxe.Timer.clearTimeout(this._animationId);
				}
				this._timeStart = -1;
				this._animationId = haxe.Timer.delay(function(t) {
					self.updateTbState(STATE.ANIMATION_FOCUS, true);
					self.onFocusAnim(t, hitP, self._cameraMatrixState, self._gizmoMatrixState);
				}, 10);
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
			this.camera.getWorldDirection(this._rotationAxis); //rotation axis
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
			var amount = MathTools.DEG2RAD * (this._startFingerRotation - this._currentFingerRotation);
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
			var minDistance = 12; //minimum distance between fingers (in css pixels)
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
			for (var i = 0; i < nFingers; i++) {
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
			for (var i = 0; i < nFingers; i++) {
				clientX += this._touchCurrent[i].clientX;
				clientY += this._touchCurrent[i].clientY;
			}
			this.setCenter(clientX / nFingers, clientY / nFingers);
			var screenNotches = 8;	//how many wheel notches corresponds to a full screen pan
			this._currentCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
			var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
			var size = 1;
			if (movement < 0) {
				size = 1 / (Math.pow(this.scaleFactor, -movement * screenNotches));
			} else if (movement > 0) {
				size = Math.pow(this.scaleFactor, movement * screenNotches);
			}
			this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
			var x = this._v3_1.distanceTo(this._gizmos.position);
			var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed
			//check min and max distance
			xNew = MathTools.clamp(xNew, this.minDistance, this.maxDistance);
			var y = x * Math.tan(MathTools.DEG2RAD * this._fovState * 0.5);
			//calculate new fov
			var newFov = MathTools.RAD2DEG * (Math.atan(y / xNew) * 2);
			//check min and max fov
			newFov = MathTools.clamp(newFov, this.minFov, this.maxFov);
			var newDistance = y / Math.tan(MathTools.DEG2RAD * (newFov / 2));
			size = x / newDistance;
			this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
			this.setFov(newFov);
			this.applyTransformMatrix(this.scale(size, this._v3_2, false));
			//adjusting distance
			_offset.copy(this._gizmos.position).sub(this.camera.position).normalize().multiplyScalar(newDistance / x);
			this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onTriplePanEnd() {
		this.updateTbState(STATE.IDLE, false);
		this.dispatchEvent(_endEvent);
	}

	public function setCenter(clientX:Float, clientY:Float) {
		_center.x = clientX;
		_center.y = clientY;
	}

	public function setFov(fov:Float) {
		this._fovState = fov;
		this.camera.fov = fov;
		this.camera.updateProjectionMatrix();
	}

	public function initializeMouseActions() {
		this.setMouseAction("PAN", 0, "CTRL");
		this.setMouseAction("PAN", 2);
		this.setMouseAction("ROTATE", 0);
		this.setMouseAction("ZOOM", "WHEEL");
		this.setMouseAction("ZOOM", 1);
		this.setMouseAction("FOV", "WHEEL", "SHIFT");
		this.setMouseAction("FOV", 1, "SHIFT");
	}

	public function compareMouseAction(action1:MouseAction, action2:MouseAction):Bool {
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

	public function setMouseAction(operation:String, mouse:Int = -1, key:String = null) {
		var mouseAction = new MouseAction(operation, mouse, key);
		this._mouseActions.push(mouseAction);
	}

	public function activateGizmos(active:Bool) {
		if (active && this.enableGizmos) {
			this.gizmos.visible = true;
		} else {
			this.gizmos.visible = false;
		}
	}

	public function disposeGrid() {
		if (this.enableGrid) {
			this.scene.remove(this._grid);
			this._grid = null;
		}
	}

	public function updateTbState(newState:STATE, active:Bool) {
		if (active) {
			this._state = newState;
		} else {
			if (this._state == newState) {
				this._state = STATE.IDLE;
			}
		}
	}

	public function getAngle(p1:TouchEvent, p2:TouchEvent):Float {
		return Math.atan2(p2.clientY - p1.clientY, p2.clientX - p1.clientX);
	}

	public function calculatePointersDistance(p1:TouchEvent, p2:TouchEvent):Float {
		return Math.sqrt(Math.pow(p2.clientX - p1.clientX, 2) + Math.pow(p2.clientY - p1.clientY, 2));
	}

	public function getCursorNDC(x:Float, y:Float, domElement:DOMElement):Vector3 {
		return new Vector3((x / domElement.width) * 2 - 1, -(y / domElement.height) * 2 + 1, 0.5);
	}

	public function unprojectOnObj(ndc:Vector3, camera:Dynamic):Vector3 {
		var invMatrix = new Matrix4().getInverse(camera.matrixWorld);
		var vector = ndc.applyMatrix4(invMatrix);
		return vector;
	}

	public function unprojectOnTbPlane(camera:Dynamic, x:Float, y:Float, domElement:DOMElement, world:Bool = false):Vector3 {
		var ndc = this.getCursorNDC(x, y, domElement);
		var vector = new Vector3();
		var invMatrix = new Matrix4();
		if (world) {
			invMatrix = new Matrix4().getInverse(camera.matrixWorld);
		} else {
			invMatrix = new Matrix4().getInverse(camera.matrix);
		}
		vector.applyMatrix4(invMatrix);
		return vector;
	}

	public function applyTransformMatrix(matrix:Matrix4) {
		this._cameraMatrixState.multiplyMatrices(matrix, this._cameraMatrixState);
		this.camera.matrix.copy(this._cameraMatrixState);
		this.camera.updateProjectionMatrix();
		this._gizmoMatrixState.multiplyMatrices(matrix, this._gizmoMatrixState);
		this.gizmos.matrix.copy(this._gizmoMatrixState);
	}

	public function pan(start:Vector3, end:Vector3, world:Bool = false):Matrix4 {
		var v3 = end.sub(start);
		var m4 = new Matrix4();
		if (world) {
			m4.makeTranslation(-v3.x, -v3.y, -v3.z);
		} else {
			m4.makeTranslation(v3.x, v3.y, v3.z);
		}
		return m4;
	}

	public function scale(amount:Float, scalePoint:Vector3, world:Bool = true):Matrix4 {
		var m4 = new Matrix4();
		if (world) {
			m4.makeTranslation(scalePoint.x, scalePoint.y, scalePoint.z);
			m4.scale(new Vector3(amount, amount, amount));
			m4.makeTranslation(-scalePoint.x, -scalePoint.y, -scalePoint.z);
		} else {
			m4.makeTranslation(-scalePoint.x, -scalePoint.y, -scalePoint.z);
			m4.scale(new Vector3(amount, amount, amount));
			m4.makeTranslation(scalePoint.x, scalePoint.y, scalePoint.z);
		}
		return m4;
	}

	public function zRotate(rotationPoint:Vector3, amount:Float):Matrix4 {
		var m4 = new Matrix4();
		m4.makeTranslation(rotationPoint.x, rotationPoint.y, rotationPoint.z);
		m4.makeRotationAxis(this._rotationAxis, amount);
		m4.makeTranslation(-rotationPoint.x, -rotationPoint.y, -rotationPoint.z);
		return m4;
	}

	public
import haxe.ui.Event;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.TouchEvent;
import haxe.ui.components.Component;
import haxe.ui.Toolkit;
import haxe.ui.backend.Backend;
import haxe.ui.backend.dom.DOMBackend;
import haxe.ui.backend.dom.DOMComponent;
import haxe.ui.backend.dom.DOMElement;
import haxe.ui.backend.dom.DOMEvent;
import haxe.ui.backend.dom.DOMEventHandler;
import haxe.ui.backend.dom.DOMMouseEventHandler;
import haxe.ui.backend.dom.DOMTouchEvent;
import haxe.ui.backend.dom.DOMTouchEventHandler;
import haxe.ui.backend.dom.DOMWheelEventHandler;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.ComponentBase;
import haxe.ui.core.EventDispatcher;
import haxe.ui.core.ICloneable;
import haxe.ui.core.IEventDispatcher;
import haxe.ui.core.IPositionable;
import haxe.ui.core.ISizeable;
import haxe.ui.core.ITransformable;
import haxe.ui.core.MeasuredSize;
import haxe.ui.core.Rectangle;
import haxe.ui.core.Size;
import haxe.ui.core.Style;
import haxe.ui.core.Transform;
import haxe.ui.core.Vector3;
import haxe.ui.core.Matrix4;
import haxe.ui.effects.Animation;
import haxe.ui.effects.AnimationType;
import haxe.ui.effects.EasingType;
import haxe.ui.effects.IEasing;
import haxe.ui.effects.InterpolationType;
import haxe.ui.effects.Tween;
import haxe.ui.focus.IFocusable;
import haxe.ui.focus.IFocusManager;
import haxe.ui.focus.FocusManager;
import haxe.ui.graphics.Color;
import haxe.ui.graphics.Graphics;
import haxe.ui.graphics.GraphicsStyle;
import haxe.ui.graphics.GraphicsTools;
import haxe.ui.graphics.LineStyle;
import haxe.ui.graphics.RectangleStyle;
import haxe.ui.graphics.Shape;
import haxe.ui.graphics.Sprite;
import haxe.ui.graphics.Text;
import haxe.ui.graphics.TextFormat;
import haxe.ui.graphics.Texture;
import haxe.ui.graphics.TextureFormat;
import haxe.ui.graphics.TextureTools;
import haxe.ui.layout.Layout;
import haxe.ui.layout.LayoutManager;
import haxe.ui.layout.Padding;
import haxe.ui.layout.SizeConstraint;
import haxe.ui.layout.Spacing;
import haxe.ui.layout.VerticalLayout;
import haxe.ui.loaders.ImageLoader;
import haxe.ui.loaders.Loader;
import haxe.ui.loaders.LoaderEvent;
import haxe.ui.loaders.SoundLoader;
import haxe.ui.loaders.TextLoader;
import haxe.ui.loaders.URLRequest;
import haxe.ui.media.Sound;
import haxe.ui.media.SoundChannel;
import haxe.ui.media.SoundTransform;
import haxe.ui.media.Video;
import haxe.ui.media.VideoEvent;
import haxe.ui.media.VideoPlayer;
import haxe.ui.misc.BitmapData;
import haxe.ui.misc.Clipboard;
import haxe.ui.misc.DisplayObject;
import haxe.ui.misc.DisplayObjectContainer;
import haxe.ui.misc.InteractiveObject;
import haxe.ui.misc.Mouse;
import haxe.ui.misc.MouseCursor;
import haxe.ui.misc.MouseState;
import haxe.ui.misc.Point;
import haxe.ui.misc.Rectangle;
import haxe.ui.misc.Stage;
import haxe.ui.misc.StageAlign;
import haxe.ui.misc.StageScaleMode;
import haxe.ui.misc.TouchEvent;
import haxe.ui.misc.TouchState;
import haxe.ui.text.TextField;
import haxe.ui.text.TextInput;
import haxe.ui.text.TextFormat;
import haxe.ui.text.TextArea;
import haxe.ui.text.TextEvent;
import haxe.ui.text.TextFormatAlign;
import haxe.ui.text.TextFormatBlock;
import haxe.ui.text.TextFormatFont;
import haxe.ui.text.TextFormatSize;
import haxe.ui.text.TextFormatWeight;
import haxe.ui.util.Console;
import haxe.ui.util.Debug;
import haxe.ui.util.EventTools;
import haxe.ui.util.Hash;
import haxe.ui.util.JSON;
import haxe.ui.util.MathTools;
import haxe.ui.util.Timer;
import haxe.ui.util.URLTools;
import haxe.ui.util.Utils;
import haxe.ui.util.XMLTools;
import haxe.ui.view.View;
import haxe.ui.view.ViewEvent;
import haxe.ui.view.ViewManager;
import haxe.ui.view.ViewTransition;
import haxe.ui.view.ViewTransitionEvent;
import haxe.ui.view.ViewTransitionType;

class TouchControls extends ComponentBase {

	public var enabled:Bool = true;
	public var enablePan:Bool = true;
	public var enableRotate:Bool = true;
	public var enableZoom:Bool = true;
	public var enableGrid:Bool = true;
	public var enableAnimations:Bool = true;
	public var enableGizmos:Bool = false;

	public var scene:Dynamic = null;
	public var camera:Dynamic = null;
	public var domElement:DOMElement = null;
	public var gizmos:Dynamic = null;
	public var scaleFactor:Float = 1.2;
	public var wMax:Float = 100;
	public var minFov:Float = 1;
	public var maxFov:Float = 179;
	public var minDistance:Float = 0.1;
	public var maxDistance:Float = 1000;
	public var _fovState:Float = 0;
	public var _cameraMatrixState:Matrix4 = new Matrix4();
	public var _gizmoMatrixState:Matrix4 = new Matrix4();
	public var _startCursorPosition:Vector3 = new Vector3();
	public var _currentCursorPosition:Vector3 = new Vector3();
	public var _touchStart:Array<TouchEvent> = [];
	public var _touchCurrent:Array<TouchEvent> = [];
	public var _startFingerDistance:Float = 0;
	public var _currentFingerDistance:Float = 0;
	public var _startFingerRotation:Float = 0;
	public var _currentFingerRotation:Float = 0;
	public var _wPrev:Float = 0;
	public var _wCurr:Float = 0;
	public var _timeCurrent:Float = 0;
	public var _timeStart:Float = -1;
	public var _animationId:Int = -1;
	public var _rotationAxis:Vector3 = new Vector3();
	public var _center:Point = new Point();
	public var _v3_1:Vector3 = new Vector3();
	public var _v3_2:Vector3 = new Vector3();
	public var _m4_1:Matrix4 = new Matrix4();
	public var _offset:Vector3 = new Vector3();
	public var _devPxRatio:Float = 1;

	public var _state:STATE = STATE.IDLE;

	public var _startEvent:Event = new Event("onStart");
	public var _endEvent:Event = new Event("onEnd");
	public var _changeEvent:Event = new Event("onChange");


	public function new(scene:Dynamic, camera:Dynamic, domElement:DOMElement, gizmos:Dynamic) {
		super();
		this.scene = scene;
		this.camera = camera;
		this.domElement = domElement;
		this.gizmos = gizmos;
		this._devPxRatio = Toolkit.backend.getPixelRatio();
		this.initializeMouseActions();
		this.domElement.addEventListener(DOMEvent.TOUCH_START, this.onTouchStart);
		this.domElement.addEventListener(DOMEvent.TOUCH_MOVE, this.onTouchMove);
		this.domElement.addEventListener(DOMEvent.TOUCH_END, this.onTouchEnd);
		this.domElement.addEventListener(DOMEvent.TOUCH_CANCEL, this.onTouchEnd);
		this.domElement.addEventListener(DOMEvent.DOUBLE_TAP, this.onDoubleTap);
		this.domElement.addEventListener(DOMEvent.MOUSE_DOWN, this.onMouseDown);
		this.domElement.addEventListener(DOMEvent.MOUSE_UP, this.onMouseUp);
		this.domElement.addEventListener(DOMEvent.MOUSE_MOVE, this.onMouseMove);
		this.domElement.addEventListener(DOMEvent.MOUSE_WHEEL, this.onMouseWheel);
		this.domElement.addEventListener(DOMEvent.MOUSE_OUT, this.onMouseOut);
		this.domElement.addEventListener(DOMEvent.MOUSE_OVER, this.onMouseOver);
	}

	public function dispose() {
		this.domElement.removeEventListener(DOMEvent.TOUCH_START, this.onTouchStart);
		this.domElement.removeEventListener(DOMEvent.TOUCH_MOVE, this.onTouchMove);
		this.domElement.removeEventListener(DOMEvent.TOUCH_END, this.onTouchEnd);
		this.domElement.removeEventListener(DOMEvent.TOUCH_CANCEL, this.onTouchEnd);
		this.domElement.removeEventListener(DOMEvent.DOUBLE_TAP, this.onDoubleTap);
		this.domElement.removeEventListener(DOMEvent.MOUSE_DOWN, this.onMouseDown);
		this.domElement.removeEventListener(DOMEvent.MOUSE_UP, this.onMouseUp);
		this.domElement.removeEventListener(DOMEvent.MOUSE_MOVE, this.onMouseMove);
		this.domElement.removeEventListener(DOMEvent.MOUSE_WHEEL, this.onMouseWheel);
		this.domElement.removeEventListener(DOMEvent.MOUSE_OUT, this.onMouseOut);
		this.domElement.removeEventListener(DOMEvent.MOUSE_OVER, this.onMouseOver);
	}

	public function onTouchStart(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchStart = event.touches;
			this._touchCurrent = event.touches;
			this.dispatchEvent(_startEvent);
			if (event.touches.length == 1) {
				this.onSinglePanStart();
			} else if (event.touches.length == 2) {
				this.onDoublePanStart();
			} else if (event.touches.length == 3) {
				this.onTriplePanStart();
			}
		}
	}

	public function onTouchMove(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchCurrent = event.touches;
			if (event.touches.length == 1) {
				this.onSinglePanMove();
			} else if (event.touches.length == 2) {
				this.onDoublePanMove();
			} else if (event.touches.length == 3) {
				this.onTriplePanMove();
			}
		}
	}

	public function onTouchEnd(event:DOMTouchEvent) {
		if (this.enabled) {
			this._touchCurrent = event.touches;
			this.dispatchEvent(_endEvent);
			if (this._state == STATE.PAN || this._state == STATE.ROTATE || this._state == STATE.SCALE) {
				this.onSinglePanEnd();
			} else if (this._state == STATE.ZROTATE) {
				this.onRotateEnd();
			}
		}
	}

	public function onMouseDown(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this.onSinglePanStart();
		}
	}

	public function onMouseUp(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_endEvent);
			this.onSinglePanEnd();
		}
	}

	public function onMouseMove(event:MouseEvent) {
		if (this.enabled) {
			if (this._state == STATE.PAN) {
				this.onSinglePanMove();
			} else if (this._state == STATE.ROTATE) {
				this.onRotateMove();
			}
		}
	}

	public function onMouseWheel(event:MouseEvent) {
		if (this.enabled) {
			this.dispatchEvent(_startEvent);
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			if (this.enableZoom) {
				this.onPinchMove();
			}
			if (this.enableGrid) {
				this.disposeGrid();
			}
			this.dispatchEvent(_endEvent);
		}
	}

	public function onMouseOver(event:MouseEvent) {
		if (this.enabled) {
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, event.clientX, event.clientY, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
		}
	}

	public function onMouseOut(event:MouseEvent) {
		if (this.enabled) {
			if (this._state == STATE.ROTATE) {
				this.onRotateEnd();
			}
		}
	}

	public function onSinglePanStart() {
		if (this.enabled && this.enablePan) {
			this.dispatchEvent(_startEvent);
			this.updateTbState(STATE.PAN, true);
			this.setCenter(Toolkit.backend.getMouseX(), Toolkit.backend.getMouseY());
			this._startCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this._currentCursorPosition.copy(this._startCursorPosition);
			this.activateGizmos(false);
		}
	}

	public function onSinglePanMove() {
		if (this.enabled && this.enablePan) {
			this.setCenter(Toolkit.backend.getMouseX(), Toolkit.backend.getMouseY());
			if (this._state != STATE.PAN) {
				this.updateTbState(STATE.PAN, true);
				this._startCursorPosition.copy(this._currentCursorPosition);
			}
			this._currentCursorPosition.copy(this.unprojectOnTbPlane(this.camera, _center.x, _center.y, this.domElement, true));
			this.applyTransformMatrix(this.pan(this._startCursorPosition, this._currentCursorPosition, true));
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onSinglePanEnd() {
		if (this._state == STATE.ROTATE) {
			if (!this.enableRotate) {
				return;
			}
			if (this.enableAnimations) {
				//perform rotation animation
				var deltaTime = (haxe.Timer.stamp() - this._timeCurrent);
				if (deltaTime < 120) {
					var w = Math.abs((this._wPrev + this._wCurr) / 2);
					var self = this;
					this._animationId = haxe.Timer.delay(function() {
						self.updateTbState(STATE.ANIMATION_ROTATE, true);
						var rotationAxis = self.calculateRotationAxis(self._cursorPosPrev, self._cursorPosCurr);
						self.onRotationAnim(haxe.Timer.stamp(), rotationAxis, Math.min(w, self.wMax));
					}, 10);
				} else {
					//cursor has been standing still for over 120 ms since last movement
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

	public function onDoubleTap(event:DOMTouchEvent) {
		if (this.enabled && this.enablePan && this.scene != null) {
			this.dispatchEvent(_startEvent);
			this.setCenter(event.clientX, event.clientY);
			var hitP = this.unprojectOnObj(this.getCursorNDC(_center.x, _center.y, this.domElement), this.camera);
			if (hitP != null && this.enableAnimations) {
				var self = this;
				if (this._animationId != -1) {
					haxe.Timer.clearTimeout(this._animationId);
				}
				this._timeStart = -1;
				this._animationId = haxe.Timer.delay(function(t) {
					self.updateTbState(STATE.ANIMATION_FOCUS, true);
					self.onFocusAnim(t, hitP, self._cameraMatrixState, self._gizmoMatrixState);
				}, 10);
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
			this.camera.getWorldDirection(this._rotationAxis); //rotation axis
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
			var amount = MathTools.DEG2RAD * (this._startFingerRotation - this._currentFingerRotation);
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
			var minDistance = 12; //minimum distance between fingers (in css pixels)
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
			for (var i = 0; i < nFingers; i++) {
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
			for (var i = 0; i < nFingers; i++) {
				clientX += this._touchCurrent[i].clientX;
				clientY += this._touchCurrent[i].clientY;
			}
			this.setCenter(clientX / nFingers, clientY / nFingers);
			var screenNotches = 8;	//how many wheel notches corresponds to a full screen pan
			this._currentCursorPosition.setY(this.getCursorNDC(_center.x, _center.y, this.domElement).y * 0.5);
			var movement = this._currentCursorPosition.y - this._startCursorPosition.y;
			var size = 1;
			if (movement < 0) {
				size = 1 / (Math.pow(this.scaleFactor, -movement * screenNotches));
			} else if (movement > 0) {
				size = Math.pow(this.scaleFactor, movement * screenNotches);
			}
			this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
			var x = this._v3_1.distanceTo(this._gizmos.position);
			var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed
			//check min and max distance
			xNew = MathTools.clamp(xNew, this.minDistance, this.maxDistance);
			var y = x * Math.tan(MathTools.DEG2RAD * this._fovState * 0.5);
			//calculate new fov
			var newFov = MathTools.RAD2DEG * (Math.atan(y / xNew) * 2);
			//check min and max fov
			newFov = MathTools.clamp(newFov, this.minFov, this.maxFov);
			var newDistance = y / Math.tan(MathTools.DEG2RAD * (newFov / 2));
			size = x / newDistance;
			this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);
			this.setFov(newFov);
			this.applyTransformMatrix(this.scale(size, this._v3_2, false));
			//adjusting distance
			_offset.copy(this._gizmos.position).sub(this.camera.position).normalize().multiplyScalar(newDistance / x);
			this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
			this.dispatchEvent(_changeEvent);
		}
	}

	public function onTriplePanEnd() {
		this.updateTbState(STATE.IDLE, false);
		this.dispatchEvent(_endEvent);
	}

	public function setCenter(clientX:Float, clientY:Float) {
		_center.x = clientX;
		_center.y = clientY;
	}

	public function setFov(fov:Float) {
		this._fovState = fov;
		this.camera.fov = fov;
		this.camera.updateProjectionMatrix();
	}

	public function initializeMouseActions() {
		this.setMouseAction("PAN", 0, "CTRL");
		this.setMouseAction("PAN", 2);
		this.setMouseAction("ROTATE", 0);
		this.setMouseAction("ZOOM", "WHEEL");
		this.setMouseAction("ZOOM", 1);
		this.setMouseAction("FOV", "WHEEL", "SHIFT");
		this.setMouseAction("FOV", 1, "SHIFT");
	}

	public function compareMouseAction(action1:MouseAction, action2:MouseAction):Bool {
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

	public function setMouseAction(operation:String, mouse:Int = -1, key:String = null) {
		var mouseAction = new MouseAction(operation, mouse, key);
		this._mouseActions.push(mouseAction);
	}

	public function activateGizmos(active:Bool) {
		if (active && this.enableGizmos) {
			this.gizmos.visible = true;
		} else {
			this.gizmos.visible = false;
		}
	}

	public function disposeGrid() {
		if (this.enableGrid) {
			this.scene.remove(this._grid);
			this._grid = null;
		}
	}

	public function updateTbState(newState:STATE, active:Bool) {
		if (active) {
			this._state = newState;
		} else {
			if (this._state == newState) {
				this._state = STATE.IDLE;
			}
		}
	}

	public function getAngle(p1:TouchEvent, p2:TouchEvent):Float {
		return Math.atan2(p2.clientY - p1.clientY, p2.clientX - p1.clientX);
	}

	public function calculatePointersDistance(p1:TouchEvent, p2:TouchEvent):Float {
		return Math.sqrt(Math.pow(p2.clientX - p1.clientX, 2) + Math.pow(p2.clientY - p1.clientY, 2));
	}

	public function getCursorNDC(x:Float, y:Float, domElement:DOMElement):Vector3 {
		return new Vector3((x / domElement.width) * 2 - 1, -(y / domElement.height) * 2 + 1, 0.5);
	}

	public function unprojectOnObj(ndc:Vector3, camera:Dynamic):Vector3 {
		var invMatrix = new Matrix4().getInverse(camera.matrixWorld);
		var vector = ndc.applyMatrix4(invMatrix);
		return vector;
	}

	public function unprojectOnTbPlane(camera:Dynamic, x:Float, y:Float, domElement:DOMElement, world:Bool = false):Vector3 {
		var ndc = this.getCursorNDC(x, y, domElement);
		var vector = new Vector3();
		var invMatrix = new Matrix4();
		if (world) {
			invMatrix = new Matrix4().getInverse(camera.matrixWorld);
		} else {
			invMatrix = new Matrix4().getInverse(camera.matrix);
		}
		vector.applyMatrix4(invMatrix);
		return vector;
	}

	public function applyTransformMatrix(matrix:Matrix4) {
		this._cameraMatrixState.multiplyMatrices(matrix, this._cameraMatrixState);
		this.camera.matrix.copy(this._cameraMatrixState);
		this.camera.updateProjectionMatrix();
		this._gizmoMatrixState.multiplyMatrices(matrix, this._gizmoMatrixState);
		this.gizmos.matrix.copy(this._gizmoMatrixState);
	}

	public function pan(start:Vector3, end:Vector3, world:Bool = false):Matrix4 {
		var v3 = end.sub(start);
		var m4 = new Matrix4();
		if (world) {
			m4.makeTranslation(-v3.x, -v3.y, -v3.z);
		} else {
			m4.makeTranslation(v3.x, v3.y, v3.z);
		}
		return m4;
	}

	public function scale(amount:Float, scalePoint:Vector3, world:Bool = true):Matrix4 {
		var m4 = new Matrix4();
		if (world) {
			m4.makeTranslation(scalePoint.x, scalePoint.y, scalePoint.z);
			m4.scale(new Vector3(amount, amount, amount));
			m4.makeTranslation(-scalePoint.x, -scalePoint.y, -scalePoint.z);
		} else {
			m4.makeTranslation(-scalePoint.x, -scalePoint.y, -scalePoint.z);
			m4.scale(new Vector3(amount, amount, amount));
			m4.makeTranslation(scalePoint.x, scalePoint.y, scalePoint.z);
		}
		return m4;
	}

	public function zRotate(rotationPoint:Vector3, amount:Float):Matrix4 {
		var m4 = new Matrix4();
		m4.makeTranslation(rotationPoint.x, rotationPoint.y, rotationPoint.z);
		m4.makeRotationAxis(this._rotationAxis, amount);
		m4.makeTranslation(-rotationPoint.x, -rotationPoint.y, -rotationPoint.z);
		return m4;
	}

	public