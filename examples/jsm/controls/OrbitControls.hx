import haxe.math.Math3D;
import haxe.math.MathConst;
import openfl.events.EventDispatcher;
import openfl.geom.Vector2;
import openfl.geom.Vector3;
import openfl.geom.Vector4;
import openfl.math.Matrix3D;

class OrbitControls extends EventDispatcher {

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

	public function new(object:Dynamic, domElement:Dynamic) {
		super();

		this.object = object;
		this.domElement = domElement;
		domElement.style.touchAction = "none";

		this.enabled = true;

		this.target = new Vector3();
		this.cursor = new Vector3();

		this.minDistance = 0;
		this.maxDistance = Float.MAX_VALUE;

		this.minZoom = 0;
		this.maxZoom = Float.MAX_VALUE;

		this.minTargetRadius = 0;
		this.maxTargetRadius = Float.MAX_VALUE;

		this.minPolarAngle = 0;
		this.maxPolarAngle = MathConst.PI;

		this.minAzimuthAngle = -MathConst.PI;
		this.maxAzimuthAngle = MathConst.PI;

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

		this.keys = { LEFT: "ArrowLeft", UP: "ArrowUp", RIGHT: "ArrowRight", BOTTOM: "ArrowDown" };
		this.mouseButtons = { LEFT: 0, MIDDLE: 1, RIGHT: 2 };
		this.touches = { ONE: 0, TWO: 1 };

		this.target0 = this.target.clone();
		this.position0 = this.object.position.clone();
		this.zoom0 = this.object.zoom;

		this._domElementKeyEvents = null;

		this.getPolarAngle = this.getPolarAngle_gen;
		this.getAzimuthalAngle = this.getAzimuthalAngle_gen;
		this.getDistance = this.getDistance_gen;
		this.listenToKeyEvents = this.listenToKeyEvents_gen;
		this.stopListenToKeyEvents = this.stopListenToKeyEvents_gen;
		this.saveState = this.saveState_gen;
		this.reset = this.reset_gen;
		this.update = this.update_gen;
		this.dispose = this.dispose_gen;
	}

	public function getPolarAngle_gen():Float {
		return spherical.phi;
	}

	public function getAzimuthalAngle_gen():Float {
		return spherical.theta;
	}

	public function getDistance_gen():Float {
		return this.object.position.distanceTo(this.target);
	}

	public function listenToKeyEvents_gen(domElement:Dynamic) {
		domElement.addEventListener("keydown", onKeyDown);
		this._domElementKeyEvents = domElement;
	}

	public function stopListenToKeyEvents_gen() {
		this._domElementKeyEvents.removeEventListener("keydown", onKeyDown);
		this._domElementKeyEvents = null;
	}

	public function saveState_gen() {
		scope.target0.copy(scope.target);
		scope.position0.copy(scope.object.position);
		scope.zoom0 = scope.object.zoom;
	}

	public function reset_gen() {
		scope.target.copy(scope.target0);
		scope.object.position.copy(scope.position0);
		scope.object.zoom = scope.zoom0;
		scope.object.updateProjectionMatrix();
		scope.dispatchEvent(_changeEvent);
		scope.update();
		state = STATE.NONE;
	}

	public function update_gen(deltaTime:Dynamic = null) {
		// Implement the update logic here
	}

	public function dispose_gen() {
		scope.domElement.removeEventListener("contextmenu", onContextMenu);
		scope.domElement.removeEventListener("pointerdown", onPointerDown);
		scope.domElement.removeEventListener("pointercancel", onPointerUp);
		scope.domElement.removeEventListener("wheel", onMouseWheel);
		const document = scope.domElement.getRootNode();
		document.removeEventListener("keydown", interceptControlDown, { capture: true });
		if (scope._domElementKeyEvents != null) {
			scope._domElementKeyEvents.removeEventListener("keydown", onKeyDown);
			scope._domElementKeyEvents = null;
		}
	}

	private var _changeEvent:Dynamic = { type: "change" };
	private var _startEvent:Dynamic = { type: "start" };
	private var _endEvent:Dynamic = { type: "end" };
	private var _ray:Ray = new Ray();
	private var _plane:Plane = new Plane();
	private var TILT_LIMIT:Float = Math.cos(70 * MathUtils.DEG2RAD);

	// Add the rest of the OrbitControls implementation here
}