import haxe.ui.backend.HXT;
import haxe.ui.backend.hx.HXT_hx;
import haxe.ui.backend.hx.HXT_hx_dom;
import haxe.ui.util.Color;
import haxe.ui.util.Event;
import haxe.ui.util.IEventDispatcher;
import haxe.ui.util.Matrix3;
import haxe.ui.util.Matrix4;
import haxe.ui.util.Quaternion;
import haxe.ui.util.Vector3;
import haxe.ui.util.MathUtils;
import haxe.ui.util.Geometry;
import haxe.ui.util.LineBasicMaterial;
import haxe.ui.util.BufferGeometry;
import haxe.ui.util.EllipseCurve;
import haxe.ui.util.Line;
import haxe.ui.util.Object3D;
import haxe.ui.util.PerspectiveCamera;
import haxe.ui.util.OrthographicCamera;

class Arcball {

	private var _camera:PerspectiveCamera;
	private var _cameraMatrixState:Matrix4;
	private var _cameraMatrixState0:Matrix4;
	private var _gizmoMatrixState:Matrix4;
	private var _gizmoMatrixState0:Matrix4;
	private var _scaleMatrix:Matrix4;
	private var _translationMatrix:Matrix4;
	private var _gizmos:Object3D;
	private var _rotationMatrix:Matrix4;
	private var _tbRadius:Float;
	private var _curvePts:Int = 20;
	private var _nearPos:Float;
	private var _farPos:Float;
	private var _fov0:Float;
	private var _zoom0:Float;
	private var _up0:Vector3;
	private var _zoomState:Float = 1;
	private var _v3_1:Vector3;
	private var _v3_2:Vector3;
	private var _m4_1:Matrix4;
	private var _m4_2:Matrix4;
	private var _offset:Vector3;
	private var _scalePointTemp:Vector3;
	private var _timeStart:Float = -1;
	private var _animationId:Int = -1;
	private var _anglePrev:Float = 0;
	private var _angleCurrent:Float = 0;
	private var _state:STATE = STATE.IDLE;

	private var _changeEvent:Event;

	public var radiusFactor:Float = 1;
	public var scaleFactor:Float = 1;
	public var dampingFactor:Float = 5;
	public var focusAnimationTime:Float = 0.5;
	public var minZoom:Float = 0.1;
	public var maxZoom:Float = 10;
	public var minDistance:Float = 1;
	public var maxDistance:Float = 100;
	public var minFov:Float = 1;
	public var maxFov:Float = 179;

	public function new( camera:PerspectiveCamera ) {
		this._camera = camera;
		this._cameraMatrixState = new Matrix4();
		this._cameraMatrixState0 = new Matrix4();
		this._gizmoMatrixState = new Matrix4();
		this._gizmoMatrixState0 = new Matrix4();
		this._scaleMatrix = new Matrix4();
		this._translationMatrix = new Matrix4();
		this._gizmos = new Object3D();
		this._rotationMatrix = new Matrix4();
		this._v3_1 = new Vector3();
		this._v3_2 = new Vector3();
		this._m4_1 = new Matrix4();
		this._m4_2 = new Matrix4();
		this._offset = new Vector3();
		this._scalePointTemp = new Vector3();
		this._changeEvent = new Event(Event.CHANGE);

		this.saveState();
		this.makeGizmos(this._gizmos.position, this.calculateTbRadius(this._camera));
	}

	public function setTbRadius( value:Float ):Void {
		this.radiusFactor = value;
		this._tbRadius = this.calculateTbRadius(this._camera);

		var curve = new EllipseCurve(0, 0, this._tbRadius, this._tbRadius);
		var points = curve.getPoints(this._curvePts);
		var curveGeometry = new BufferGeometry().setFromPoints(points);

		for (gizmo in this._gizmos.children) {
			this._gizmos.children[gizmo].geometry = curveGeometry;
		}

		this.dispatchEvent(_changeEvent);
	}

