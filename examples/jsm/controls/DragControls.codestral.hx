import js.html.HTMLDocument;
import js.html.HTMLStyleElement;
import js.html.HTMLInputElement;
import three.core.EventDispatcher;
import three.math.Matrix4;
import three.math.Plane;
import three.math.Raycaster;
import three.math.Vector2;
import three.math.Vector3;

class DragControls extends EventDispatcher {
    private var _plane:Plane = new Plane();
    private var _raycaster:Raycaster = new Raycaster();
    private var _pointer:Vector2 = new Vector2();
    private var _offset:Vector3 = new Vector3();
    private var _diff:Vector2 = new Vector2();
    private var _previousPointer:Vector2 = new Vector2();
    private var _intersection:Vector3 = new Vector3();
    private var _worldPosition:Vector3 = new Vector3();
    private var _inverseMatrix:Matrix4 = new Matrix4();
    private var _up:Vector3 = new Vector3();
    private var _right:Vector3 = new Vector3();
    private var _selected:Object = null;
    private var _hovered:Object = null;
    private var _intersections:Array<Object> = [];
    private var _domElement:HTMLInputElement;
    private var _objects:Array<Object>;
    private var _camera:Object;
    public var mode:String = "translate";
    public var rotateSpeed:Float = 1;
    public var enabled:Bool = true;
    public var recursive:Bool = true;
    public var transformGroup:Bool = false;

    public function new(_objects:Array<Object>, _camera:Object, _domElement:HTMLInputElement) {
        super();
        this._objects = _objects;
        this._camera = _camera;
        this._domElement = _domElement;

        _domElement.style.touchAction = 'none';

        // event listeners are not directly supported in Haxe.
        // you need to implement them manually.
        // _domElement.addEventListener('pointermove', onPointerMove);
        // _domElement.addEventListener('pointerdown', onPointerDown);
        // _domElement.addEventListener('pointerup', onPointerCancel);
        // _domElement.addEventListener('pointerleave', onPointerCancel);
    }

    public function activate() {
        // implement event listeners here.
    }

    public function deactivate() {
        // implement event listeners removal here.
        _domElement.style.cursor = '';
    }

    public function dispose() {
        deactivate();
    }

    public function getObjects():Array<Object> {
        return _objects;
    }

    public function setObjects(objects:Array<Object>) {
        _objects = objects;
    }

    public function getRaycaster():Raycaster {
        return _raycaster;
    }

    // implement other functions here.
}