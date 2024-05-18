import haxe.ds.EnumValue;
import haxe.ds.Option;
import haxe.ds.BalancedTree;
import haxe.math.Vector3;
import haxe.math.Quaternion;
import haxe.math.Matrix4;
import haxe.math.Ray;
import haxe.math.Intersection;
import three.core.Object3D;
import three.math.Color;

class TransformControls extends Object3D {

	public var isTransformControls:Bool;
	public var visible:Bool;
	public var domElement:Dynamic;
	public var dragging:Bool;
	public var axis:String;
	public var mode:TransformMode;
	public var translationSnap:Float;
	public var rotationSnap:Float;
	public var scaleSnap:Float;
	public var space:TransformSpace;
	public var size:Float;
	public var _gizmo:TransformControlsGizmo;
	public var _plane:TransformControlsPlane;
	public var _offset:Vector3;
	public var _startNorm:Vector3;
	public var _endNorm:Vector3;
	public var _cameraScale:Vector3;
	public var _parentPosition:Vector3;
	public var _parentQuaternion:Quaternion;
	public var _parentQuaternionInv:Quaternion;
	public var _parentScale:Vector3;
	public var _worldScaleStart:Vector3;
	public var _worldQuaternionInv:Quaternion;
	public var _worldScale:Vector3;
	public var _positionStart:Vector3;
	public var _quaternionStart:Quaternion;
	public var _scaleStart:Vector3;
	public var _changeEvent:Dynamic;
	public var _objectChangeEvent:Dynamic;
	public var _mouseDownEvent:Dynamic;

	public function new(camera:Camera, domElement:Dynamic) {
		super();
		this.isTransformControls = true;
		this.visible = false;
		this.domElement = domElement;
		this.domElement.style.touchAction = 'none'; // disable touch scroll
		this._gizmo = new TransformControlsGizmo();
		this.add(_gizmo);
		this._plane = new TransformControlsPlane();
		this.add(_plane);
		this._offset = new Vector3();
		this._startNorm = new Vector3();
		this._endNorm = new Vector3();
		this._cameraScale = new Vector3();
		this._parentPosition = new Vector3();
		this._parentQuaternion = new Quaternion();
		this._parentQuaternionInv = new Quaternion();
		this._parentScale = new Vector3();
		this._worldScaleStart = new Vector3();
		this._worldQuaternionInv = new Quaternion();
		this._worldScale = new Vector3();
		this._positionStart = new Vector3();
		this._quaternionStart = new Quaternion();
		this._scaleStart = new Vector3();
		this._changeEvent = { type:null, value:null };
		this._objectChangeEvent = { type:null, value:null };
		this._mouseDownEvent = { type:null, mode:null };
		this.mode = TransformMode.Translate;
		this.space = TransformSpace.World;
		this.size = 1.0;
		this.defineProperty("camera", camera);
		this.defineProperty("object", null);
		this.defineProperty("enabled", true);
		this.defineProperty("axis", null);
		this.defineProperty("mode", TransformMode.Translate);
		this.defineProperty("translationSnap", null);
		this.defineProperty("rotationSnap", null);
		this.defineProperty("scaleSnap", null);
		this.defineProperty("space", TransformSpace.World);
		this.defineProperty("size", 1);
		this.defineProperty("dragging", false);
		this.defineProperty("showX", true);
		this.defineProperty("showY", true);
		this.defineProperty("showZ", true);
		this._getPointer = getPointer.bind(this);
		this._onPointerDown = onPointerDown.bind(this);
		this._onPointerHover = onPointerHover.bind(this);
		this._onPointerMove = onPointerMove.bind(this);
		this._onPointerUp = onPointerUp.bind(this);
		this.domElement.addEventListener("pointerdown", this._onPointerDown);
		this.domElement.addEventListener("pointermove", this._onPointerHover);
		this.domElement.addEventListener("pointerup", this._onPointerUp);
	}