	public function makeGizmos( tbCenter:Vector3, tbRadius:Float ):Void {
		var curve = new EllipseCurve(0, 0, tbRadius, tbRadius);
		var points = curve.getPoints(this._curvePts);

		// geometry
		var curveGeometry = new BufferGeometry().setFromPoints(points);

		// material
		var curveMaterialX = new LineBasicMaterial({color: Color.fromHex(0xff8080), fog: false, transparent: true, opacity: 0.6});
		var curveMaterialY = new LineBasicMaterial({color: Color.fromHex(0x80ff80), fog: false, transparent: true, opacity: 0.6});
		var curveMaterialZ = new LineBasicMaterial({color: Color.fromHex(0x8080ff), fog: false, transparent: true, opacity: 0.6});

		// line
		var gizmoX = new Line(curveGeometry, curveMaterialX);
		var gizmoY = new Line(curveGeometry, curveMaterialY);
		var gizmoZ = new Line(curveGeometry, curveMaterialZ);

		var rotation = Math.PI * 0.5;
		gizmoX.rotation.x = rotation;
		gizmoY.rotation.y = rotation;

		// setting state
		this._gizmoMatrixState0.identity().setPosition(tbCenter);
		this._gizmoMatrixState.copy(this._gizmoMatrixState0);

		if (this._camera.zoom != 1) {
			// adapt gizmos size to camera zoom
			var size = 1 / this._camera.zoom;
			this._scaleMatrix.makeScale(size, size, size);
			this._translationMatrix.makeTranslation(-tbCenter.x, -tbCenter.y, -tbCenter.z);

			this._gizmoMatrixState.premultiply(this._translationMatrix).premultiply(this._scaleMatrix);
			this._translationMatrix.makeTranslation(tbCenter.x, tbCenter.y, tbCenter.z);
			this._gizmoMatrixState.premultiply(this._translationMatrix);
		}

		this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);

		//
		this._gizmos.traverse(function(object) {
			if (object.isLine) {
				object.geometry.dispose();
				object.material.dispose();
			}
		});

		this._gizmos.clear();

		//

