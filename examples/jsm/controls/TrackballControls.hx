import three.events.EventDispatcher;
import three.math._Math;
import three.math.Vector2;
import three.math.Vector3;

class TrackballControls extends EventDispatcher {

	public var object:Dynamic;
	public var domElement:Dynamic;
	public var enabled:Bool;

	public var screen: { left:Float, top:Float, width:Float, height:Float };

	public var rotateSpeed:Float;
	public var zoomSpeed:Float;
	public var panSpeed:Float;

	public var noRotate:Bool;
	public var noZoom:Bool;
	public var noPan:Bool;

	public var staticMoving:Bool;
	public var dynamicDampingFactor:Float;

	public var minDistance:Float;
	public var maxDistance:Float;

	public var minZoom:Float;
	public var maxZoom:Float;

	public var keys:Array<String>;
	public var mouseButtons: { LEFT:Int, MIDDLE:Int, RIGHT:Int };

	private var _changeEvent:Dynamic;
	private var _startEvent:Dynamic;
	private var _endEvent:Dynamic;

	private var STATE: { NONE:Int, ROTATE:Int, ZOOM:Int, PAN:Int, TOUCH_ROTATE:Int, TOUCH_ZOOM_PAN:Int };
	private var _state:Int;
	private var _keyState:Int;

	private var _touchZoomDistanceStart:Float;
	private var _touchZoomDistanceEnd:Float;
	private var _lastAngle:Float;

	private var _eye:Vector3;
	private var _movePrev:Vector2;
	private var _moveCurr:Vector2;
	private var _lastAxis:Vector3;
	private var _zoomStart:Vector2;
	private var _zoomEnd:Vector2;
	private var _panStart:Vector2;
	private var _panEnd:Vector2;
	private var _pointers:Array<Dynamic>;
	private var _pointerPositions: { [index:Int]:Vector2 };

	private var target0:Vector3;
	private var position0:Vector3;
	private var up0:Vector3;
	private var zoom0:Float;

	public function new(object:Dynamic, domElement:Dynamic) {
		super();
		
		this.enabled = true;
		this.screen = { left: 0, top: 0, width: 0, height: 0 };
		this.rotateSpeed = 1.0;
		this.zoomSpeed = 1.2;
		this.panSpeed = 0.3;
		this.noRotate = false;
		this.noZoom = false;
		this.noPan = false;
		this.staticMoving = false;
		this.dynamicDampingFactor = 0.2;
		this.minDistance = 0;
		this.maxDistance = _Math.INFINITY;
		this.minZoom = 0;
		this.maxZoom = _Math.INFINITY;
		this.keys = ['KeyA', 'KeyS', 'KeyD'];
		this.mouseButtons = { LEFT: 0, MIDDLE: 1, RIGHT: 2 };

		this._changeEvent = { type: 'change' };
		this._startEvent = { type: 'start' };
		this._endEvent = { type: 'end' };

		this.STATE = { NONE: -1, ROTATE: 0, ZOOM: 1, PAN: 2, TOUCH_ROTATE: 3, TOUCH_ZOOM_PAN: 4 };
		this._state = this.STATE.NONE;
		this._keyState = this.STATE.NONE;

		this._touchZoomDistanceStart = 0;
		this._touchZoomDistanceEnd = 0;
		this._lastAngle = 0;

		this._eye = new Vector3();
		this._movePrev = new Vector2();
		this._moveCurr = new Vector2();
		this._lastAxis = new Vector3();
		this._zoomStart = new Vector2();
		this._zoomEnd = new Vector2();
		this._panStart = new Vector2();
		this._panEnd = new Vector2();
		this._pointers = [];
		this._pointerPositions = {};

		this.target0 = object.position.clone();
		this.position0 = object.position.clone();
		this.up0 = object.up.clone();
		this.zoom0 = object.zoom;

		this.handleResize();
	}

	private function handleResize():Void {
		// implement handleResize method
	}

	private function getMouseOnScreen(pageX:Int, pageY:Int):Vector2 {
		// implement getMouseOnScreen method
	}

	private function getMouseOnCircle(pageX:Int, pageY:Int):Vector2 {
		// implement getMouseOnCircle method
	}

	private function rotateCamera():Void {
		// implement rotateCamera method
	}

	private function zoomCamera():Void {
		// implement zoomCamera method
	}

	private function panCamera():Void {
		// implement panCamera method
	}

	private function checkDistances():Void {
		// implement checkDistances method
	}

	public function update():Void {
		// implement update method
	}

	public function reset():Void {
		// implement reset method
	}

	// Add event listeners and initialize variables here

}