	override public function updateMatrixWorld(force:Bool) {
		if (this.object !== undefined) {
			this.object.updateMatrixWorld();
			if (this.object.parent === null) {
				trace("TransformControls: The attached 3D object must be a part of the scene graph.");
			} else {
				this.object.parent.matrixWorld.decompose(this._parentPosition, this._parentQuaternion, this._parentScale);
			}
			this.object.matrixWorld.decompose(this.worldPosition, this.worldQuaternion, this._worldScale);
			this._parentQuaternionInv.copy(this._parentQuaternion).invert();
			this._worldQuaternionInv.copy(this.worldQuaternion).invert();
		}
		this.camera.updateMatrixWorld();
		this.camera.matrixWorld.decompose(this.cameraPosition, this.cameraQuaternion, this._cameraScale);
		if (this.camera.isOrthographicCamera) {
			this.camera.getWorldDirection(this.eye).negate();
		} else {
			this.eye.copy(this.cameraPosition).sub(this.worldPosition).normalize();
		}
		super.updateMatrixWorld(force);
	}

	public function defineProperty(propName:String, defaultValue:Dynamic) {
		var propValue:Dynamic = defaultValue;
		Object.defineProperty(this, propName, {
			get: function () {
				return propValue !== undefined ? propValue : defaultValue;
			},
			set: function (value) {
				if (propValue !== value) {
					propValue = value;
					_plane[propName] = value;
					_gizmo[propName] = value;
					this.dispatchEvent(_changeEvent.set("type", propName + "-changed").set("value", value));
					this.dispatchEvent(_changeEvent.set("type", "change").set("value", value));
				}
			}
		});
		this[propName] = defaultValue;
		_plane[propName] = defaultValue;
		_gizmo[propName] = defaultValue;
	}

	public function pointerHover(pointer:Dynamic) {
		if (this.object === undefined || this.dragging === true) return;
		if (pointer !== null) _raycaster.setFromCamera(pointer, this.camera);
		var intersect = intersectObjectWithRay(this._gizmo.picker[this.mode], _raycaster);
		if (intersect) {
			this.axis = intersect.object.name;
		} else {
			this.axis = null;
		}
	}

	public function pointerDown(pointer:Dynamic) {
		if (this.object === undefined || this.dragging === true || (pointer != null && pointer.button !== 0)) return;
		if (this.axis !== null) {
			if (pointer !== null) _raycaster.setFromCamera(pointer, this.camera);
			var planeIntersect = intersectObjectWithRay(this._plane, _raycaster, true);
			if (planeIntersect) {
				this.object.updateMatrixWorld();
				this.object.parent.updateMatrixWorld();
				this._positionStart.copy(this.object.position);
				this._quaternionStart.copy(this.object.quaternion);
				this._scaleStart.copy(this.object.scale);
				this.worldPositionStart.copy(this.object.position);
				this.pointStart.copy(planeIntersect.point).sub(this.worldPositionStart);
				this.dragging = true;
				this._mouseDownEvent.set("mode", this.mode);
				this.dispatchEvent(this._mouseDownEvent);
			}
		}
	}

