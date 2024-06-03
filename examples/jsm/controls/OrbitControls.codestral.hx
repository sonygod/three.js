import three.EventDispatcher;
import three.MOUSE;
import three.Quaternion;
import three.Spherical;
import three.TOUCH;
import three.Vector2;
import three.Vector3;
import three.Plane;
import three.Ray;
import three.MathUtils;

class OrbitControls extends EventDispatcher {
    private var _changeEvent = { type: 'change' };
    private var _startEvent = { type: 'start' };
    private var _endEvent = { type: 'end' };
    private static var _ray = new Ray();
    private static var _plane = new Plane();
    private static var TILT_LIMIT = Math.cos(70 * MathUtils.DEG2RAD);

    public var object:Dynamic;
    public var domElement:Dynamic;

    public var enabled:Bool = true;
    public var target:Vector3 = new Vector3();
    public var cursor:Vector3 = new Vector3();
    public var minDistance:Float = 0;
    public var maxDistance:Float = Float.POSITIVE_INFINITY;
    public var minZoom:Float = 0;
    public var maxZoom:Float = Float.POSITIVE_INFINITY;
    public var minTargetRadius:Float = 0;
    public var maxTargetRadius:Float = Float.POSITIVE_INFINITY;
    public var minPolarAngle:Float = 0;
    public var maxPolarAngle:Float = Math.PI;
    public var minAzimuthAngle:Float = Float.NEGATIVE_INFINITY;
    public var maxAzimuthAngle:Float = Float.POSITIVE_INFINITY;
    public var enableDamping:Bool = false;
    public var dampingFactor:Float = 0.05;
    public var enableZoom:Bool = true;
    public var zoomSpeed:Float = 1.0;
    public var enableRotate:Bool = true;
    public var rotateSpeed:Float = 1.0;
    public var enablePan:Bool = true;
    public var panSpeed:Float = 1.0;
    public var screenSpacePanning:Bool = true;
    public var keyPanSpeed:Float = 7.0;
    public var zoomToCursor:Bool = false;
    public var autoRotate:Bool = false;
    public var autoRotateSpeed:Float = 2.0;
    public var keys:Dynamic = { LEFT: 'ArrowLeft', UP: 'ArrowUp', RIGHT: 'ArrowRight', BOTTOM: 'ArrowDown' };
    public var mouseButtons:Dynamic = { LEFT: MOUSE.ROTATE, MIDDLE: MOUSE.DOLLY, RIGHT: MOUSE.PAN };
    public var touches:Dynamic = { ONE: TOUCH.ROTATE, TWO: TOUCH.DOLLY_PAN };
    public var target0:Vector3;
    public var position0:Vector3;
    public var zoom0:Float;
    private var _domElementKeyEvents:Dynamic;

    public function new(object:Dynamic, domElement:Dynamic) {
        super();

        this.object = object;
        this.domElement = domElement;
        this.domElement.style.touchAction = 'none';

        this.target0 = this.target.clone();
        this.position0 = this.object.position.clone();
        this.zoom0 = this.object.zoom;

        this.domElement.addEventListener('contextmenu', onContextMenu);
        this.domElement.addEventListener('pointerdown', onPointerDown);
        this.domElement.addEventListener('pointercancel', onPointerUp);
        this.domElement.addEventListener('wheel', onMouseWheel);

        var document = this.domElement.getRootNode();
        document.addEventListener('keydown', interceptControlDown, { capture: true });
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
        this.target0.copy(this.target);
        this.position0.copy(this.object.position);
        this.zoom0 = this.object.zoom;
    }

    public function reset() {
        this.target.copy(this.target0);
        this.object.position.copy(this.position0);
        this.object.zoom = this.zoom0;

        this.object.updateProjectionMatrix();
        this.dispatchEvent(_changeEvent);

        this.update();

        state = STATE.NONE;
    }

    public function update():Bool {
        var offset = new Vector3();
        var quat = new Quaternion().setFromUnitVectors(object.up, new Vector3(0, 1, 0));
        var quatInverse = quat.clone().invert();
        var lastPosition = new Vector3();
        var lastQuaternion = new Quaternion();
        var lastTargetPosition = new Vector3();
        var twoPI = 2 * Math.PI;

        return function(deltaTime:Float = null):Bool {
            //... rest of the update function
        };
    }

    public function dispose() {
        //... rest of the dispose function
    }

    //... rest of the class methods and internals
}