		this._gizmos.add(gizmoX);
		this._gizmos.add(gizmoY);
		this._gizmos.add(gizmoZ);
	}

	public function onFocusAnim(time:Float, point:Vector3, cameraMatrix:Matrix4, gizmoMatrix:Matrix4):Void {
		if (this._timeStart == -1) {
			// animation start
			this._timeStart = time;
		}

		if (this._state == STATE.ANIMATION_FOCUS) {
			var deltaTime = time - this._timeStart;
			var animTime = deltaTime / this.focusAnimationTime;

			this._gizmoMatrixState.copy(gizmoMatrix);

			if (animTime >= 1) {
				// animation end

				this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);

				this.focus(point, this.scaleFactor);

				this._timeStart = -1;
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
				this._animationId = HXT.requestAnimationFrame(function(t) {
					self.onFocusAnim(t, point, cameraMatrix, gizmoMatrix.clone());
				});
			}
		} else {
			// interrupt animation

			this._animationId = -1;
			this._timeStart = -1;
		}
	}

	public function onRotationAnim(time:Float, rotationAxis:Vector3, w0:Float):Void {
		if (this._timeStart == -1) {
			// animation start
			this._anglePrev = 0;
			this._angleCurrent = 0;
			this._timeStart = time;
		}

		if (this._state == STATE.ANIMATION_ROTATE) {
			// w = w0 + alpha * t
			var deltaTime = (time - this._timeStart) / 1000;
			var w = w0 + ((-this.dampingFactor) * deltaTime);

			if (w > 0) {
				// tetha = 0.5 * alpha * t^2 + w0 * t + tetha0
				this._angleCurrent = 0.5 * (-this.dampingFactor) * Math.pow(deltaTime, 2) + w0 * deltaTime + 0;
				this.applyTransformMatrix(this.rotate(rotationAxis, this._angleCurrent));
				this.dispatchEvent(_changeEvent);
				var self = this;
				this._animationId = HXT.requestAnimationFrame(function(t) {
					self.onRotationAnim(t, rotationAxis, w0);
				});
			} else {
				this._animationId = -1;
				this._timeStart = -1;

				this.updateTbState(STATE.IDLE, false);
				this.activateGizmos(false);

				this.dispatchEvent(_changeEvent);
			}
		} else {
			// interrupt animation

			this._animationId = -1;
			this._timeStart = -1;

			if (this._state != STATE.ROTATE) {
				this.activateGizmos(false);
				this.dispatchEvent(_changeEvent);
			}
		}
	}

	public function pan(p0:Vector3, p1:Vector3, adjust:Bool = false):Matrix4 {
		var movement = p0.clone().sub(p1);

		if (this._camera.isOrthographicCamera) {
			// adjust movement amount
			movement.multiplyScalar(1 / this._camera.zoom);
		} else if (this._camera.isPerspectiveCamera && adjust) {
			// adjust movement amount
			this._v3_1.setFromMatrixPosition(this._cameraMatrixState0);	// camera's initial position
			this._v3_2.setFromMatrixPosition(this._gizmoMatrixState0);	// gizmo's initial position
			var distanceFactor = this._v3_1.distanceTo(this._v3_2) / this._camera.position.distanceTo(this._gizmos.position);
			movement.multiplyScalar(1 / distanceFactor);
		}

		this._v3_1.set(movement.x, movement.y, 0).applyQuaternion(this._camera.quaternion);

		this._m4_1.makeTranslation(this._v3_1.x, this._v3_1.y, this._v3_1.z);

		this.setTransformationMatrices(this._m4_1, this._m4_1);
		return _transformation;
	}

	public function reset():Void {
		this._camera.zoom = this._zoom0;

		if (this._camera.isPerspectiveCamera) {
			this._camera.fov = this._fov0;
		}

		this._camera.near = this._nearPos;
		this._camera.far = this._farPos;
		this._cameraMatrixState.copy(this._cameraMatrixState0);
		this._cameraMatrixState.decompose(this._camera.position, this._camera.quaternion, this._camera.scale);
		this._camera.up.copy(this._up0);

		this._camera.updateMatrix();
		this._camera.updateProjectionMatrix();

		this._gizmoMatrixState.copy(this._gizmoMatrixState0);
		this._gizmoMatrixState0.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
		this._gizmos.updateMatrix();

		this._tbRadius = this.calculateTbRadius(this._camera);
		this.makeGizmos(this._gizmos.position, this._tbRadius);

		this._camera.lookAt(this._gizmos.position);

		this.updateTbState(STATE.IDLE, false);

		this.dispatchEvent(_changeEvent);
	}

	public function rotate(axis:Vector3, angle:Float):Matrix4 {
		var point = this._gizmos.position; // rotation center
		this._translationMatrix.makeTranslation(-point.x, -point.y, -point.z);
		this._rotationMatrix.makeRotationAxis(axis, -angle);

		// rotate camera
		this._m4_1.makeTranslation(point.x, point.y, point.z);
		this._m4_1.multiply(this._rotationMatrix);
		this._m4_1.multiply(this._translationMatrix);

		this.setTransformationMatrices(this._m4_1);

		return _transformation;
	}

	public function copyState():Void {
		var state:String;
		if (this._camera.isOrthographicCamera) {
			state = JSON.stringify({arcballState: {
				cameraFar: this._camera.far,
				cameraMatrix: this._camera.matrix,
				cameraNear: this._camera.near,
				cameraUp: this._camera.up,
				cameraZoom: this._camera.zoom,
				gizmoMatrix: this._gizmos.matrix
			}});
		} else if (this._camera.isPerspectiveCamera) {
			state = JSON.stringify({arcballState: {
				cameraFar: this._camera.far,
				cameraFov: this._camera.fov,
				cameraMatrix: this._camera.matrix,
				cameraNear: this._camera.near,
				cameraUp: this._camera.up,
				cameraZoom: this._camera.zoom,
				gizmoMatrix: this._gizmos.matrix
			}});
		}

		HXT_hx_dom.clipboardWriteText(state);
	}

	public function pasteState():Void {
		var self = this;
		HXT_hx_dom.clipboardReadText().then(function(value:String) {
			self.setStateFromJSON(value);
		});
	}

	public function saveState():Void {
		this._cameraMatrixState0.copy(this._camera.matrix);
		this._gizmoMatrixState0.copy(this._gizmos.matrix);
		this._nearPos = this._camera.near;
		this._farPos = this._camera.far;
		this._zoom0 = this._camera.zoom;
		this._up0.copy(this._camera.up);

		if (this._camera.isPerspectiveCamera) {
			this._fov0 = this._camera.fov;
		}
	}

	public function scale(size:Float, point:Vector3, scaleGizmos:Bool = true):Matrix4 {
		_scalePointTemp.copy(point);
		var sizeInverse = 1 / size;

		if (this._camera.isOrthographicCamera) {
			// camera zoom
			this._camera.zoom = this._zoomState;
			this._camera.zoom *= size;

			// check min and max zoom
			if (this._camera.zoom > this.maxZoom) {
				this._camera.zoom = this.maxZoom;
				sizeInverse = this._zoomState / this.maxZoom;
			} else if (this._camera.zoom < this.minZoom) {
				this._camera.zoom = this.minZoom;
				sizeInverse = this._zoomState / this.minZoom;
			}

			this._camera.updateProjectionMatrix();

			this._v3_1.setFromMatrixPosition(this._gizmoMatrixState);	// gizmos position

			// scale gizmos so they appear in the same spot having the same dimension
			this._scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);
			this._translationMatrix.makeTranslation(-this._v3_1.x, -this._v3_1.y, -this._v3_1.z);

			this._m4_2.makeTranslation(this._v3_1.x, this._v3_1.y, this._v3_1.z).multiply(this._scaleMatrix);
			this._m4_2.multiply(this._translationMatrix);

			// move camera and gizmos to obtain pinch effect
			_scalePointTemp.sub(this._v3_1);

			var amount = _scalePointTemp.clone().multiplyScalar(sizeInverse);
			_scalePointTemp.sub(amount);

			this._m4_1.makeTranslation(_scalePointTemp.x, _scalePointTemp.y, _scalePointTemp.z);
			this._m4_2.premultiply(this._m4_1);

			this.setTransformationMatrices(this._m4_1, this._m4_2);
			return _transformation;
		} else if (this._camera.isPerspectiveCamera) {
			this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
			this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);

			// move camera
			var distance = this._v3_1.distanceTo(_scalePointTemp);
			var amount = distance - (distance * sizeInverse);

			// check min and max distance
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
				// scale gizmos so they appear in the same spot having the same dimension
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

	public function setFov(value:Float):Void {
		if (this._camera.isPerspectiveCamera) {
			this._camera.fov = MathUtils.clamp(value, this.minFov, this.maxFov);
			this._camera.updateProjectionMatrix();
		}
	}

	public function setTransformationMatrices(camera:Matrix4 = null, gizmos:Matrix4 = null):Void {
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

	public function focus(point:Vector3, size:Float = 1, amount:Float = 1):Void {
		//move camera
		this._v3_1.setFromMatrixPosition(this._cameraMatrixState);
		this._v3_2.setFromMatrixPosition(this._gizmoMatrixState);

		var distance = this._v3_1.distanceTo(point);
		var amount = distance - (distance * size);

		//check min and max distance
		var newDistance = distance - amount;
		if (newDistance < this.minDistance) {
			size = this.minDistance / distance;
			amount = distance - (distance * size);
		} else if (newDistance > this.maxDistance) {
			size = this.maxDistance / distance;
			amount = distance - (distance * size);
		}

		_offset.copy(point).sub(this._v3_1).normalize().multiplyScalar(amount);

		this._m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);

		//move gizmos
		if (this._camera.isPerspectiveCamera) {
			distance = this._v3_2.distanceTo(point);
			amount = distance - (distance * size);

			_offset.copy(point).sub(this._v3_2).normalize().multiplyScalar(amount);

			this._translationMatrix.makeTranslation(this._v3_2.x, this._v3_2.y, this._v3_2.z);
			this._scaleMatrix.makeScale(size, size, size);

			this._m4_2.makeTranslation(_offset.x, _offset.y, _offset.z).multiply(this._translationMatrix);
			this._m4_2.multiply(this._scaleMatrix);

			this._translationMatrix.makeTranslation(-this._v3_2.x, -this._v3_2.y, -this._v3_2.z);

			this._m4_2.multiply(this._translationMatrix);
			this.setTransformationMatrices(this._m4_1, this._m4_2);

		} else {
			this.setTransformationMatrices(this._m4_1);
		}

		this.dispatchEvent(_changeEvent);
	}

	public function updateTbState(state:STATE, activateGizmos:Bool = true):Void {
		this._state = state;
		this.activateGizmos(activateGizmos);
	}

	public function activateGizmos(active:Bool):Void {
		if (active) {
			this._gizmos.visible = true;
		} else {
			this._gizmos.visible = false;
		}
	}

	public function calculateTbRadius(camera:PerspectiveCamera):Float {
		var tbRadius:Float;
		var height = HXT.window.innerHeight;
		var width = HXT.window.innerWidth;
		var aspect = width / height;
		var fov = camera.fov;

		if (camera.isPerspectiveCamera) {
			tbRadius = height * 0.5 * Math.tan(fov * 0.5 * Math.PI / 180) * this.radiusFactor;
		} else if (camera.isOrthographicCamera) {
			tbRadius = height * 0.5 * this.radiusFactor;
		}

		return tbRadius;
	}

	public function applyTransformMatrix(matrix:Matrix4):Void {
		this._camera.applyMatrix4(matrix);
		this._camera.updateMatrix();
		this._camera.updateProjectionMatrix();

		this.setTransformationMatrices(matrix);
		this._gizmoMatrixState.premultiply(matrix);
		this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
		this._gizmos.updateMatrix();
	}

	public function setStateFromJSON(json:String):Void {
		var state = JSON.parse(json);
		var arcballState = state.arcballState;

		if (this._camera.isOrthographicCamera) {
			this._camera.far = arcballState.cameraFar;
			this._camera.matrix.copy(arcballState.cameraMatrix);
			this._camera.near = arcballState.cameraNear;
			this._camera.up.copy(arcballState.cameraUp);
			this._camera.zoom = arcballState.cameraZoom;
			this._gizmos.matrix.copy(arcballState.gizmoMatrix);
		} else if (this._camera.isPerspectiveCamera) {
			this._camera.far = arcballState.cameraFar;
			this._camera.fov = arcballState.cameraFov;
			this._camera.matrix.copy(arcballState.cameraMatrix);
			this._camera.near = arcballState.cameraNear;
			this._camera.up.copy(arcballState.cameraUp);
			this._camera.zoom = arcballState.cameraZoom;
			this._gizmos.matrix.copy(arcballState.gizmoMatrix);
		}

		this._camera.updateMatrix();
		this._camera.updateProjectionMatrix();

		this._gizmoMatrixState.copy(this._gizmos.matrix);
		this._gizmoMatrixState.decompose(this._gizmos.position, this._gizmos.quaternion, this._gizmos.scale);
		this._gizmos.updateMatrix();

		this.dispatchEvent(_changeEvent);
	}

	public function easeOutCubic(t:Float):Float {
		return 1 - Math.pow(1 - t, 3);
	}

	public function addEventListener(type:String, listener:Dynamic, useCapture:Bool = false):Void {
		this._changeEvent.addEventListener(type, listener, useCapture);
	}

	public function removeEventListener(type:String, listener:Dynamic, useCapture:Bool = false):Void {
		this._changeEvent.removeEventListener(type, listener, useCapture);
	}

	public function dispatchEvent(event:Event):Bool {
		return this._changeEvent.dispatchEvent(event);
	}

	public function hasEventListener(type:String):Bool {
		return this._changeEvent.hasEventListener(type);
	}

	private function dispose():Void {
		this._gizmos.dispose();
		this._cameraMatrixState.dispose();
		this._cameraMatrixState0.dispose();
		this._gizmoMatrixState.dispose();
		this._gizmoMatrixState0.dispose();
		this._scaleMatrix.dispose();
		this._translationMatrix.dispose();
		this._rotationMatrix.dispose();
		this._v3_1.dispose();
		this._v3_2.dispose();
		this._m4_1.dispose();
		this._m4_2.dispose();
		this._offset.dispose();
		this._scalePointTemp.dispose();
	}
}

enum STATE {
	IDLE;
	ANIMATION_FOCUS;
	ANIMATION_ROTATE;
	ROTATE;
	PAN;
}

class Transformation {
	public var camera:Matrix4;
	public var gizmos:Matrix4;
}

var _transformation:Transformation = new Transformation();