	public function pointerMove(pointer:Dynamic) {
		if (this.object === undefined || this.axis === null || this.dragging === false || (pointer !== null && pointer.button !== -1)) return;
		if (pointer !== null) _raycaster.setFromCamera(pointer, this.camera);
		var planeIntersect = intersectObjectWithRay(this._plane, _raycaster, true);
		if (!planeIntersect) return;
		this.pointEnd.copy(planeIntersect.point).sub(this.worldPositionStart);
		if (this.mode === TransformMode.Translate) {
			// Apply translate
			this._offset.copy(this.pointEnd).sub(this.pointStart);
			if (this.space === TransformSpace.Local && this.axis !== "XYZ") {
				this._offset.applyQuaternion(this._worldQuaternionInv);
			}
			if (this.axis.indexOf("X") === -1) this._offset.x = 0;
			if (this.axis.indexOf("Y") === -1) this._offset.y = 0;
			if (this.axis.indexOf("Z") === -1) this._offset.z = 0;
			if (this.space === TransformSpace.Local && this.axis !== "XYZ") {
				this._offset.applyQuaternion(this._quaternionStart).divide(this._parentScale);
			} else {
				this._offset.applyQuaternion(this._parentQuaternionInv).divide(this._parentScale);
			}
			this.object.position.copy(this._offset).add(this._positionStart);
			// Apply translation snap
			if (this.translationSnap) {
				if (this.space === TransformSpace.Local) {
					this.object.position.applyQuaternion(this._quaternionStart.invert());
					if (this.axis.search("X") !== -1) {
						this.object.position.x = Math.round(this.object.position.x / this.translationSnap) * this.translationSnap;
					}
					if (this.axis.search("Y") !== -1) {
						this.object.position.y = Math.round(this.object.position.y / this.translationSnap) * this.translationSnap;
					}
					if (this.axis.search("Z") !== -1) {
						this.object.position.z = Math.round(this.object.position.z / this.translationSnap) * this.translationSnap;
					}
					this.object.position.applyQuaternion(this._quaternionStart);
				}
				if (this.space === TransformSpace.World) {
					if (this.object.parent) {
						this.object.position.add(this._tempVector.setFromMatrixPosition(this.object.parent.matrixWorld));
					}
					if (this.axis.search("X") !== -1) {
						this.object.position.x = Math.round(this.object.position.x / this.translationSnap) * this.translationSnap;
					}
					if (this.axis.search("Y") !== -1) {
						this.object.position.y = Math.round(this.object.position.y / this.translationSnap) * this.translationSnap;
					}
					if (this.axis.search("Z") !== -1) {
						this.object.position.z = Math.round(this.object.position.z / this.translationSnap) * this.translationSnap;
					}
					if (this.object.parent) {
						this.object.position.sub(this._tempVector.setFromMatrixPosition(this.object.parent.matrixWorld));
					}
				}
			}
		} else if (this.mode === TransformMode.Rotate) {
			// Apply rotate
			this._offset.copy(this.pointEnd).sub(this.pointStart);
			var ROTATION_SPEED = 20 / this.worldPosition.distanceTo(this._tempVector.setFromMatrixPosition(this.camera.matrixWorld));
			var _inPlaneRotation = false;
			if (this.axis === "XYZE") {
				this.rotationAxis.copy(this._offset).cross(this.eye).normalize();
				this.rotationAngle = this._offset.dot(this._tempVector.copy(this.rotationAxis).cross(this.eye)) * ROTATION_SPEED;
			} else if (this.axis === "X" || this.axis === "Y" || this.axis === "Z") {
				this.rotationAxis.copy(_unit[axis]);
				_tempVector.copy(this._unit[axis]);
				if (space === TransformSpace.Local) {
					_tempVector.applyQuaternion(this.worldQuaternion);
				}
				_tempVector.cross(this.eye);
				// When _tempVector is 0 after cross with this.eye the vectors are parallel and should use in-plane rotation logic.
				if (_tempVector.length() === 0) {
					_inPlaneRotation = true;
				} else {
					this.rotationAngle = this._offset.dot(this._tempVector.normalize()) * ROTATION_SPEED;
				}
			}
			if (this.axis === "E" || _inPlaneRotation) {
				this.rotationAxis.copy(this.eye);
				this.rotationAngle = this.pointEnd.angleTo(this.pointStart);
				this._startNorm.copy(this.pointStart).normalize();
				this._endNorm.copy(this.pointEnd).normalize();
				this.rotationAngle *= (this._endNorm.cross(this._startNorm).dot(this.eye) < 0 ? 1 : -1);
			}
			// Apply rotation snap
			if (this.rotationSnap) this.rotationAngle = Math.round(this.rotationAngle / this.rotationSnap) * this.rotationSnap;
			// Apply rotate
			if (space === TransformSpace.Local && this.axis !== "E" && this.axis !== "XYZE") {
				this.object.quaternion.copy(this._quaternionStart);
				this.object.quaternion.multiply(this._tempQuaternion.setFromAxisAngle(this.rotationAxis, this.rotationAngle)).normalize();
			} else {
				this.rotationAxis.applyQuaternion(this._parentQuaternionInv);
				this.object.quaternion.copy(this._tempQuaternion.setFromAxisAngle(this.rotationAxis, this.rotationAngle));
				this.object.quaternion.multiply(this._quaternionStart).normalize();
			}
		} else if (this.mode === TransformMode.Scale) {
			// Apply scale
			this.object.scale.copy(this._scaleStart).multiply(this._tempVector2);
			// Apply scale snap
			if (this.scaleSnap) {
				if (this.axis.search("X") !== -1) {
					this.object.scale.x = Math.round(this.object.scale.x / this.scaleSnap) * this.scaleSnap || this.scaleSnap;
				}
				if (this.axis.search("Y") !== -1) {
					this.object.scale.y = Math.round(this.object.scale.y / this.scaleSnap) * this.scaleSnap || this.scaleSnap;
				}
				if (this.axis.search("Z") !== -1) {
					this.object.scale.z = Math.round(this.object.scale.z / this.scaleSnap) * this.scaleSnap || this.scaleSnap;
				}
			}
		}
		this.dispatchEvent(this._changeEvent.set("type", "change").set("value", null));
		this.dispatchEvent(this._objectChangeEvent.set("type", "objectChange").set("value", null));
	}

