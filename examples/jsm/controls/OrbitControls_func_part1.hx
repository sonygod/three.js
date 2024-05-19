import three.js.*;

class OrbitControls {
    private var object:three.js.Camera;
    private var domElement:js.html.Element;
    private var enabled:Bool = true;
    private var target:Vector3;
    private var cursor:Vector3;
    private var minDistance:Float = 0;
    private var maxDistance:Float = Math.POSITIVE_INFINITY;
    private var minZoom:Float = 0;
    private var maxZoom:Float = Math.POSITIVE_INFINITY;
    private var minTargetRadius:Float = 0;
    private var maxTargetRadius:Float = Math.POSITIVE_INFINITY;
    private var minPolarAngle:Float = 0;
    private var maxPolarAngle:Float = Math.PI;
    private var minAzimuthAngle:Float = -Math.PI;
    private var maxAzimuthAngle:Float = Math.PI;
    private var enableDamping:Bool = false;
    private var dampingFactor:Float = 0.05;
    private var enableZoom:Bool = true;
    private var zoomSpeed:Float = 1.0;
    private var enableRotate:Bool = true;
    private var rotateSpeed:Float = 1.0;
    private var enablePan:Bool = true;
    private var panSpeed:Float = 1.0;
    private var screenSpacePanning:Bool = true;
    private var keyPanSpeed:Float = 7.0;
    private var zoomToCursor:Bool = false;
    private var autoRotate:Bool = false;
    private var autoRotateSpeed:Float = 2.0;
    private var keys:{LEFT:String, UP:String, RIGHT:String, BOTTOM:String};
    private var mouseButtons:{LEFT:Mouse, MIDDLE:Mouse, RIGHT:Mouse};
    private var touches:{ONE:Touch, TWO:Touch};

    public function new(object:three.js.Camera, domElement:js.html.Element) {
        super();
        this.object = object;
        this.domElement = domElement;
        domElement.style.touchAction = 'none'; // disable touch scroll

        target = new Vector3();
        cursor = new Vector3();

        target0 = target.clone();
        position0 = object.position.clone();
        zoom0 = object.zoom;

        _domElementKeyEvents = null;

        // ...
    }

    // ...

    public function getPolarAngle():Float {
        return spherical.phi;
    }

    public function getAzimuthalAngle():Float {
        return spherical.theta;
    }

    public function getDistance():Float {
        return object.position.distanceTo(target);
    }

    public function listenToKeyEvents(domElement:js.html.Element) {
        domElement.addEventListener('keydown', onKeyDown);
        _domElementKeyEvents = domElement;
    }

    public function stopListenToKeyEvents() {
        _domElementKeyEvents.removeEventListener('keydown', onKeyDown);
        _domElementKeyEvents = null;
    }

    public function saveState() {
        target0.copy(target);
        position0.copy(object.position);
        zoom0 = object.zoom;
    }

    public function reset() {
        target.copy(target0);
        object.position.copy(position0);
        object.zoom = zoom0;

        object.updateProjectionMatrix();
        dispatchEvent(_changeEvent);

        update();

        state = STATE.NONE;
    }

    private function update(?deltaTime:Float) {
        // ...
    }

    private function dispose() {
        domElement.removeEventListener('contextmenu', onContextMenu);

        domElement.removeEventListener('pointerdown', onPointerDown);
        domElement.removeEventListener('pointercancel', onPointerUp);
        domElement.removeEventListener('wheel', onMouseWheel);

        domElement.removeEventListener('pointermove', onPointerMove);
        domElement.removeEventListener('pointerup', onPointerUp);

        const document = domElement.getRootNode(); // offscreen canvas compatibility

        document.removeEventListener('keydown', interceptControlDown, { capture: true });

        if (_domElementKeyEvents !== null) {
            _domElementKeyEvents.removeEventListener('keydown', onKeyDown);
            _domElementKeyEvents = null;
        }
    }

    // ...
}