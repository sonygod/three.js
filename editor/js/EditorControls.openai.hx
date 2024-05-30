package three.js.editor.js;

import three.js.THREE;

class EditorControls extends three.js.THREE.EventDispatcher {
    public var enabled:Bool = true;
    public var center:THREE.Vector3;
    public var panSpeed:Float = 0.002;
    public var zoomSpeed:Float = 0.1;
    public var rotationSpeed:Float = 0.005;

    private var vector:THREE.Vector3;
    private var delta:THREE.Vector3;
    private var box:THREE.Box3;
    private var state:Int = STATE.NONE;
    private var pointers:Array<Int>;
    private var pointerPositions:Map<Int, THREE.Vector2>;

    private var domElement:js.html.Element;

    public function new(object:THREE.Object3D, domElement:js.html.Element) {
        super();
        center = new THREE.Vector3();
        vector = new THREE.Vector3();
        delta = new THREE.Vector3();
        box = new THREE.Box3();
        pointers = [];
        pointerPositions = new Map<Int, THREE.Vector2>();
        this.domElement = domElement;

        // events
        var changeEvent = { type: 'change' };

        this.focus = function (target:THREE.Object3D) {
            // implementation
        };

        this.pan = function (delta:THREE.Vector3) {
            // implementation
        };

        this.zoom = function (delta:THREE.Vector3) {
            // implementation
        };

        this.rotate = function (delta:THREE.Vector3) {
            // implementation
        };

        onPointerDown = function (event:js.html.PointerEvent) {
            // implementation
        };

        onPointerMove = function (event:js.html.PointerEvent) {
            // implementation
        };

        onPointerUp = function (event:js.html.PointerEvent) {
            // implementation
        };

        onMouseDown = function (event:js.html.MouseEvent) {
            // implementation
        };

        onMouseMove = function (event:js.html.MouseEvent) {
            // implementation
        };

        onMouseUp = function () {
            // implementation
        };

        onMouseWheel = function (event:js.html.WheelEvent) {
            // implementation
        };

        contextmenu = function (event:js.html.Event) {
            // implementation
        };

        this.dispose = function () {
            // implementation
        };

        domElement.addEventListener('contextmenu', contextmenu);
        domElement.addEventListener('dblclick', onMouseUp);
        domElement.addEventListener('wheel', onMouseWheel, { passive: false } );
        domElement.addEventListener('pointerdown', onPointerDown);
    }
}