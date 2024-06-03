import js.Browser;
import js.html.HtmlElement;
import three.core.EventDispatcher;
import three.cameras.Camera;
import three.objects.Group;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.MathUtils;
import three.objects.GridHelper;
import three.objects.Line;
import three.core.BufferGeometry;
import three.materials.LineBasicMaterial;
import three.core.Raycaster;
import three.math.Box3;
import three.math.Sphere;
import three.extras.curves.EllipseCurve;

enum STATE {
    IDLE,
    ROTATE,
    PAN,
    SCALE,
    FOV,
    FOCUS,
    ZROTATE,
    TOUCH_MULTI,
    ANIMATION_FOCUS,
    ANIMATION_ROTATE
}

enum INPUT {
    NONE,
    ONE_FINGER,
    ONE_FINGER_SWITCHED,
    TWO_FINGER,
    MULT_FINGER,
    CURSOR
}

class ArcballControls extends EventDispatcher {
    var camera:Camera;
    var domElement:HtmlElement;
    var scene:Scene;
    var target:Vector3;
    var _currentTarget:Vector3;
    var radiusFactor:Float;

    var mouseActions:Array<Dynamic>;
    var _mouseOp:Dynamic;

    var _v2_1:Vector2;
    var _v3_1:Vector3;
    var _v3_2:Vector3;

    var _m4_1:Matrix4;
    var _m4_2:Matrix4;

    var _quat:Quaternion;

    var _translationMatrix:Matrix4;
    var _rotationMatrix:Matrix4;
    var _scaleMatrix:Matrix4;

    var _rotationAxis:Vector3;

    var _cameraMatrixState:Matrix4;
    var _cameraProjectionState:Matrix4;

    var _fovState:Float;
    var _upState:Vector3;
    var _zoomState:Float;
    var _nearPos:Float;
    var _farPos:Float;

    var _gizmoMatrixState:Matrix4;

    // ... More class variables ...

    public function new(camera:Camera, domElement:HtmlElement, scene:Scene = null) {
        super();
        this.camera = null;
        this.domElement = domElement;
        this.scene = scene;
        this.target = new Vector3();
        this._currentTarget = new Vector3();
        this.radiusFactor = 0.67;

        // ... Initialization for other variables ...

        this.setCamera(camera);

        if (this.scene != null) {
            this.scene.add(this._gizmos);
        }

        this.domElement.style.touchAction = 'none';
        this._devPxRatio = Browser.window.devicePixelRatio;

        this.initializeMouseActions();

        this._onContextMenu = onContextMenu.bind(this);
        this._onWheel = onWheel.bind(this);
        this._onPointerUp = onPointerUp.bind(this);
        this._onPointerMove = onPointerMove.bind(this);
        this._onPointerDown = onPointerDown.bind(this);
        this._onPointerCancel = onPointerCancel.bind(this);
        this._onWindowResize = onWindowResize.bind(this);

        this.domElement.addEventListener('contextmenu', this._onContextMenu);
        this.domElement.addEventListener('wheel', this._onWheel);
        this.domElement.addEventListener('pointerdown', this._onPointerDown);
        this.domElement.addEventListener('pointercancel', this._onPointerCancel);

        Browser.window.addEventListener('resize', this._onWindowResize);
    }

    public function onSinglePanStart(event:Dynamic, operation:String) {
        if (this.enabled) {
            this.dispatchEvent(_changeEvent);

            this.setCenter(event.clientX, event.clientY);

            switch (operation) {
                case 'PAN':
                    if (!this.enablePan) return;
                    // ... Rest of the code for PAN operation ...
                    break;

                case 'ROTATE':
                    if (!this.enableRotate) return;
                    // ... Rest of the code for ROTATE operation ...
                    break;

                case 'FOV':
                    if (!this.camera.isPerspectiveCamera || !this.enableZoom) return;
                    // ... Rest of the code for FOV operation ...
                    break;

                case 'ZOOM':
                    if (!this.enableZoom) return;
                    // ... Rest of the code for ZOOM operation ...
                    break;
            }
        }
    }

    public function onSinglePanMove(event:Dynamic, opState:STATE) {
        if (this.enabled) {
            var restart:Bool = opState != this._state;
            this.setCenter(event.clientX, event.clientY);

            switch (opState) {
                case STATE.PAN:
                    if (this.enablePan) {
                        // ... Rest of the code for PAN operation ...
                    }
                    break;

                case STATE.ROTATE:
                    if (this.enableRotate) {
                        // ... Rest of the code for ROTATE operation ...
                    }
                    break;

                case STATE.SCALE:
                    if (this.enableZoom) {
                        // ... Rest of the code for SCALE operation ...
                    }
                    break;

                case STATE.FOV:
                    if (this.enableZoom && this.camera.isPerspectiveCamera) {
                        // ... Rest of the code for FOV operation ...
                    }
                    break;
            }

            this.dispatchEvent(_changeEvent);
        }
    }
}