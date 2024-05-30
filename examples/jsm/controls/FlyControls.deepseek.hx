import three.EventDispatcher;
import three.Quaternion;
import three.Vector3;

class FlyControls extends EventDispatcher {

    public var object:Dynamic;
    public var domElement:Dynamic;

    public var enabled(default, null):Bool;
    public var movementSpeed(default, null):Float;
    public var rollSpeed(default, null):Float;
    public var dragToLook(default, null):Bool;
    public var autoForward(default, null):Bool;

    private var _changeEvent:Dynamic;
    private var lastQuaternion:Quaternion;
    private var lastPosition:Vector3;
    private var tmpQuaternion:Quaternion;
    private var status:Int;
    private var moveState:Dynamic;
    private var moveVector:Vector3;
    private var rotationVector:Vector3;

    public function new(object:Dynamic, domElement:Dynamic) {
        super();
        this.object = object;
        this.domElement = domElement;
        this.enabled = true;
        this.movementSpeed = 1.0;
        this.rollSpeed = 0.005;
        this.dragToLook = false;
        this.autoForward = false;
        this._changeEvent = { type: 'change' };
        this.lastQuaternion = new Quaternion();
        this.lastPosition = new Vector3();
        this.tmpQuaternion = new Quaternion();
        this.status = 0;
        this.moveState = { up: 0, down: 0, left: 0, right: 0, forward: 0, back: 0, pitchUp: 0, pitchDown: 0, yawLeft: 0, yawRight: 0, rollLeft: 0, rollRight: 0 };
        this.moveVector = new Vector3(0, 0, 0);
        this.rotationVector = new Vector3(0, 0, 0);
        this.keydown = function(event:Dynamic):Void {
            // ...
        };
        this.keyup = function(event:Dynamic):Void {
            // ...
        };
        this.pointerdown = function(event:Dynamic):Void {
            // ...
        };
        this.pointermove = function(event:Dynamic):Void {
            // ...
        };
        this.pointerup = function(event:Dynamic):Void {
            // ...
        };
        this.pointercancel = function():Void {
            // ...
        };
        this.contextMenu = function(event:Dynamic):Void {
            // ...
        };
        this.update = function(delta:Float):Void {
            // ...
        };
        this.updateMovementVector = function():Void {
            // ...
        };
        this.updateRotationVector = function():Void {
            // ...
        };
        this.getContainerDimensions = function():Dynamic {
            // ...
        };
        this.dispose = function():Void {
            // ...
        };
        var _contextmenu = this.contextMenu.bind(this);
        var _pointermove = this.pointermove.bind(this);
        var _pointerdown = this.pointerdown.bind(this);
        var _pointerup = this.pointerup.bind(this);
        var _pointercancel = this.pointercancel.bind(this);
        var _keydown = this.keydown.bind(this);
        var _keyup = this.keyup.bind(this);
        this.domElement.addEventListener('contextmenu', _contextmenu);
        this.domElement.addEventListener('pointerdown', _pointerdown);
        this.domElement.addEventListener('pointermove', _pointermove);
        this.domElement.addEventListener('pointerup', _pointerup);
        this.domElement.addEventListener('pointercancel', _pointercancel);
        window.addEventListener('keydown', _keydown);
        window.addEventListener('keyup', _keyup);
        this.updateMovementVector();
        this.updateRotationVector();
    }
}