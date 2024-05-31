import three.Cameras.OrthographicCamera;
import three.Cameras.PerspectiveCamera;
import three.Core.Object3D;
import three.Core.Raycaster;
import three.Geometries.BufferGeometry;
import three.Materials.LineBasicMaterial;
import three.Materials.MeshBasicMaterial;
import three.Math.Color;
import three.Math.EllipseCurve;
import three.Math.Euler;
import three.Math.Matrix3;
import three.Math.Matrix4;
import three.Math.MathUtils;
import three.Math.Quaternion;
import three.Math.Spherical;
import three.Math.Vector2;
import three.Math.Vector3;
import three.Objects.Group;
import three.Objects.Line;
import three.Objects.Mesh;
import three.Scenes.Scene;

@:enum
abstract InputType(Int) {
  var NONE = 0;
  var ONE_FINGER = 1;
  var TWO_FINGER = 2;
  var MULT_FINGER = 3;
  var CURSOR = 4;
  var ONE_FINGER_SWITCHED = 5;
}

@:enum
abstract State(Int) {
	var IDLE = 0;
	var ROTATE = 1;
	var PAN = 2;
	var SCALE = 3;
	var FOV = 4;
	var FOCUS = 5;
	var ZROTATION = 6;
}

@:structInit
class PointerData {
  public var pointerId:Int;
  public var x:Float;
  public var y:Float;

  public function new(pointerId:Int, x:Float, y:Float) {
    this.pointerId = pointerId;
    this.x = x;
    this.y = y;
  }
}

class ArcballControls {

  // static readonly _changeEvent = { type: 'change' };
  // static readonly _startEvent = { type: 'start' };
  // static readonly _endEvent = { type: 'end' };
  static var _changeEvent(get,never): { type: String };
  static function get__changeEvent(): { type: String } {
    return { type: 'change' };
  }
  static var _startEvent(get,never): { type: String };
  static function get__startEvent(): { type: String } {
    return { type: 'start' };
  }
  static var _endEvent(get,never): { type: String };
  static function get__endEvent(): { type: String } {
    return { type: 'end' };
  }
	
	public var camera(get, set):Dynamic;
	public var domElement:Dynamic;
	public var scene:Scene; // optional
	public var target:Vector3;

	public var enablePan:Bool;
	public var enableRotate:Bool;
	public var enableZoom:Bool;

	public var minDistance:Float;
	public var maxDistance:Float;

	public var minFov:Float;
	public var maxFov:Float;

	public var minZoom:Float;
	public var maxZoom:Float;

	public var cursorZoom:Bool;
	public var scaleFactor:Float;

	public var enableAnimations:Bool;
	public var animations:Array<Dynamic> = [];
	public var tweens:Dynamic; // not sure about the type here

	public var adjustNearFar:Bool;

	public var grid:Dynamic; // not sure about the type here
	public var gridColor:Color;

  // constructor
  public function new(camera:Dynamic, domElement:Dynamic, scene:Scene = null) {
    // this.camera = null;
		// this.domElement = null; // if null, default to document.documentElement
		// this.scene = null; // optional
		// this.target = new Vector3();

    this.camera = camera;
    this.domElement = domElement != null ? domElement : window.document.documentElement;
    this.scene = scene;
    this.target = new Vector3();
		
		// rotation
		this._spherical = new Spherical();
		this._sphericalDelta = new Spherical();
		this._sphericalDump = new Spherical();

		this._euclidean = new Vector3();
		this._rotationAxis = new Vector3( 1, 0, 0 );

		this._isDragging = false;

		// pan
		this._panOffset = new Vector3();
		this._panStart = new Vector2();
		this._panEnd = new Vector2();

		// zoom
		this._scaleStart = new Vector2();
		this._scaleEnd = new Vector2();

		// focus
		this._focusStart = new Vector2();
		this._focusEnd = new Vector2();

		// rotation inertia
		this._rotationVelocity = 0;
		this._rotationAngle = 0;
		this._lastTime = performance.now();

		// parameters
		this.enablePan = true;
		this.enableRotate = true;
		this.enableZoom = true;

		this.minDistance = 0;
		this.maxDistance = Infinity;

		this.minFov = 1;
		this.maxFov = 180;

		this.minZoom = 0;
		this.maxZoom = Infinity;

		this.cursorZoom = false;
		this.scaleFactor = 1.1;

		this.enableAnimations = false; // set to true to enable animations
		this.animations = [];
		this.tweens = {  }; // here you can override any setting of TweenJS / GSAP

		this.adjustNearFar = false;

		this.grid = null;
		this.gridColor = new Color( 0x888888 );
  }

	public function get camera():Dynamic {
		return this._camera;
	}

	public function set camera(value:Dynamic):Dynamic {
		this._camera = value;
		this._camera.lookAt( this.target );
		return value;
	}
  
	// create setters and getters for all public members
	// ... 
	
}