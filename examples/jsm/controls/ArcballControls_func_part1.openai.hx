package three.js.examples.jsm.controls;

import three.math.*;
import three.core.*;
import three.objects.*;
import three.events.*;

class ArcballControls extends EventDispatcher {
    // Trackball state
    static private var STATE = {
        IDLE: Symbol(),
        ROTATE: Symbol(),
        PAN: Symbol(),
        SCALE: Symbol(),
        FOCUS: Symbol(),
        ZROTATE: Symbol(),
        TOUCH_MULTI: Symbol(),
        ANIMATION_FOCUS: Symbol(),
        ANIMATION_ROTATE: Symbol()
    };

    // Input
    static private var INPUT = {
        NONE: Symbol(),
        ONE_FINGER: Symbol(),
        ONE_FINGER_SWITCHED: Symbol(),
        TWO_FINGER: Symbol(),
        MULT_FINGER: Symbol(),
        CURSOR: Symbol()
    };

    //cursor center coordinates
    private var _center: {x:Float, y:Float} = {x:0, y:0};

    //transformation matrices for gizmos and camera
    private var _transformation: {camera:Matrix4, gizmos:Matrix4} = {
        camera: new Matrix4(),
        gizmos: new Matrix4()
    };

    //events
    private var _changeEvent: {type:String} = {type:'change'};
    private var _startEvent: {type:String} = {type:'start'};
    private var _endEvent: {type:String} = {type:'end'};

    private var _raycaster:Raycaster;
    private var _offset:Vector3;

    private var _gizmoMatrixStateTemp:Matrix4;
    private var _cameraMatrixStateTemp:Matrix4;
    private var _scalePointTemp:Vector3;

    public function new(camera:Camera, domElement:HTMLElement, scene:Scene = null) {
        super();
        this.camera = null;
        this.domElement = domElement;
        this.scene = scene;
        this.target = new Vector3();
        this._currentTarget = new Vector3();
        this.radiusFactor = 0.67;

        this.mouseActions = [];
        this._mouseOp = null;

        //global vectors and matrices that are used in some operations to avoid creating new objects every time (e.g. every time cursor moves)
        this._v2_1 = new Vector2();
        this._v3_1 = new Vector3();
        this._v3_2 = new Vector3();

        this._m4_1 = new Matrix4();
        this._m4_2 = new Matrix4();

        this._quat = new Quaternion();

        //transformation matrices
        this._translationMatrix = new Matrix4(); //matrix for translation operation
        this._rotationMatrix = new Matrix4(); //matrix for rotation operation
        this._scaleMatrix = new Matrix4(); //matrix for scaling operation

        this._rotationAxis = new Vector3(); //axis for rotate operation

        //camera state
        this._cameraMatrixState = new Matrix4();
        this._cameraProjectionState = new Matrix4();

        this._fovState = 1;
        this._upState = new Vector3();
        this._zoomState = 1;
        this._nearPos = 0;
        this._farPos = 0;

        this._gizmoMatrixState = new Matrix4();

        //initial values
        this._up0 = new Vector3();
        this._zoom0 = 1;
        this._fov0 = 0;
        this._initialNear = 0;
        this._nearPos0 = 0;
        this._initialFar = 0;
        this._farPos0 = 0;
        this._cameraMatrixState0 = new Matrix4();
        this._gizmoMatrixState0 = new Matrix4();

        //pointers array
        this._button = -1;
        this._touchStart = [];
        this._touchCurrent = [];
        this._input = INPUT.NONE;

        //two fingers touch interaction
        this._switchSensibility = 32;	//minimum movement to be performed to fire single pan start after the second finger has been released
        this._startFingerDistance = 0; //distance between two fingers
        this._currentFingerDistance = 0;
        this._startFingerRotation = 0; //amount of rotation performed with two fingers
        this._currentFingerRotation = 0;

        //double tap
        this._devPxRatio = 0;
        this._downValid = true;
        this._nclicks = 0;
        this._downEvents = [];
        this._downStart = 0;	//pointerDown time
        this._clickStart = 0;	//first click time
        this._maxDownTime = 250;
        this._maxInterval = 300;
        this._posThreshold = 24;
        this._movementThreshold = 24;

        //cursor positions
        this._currentCursorPosition = new Vector3();
        this._startCursorPosition = new Vector3();

        //grid
        this._grid = null; //grid to be visualized during pan operation
        this._gridPosition = new Vector3();

        //gizmos
        this._gizmos = new Group();
        this._curvePts = 128;

        //animations
        this._timeStart = -1; //initial time
        this._animationId = -1;

        //focus animation
        this.focusAnimationTime = 500; //duration of focus animation in ms

        //rotate animation
        this._timePrev = 0; //time at which previous rotate operation has been detected
        this._timeCurrent = 0; //time at which current rotate operation has been detected
        this._anglePrev = 0; //angle of previous rotation
        this._angleCurrent = 0; //angle of current rotation
        this._cursorPosPrev = new Vector3();	//cursor position when previous rotate operation has been detected
        this._cursorPosCurr = new Vector3();//cursor position when current rotate operation has been detected
        this._wPrev = 0; //angular velocity of the previous rotate operation
        this._wCurr = 0; //angular velocity of the current rotate operation


        //parameters
        this.adjustNearFar = false;
        this.scaleFactor = 1.1;	//zoom/distance multiplier
        this.dampingFactor = 25;
        this.wMax = 20;	//maximum angular velocity allowed
        this.enableAnimations = true; //if animations should be performed
        this.enableGrid = false; //if grid should be showed during pan operation
        this.cursorZoom = false;	//if wheel zoom should be cursor centered
        this.minFov = 5;
        this.maxFov = 90;
        this.rotateSpeed = 1;

        this.enabled = true;
        this.enablePan = true;
        this.enableRotate = true;
        this.enableZoom = true;
        this.enableGizmos = true;

        this.minDistance = 0;
        this.maxDistance = Math.POSITIVE_INFINITY;
        this.minZoom = 0;
        this.maxZoom = Math.POSITIVE_INFINITY;

        //trackball parameters
        this._tbRadius = 1;

        this._state = STATE.IDLE;

        this.setCamera(camera);

        if (this.scene != null) {

            this.scene.add(this._gizmos);

        }

        this.domElement.style.touchAction = 'none';
        this._devPxRatio = window.devicePixelRatio;

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

        window.addEventListener('resize', this._onWindowResize);
    }

    //other methods...

    private function onSinglePanStart(event:Event, operation:String):Void {
        //...
    }

    private function onSinglePanMove(event:Event, opState:Symbol):Void {
        //...
    }
}