	public function pointerUp(pointer:Dynamic) {
		if (pointer !== null && pointer.button !== 0) return;
		if (this.dragging && (this.axis !== null)) {
			this._mouseUpEvent.set("mode", this.mode);
			this.dispatchEvent(this._mouseUpEvent);
		}
		this.dragging = false;
		this.axis = null;
	}

	public function dispose() {
		this.domElement.removeEventListener("pointerdown", this._onPointerDown);
		this.domElement.removeEventListener("pointermove", this._onPointerHover);
		this.domElement.removeEventListener("pointermove", this._onPointerMove);
		this.domElement.removeEventListener("pointerup", this._onPointerUp);
		this.traverse(function (child:Dynamic) {
			if (child.geometry) child.geometry.dispose();
			if (child.material) child.material.dispose();
		});
	}

	// Set current object
	public function attach(object:Object3D) {
		this.object = object;
		this.visible = true;
		return this;
	}

	// Detach from object
	public function detach() {
		this.object = undefined;
		this.visible = false;
		this.axis = null;
		return this;
	}

	// Reset transform
	public function reset() {
		if (!this.enabled) return;
		if (this.dragging) {
			this.object.position.copy(this._positionStart);
			this.object.quaternion.copy(this._quaternionStart);
			this.object.scale.copy(this._scaleStart);
			this.dispatchEvent(this._changeEvent.set("type", "change").set("value", null));
			this.dispatchEvent(this._objectChangeEvent.set("type", "objectChange").set("value", null));
			this.pointStart.copy(this.pointEnd);
		}
	}

	// Get raycaster
	public function getRaycaster() {
		return _raycaster;
	}

	// Deprecated
	public function getMode() {
		return this.mode;
	}

	public function setMode(mode:TransformMode) {
		this.mode = mode;
	}

	public function setTranslationSnap(translationSnap:Float) {
		this.translationSnap = translationSnap;
	}

	public function setRotationSnap(rotationSnap:Float) {
		this.rotationSnap = rotationSnap;
	}

	public function setScaleSnap(scaleSnap:Float) {
		this.scaleSnap = scaleSnap;
	}

	public function setSize(size:Float) {
		this.size = size;
	}

	public function setSpace(space:TransformSpace) {
		this.space = space;
	}

}

enum TransformMode {
	Translate,
	Rotate,
	Scale
}

enum TransformSpace {
	World,
	Local
}