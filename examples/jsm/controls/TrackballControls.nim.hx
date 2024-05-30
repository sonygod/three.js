import three.js.examples.jsm.controls.TrackballControls;
import three.js.examples.jsm.controls.EventDispatcher;
import three.js.examples.jsm.math.MathUtils;
import three.js.examples.jsm.math.MOUSE;
import three.js.examples.jsm.math.Quaternion;
import three.js.examples.jsm.math.Vector2;
import three.js.examples.jsm.math.Vector3;

class TrackballControls extends EventDispatcher {

    public static var _changeEvent = { type: 'change' };
    public static var _startEvent = { type: 'start' };
    public static var _endEvent = { type: 'end' };

    public var object:Dynamic;
    public var domElement:Dynamic;
    public var enabled:Bool;
    public var screen:Dynamic;
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
    public var mouseButtons:Dynamic;
    public var target:Vector3;
    public var target0:Vector3;
    public var position0:Vector3;
    public var up0:Vector3;
    public var zoom0:Float;

    public function new(object:Dynamic, domElement:Dynamic) {
        super();

        this.object = object;
        this.domElement = domElement;
        this.domElement.style.touchAction = 'none'; // disable touch scroll

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
        this.maxDistance = Infinity;

        this.minZoom = 0;
        this.maxZoom = Infinity;

        this.keys = ['KeyA' /*A*/, 'KeyS' /*S*/, 'KeyD' /*D*/];

        this.mouseButtons = { LEFT: MOUSE.ROTATE, MIDDLE: MOUSE.DOLLY, RIGHT: MOUSE.PAN };

        this.target = new Vector3();

        this.target0 = this.target.clone();
        this.position0 = this.object.position.clone();
        this.up0 = this.object.up.clone();
        this.zoom0 = this.object.zoom;

        this.handleResize();

        this.domElement.addEventListener('contextmenu', contextmenu);

        this.domElement.addEventListener('pointerdown', onPointerDown);
        this.domElement.addEventListener('pointercancel', onPointerCancel);
        this.domElement.addEventListener('wheel', onMouseWheel, { passive: false });

        window.addEventListener('keydown', keydown);
        window.addEventListener('keyup', keyup);

        this.update();
    }

    public function handleResize() {
        const box = this.domElement.getBoundingClientRect();
        // adjustments come from similar code in the jquery offset() function
        const d = this.domElement.ownerDocument.documentElement;
        this.screen.left = box.left + window.pageXOffset - d.clientLeft;
        this.screen.top = box.top + window.pageYOffset - d.clientTop;
        this.screen.width = box.width;
        this.screen.height = box.height;
    }

    public function getMouseOnScreen(pageX:Float, pageY:Float):Vector2 {
        const vector = new Vector2();
        vector.set(
            (pageX - this.screen.left) / this.screen.width,
            (pageY - this.screen.top) / this.screen.height
        );
        return vector;
    }

    public function getMouseOnCircle(pageX:Float, pageY:Float):Vector2 {
        const vector = new Vector2();
        vector.set(
            ((pageX - this.screen.width * 0.5 - this.screen.left) / (this.screen.width * 0.5)),
            ((this.screen.height + 2 * (this.screen.top - pageY)) / this.screen.width) // screen.width intentional
        );
        return vector;
    }

    public function rotateCamera() {
        // ...
    }

    public function zoomCamera() {
        // ...
    }

    public function panCamera() {
        // ...
    }

    public function checkDistances() {
        // ...
    }

    public function update() {
        // ...
    }

    public function reset() {
        // ...
    }

    public function dispose() {
        this.domElement.removeEventListener('contextmenu', contextmenu);

        this.domElement.removeEventListener('pointerdown', onPointerDown);
        this.domElement.removeEventListener('pointercancel', onPointerCancel);
        this.domElement.removeEventListener('wheel', onMouseWheel);

        window.removeEventListener('keydown', keydown);
        window.removeEventListener('keyup', keyup);
    }

    public function onPointerDown(event:Dynamic) {
        // ...
    }

    public function onPointerMove(event:Dynamic) {
        // ...
    }

    public function onPointerUp(event:Dynamic) {
        // ...
    }

    public function onPointerCancel(event:Dynamic) {
        // ...
    }

    public function keydown(event:Dynamic) {
        // ...
    }

    public function keyup() {
        // ...
    }

    public function onMouseDown(event:Dynamic) {
        // ...
    }

    public function onMouseMove(event:Dynamic) {
        // ...
    }

    public function onMouseUp() {
        // ...
    }

    public function onMouseWheel(event:Dynamic) {
        // ...
    }

    public function onTouchStart(event:Dynamic) {
        // ...
    }

    public function onTouchMove(event:Dynamic) {
        // ...
    }

    public function onTouchEnd(event:Dynamic) {
        // ...
    }

    public function contextmenu(event:Dynamic) {
        // ...
    }

    public function addPointer(event:Dynamic) {
        // ...
    }

    public function removePointer(event:Dynamic) {
        // ...
    }

    public function trackPointer(event:Dynamic) {
        // ...
    }

    public function getSecondPointerPosition(event:Dynamic) {
        // ...
    }
}