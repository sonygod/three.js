package three.renderers.webxr;

import three.cameras.ArrayCamera;
import three.cameras.PerspectiveCamera;
import three.core.EventDispatcher;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.MathUtils;
import three.renderers.WebGLAnimation;
import three.renderers.WebGLRenderTarget;
import three.webxr.WebXRController;
import three.textures.DepthTexture;
import three.constants.DepthFormat;
import three.constants.DepthStencilFormat;
import three.constants.RgbaFormat;
import three.constants.UnsignedByteType;
import three.constants.UnsignedIntType;
import three.constants.UnsignedInt248Type;
import three.webxr.WebXRDepthSensing;

class WebXRManager extends EventDispatcher {
    public var cameraAutoUpdate:Bool;
    public var enabled:Bool;
    public var isPresenting:Bool;

    private var session:Dynamic;
    private var framebufferScaleFactor:Float;
    private var referenceSpace:Dynamic;
    private var referenceSpaceType:String;
    private var foveation:Float;
    private var customReferenceSpace:Dynamic;
    private var pose:Dynamic;
    private var glBinding:Dynamic;
    private var glProjLayer:Dynamic;
    private var glBaseLayer:Dynamic;
    private var xrFrame:Dynamic;
    private var controllers:Array<WebXRController>;
    private var controllerInputSources:Array<Dynamic>;
    private var currentSize:Vector2;
    private var currentPixelRatio:Float;
    private var cameraL:PerspectiveCamera;
    private var cameraR:PerspectiveCamera;
    private var cameraXR:ArrayCamera;
    private var _currentDepthNear:Float;
    private var _currentDepthFar:Float;
    private var depthSensing:WebXRDepthSensing;
    private var animation:WebGLAnimation;

    public function new(renderer:Dynamic, gl:Dynamic) {
        super();

        session = null;
        framebufferScaleFactor = 1.0;
        referenceSpace = null;
        referenceSpaceType = 'local-floor';
        foveation = 1.0;
        customReferenceSpace = null;

        pose = null;
        glBinding = null;
        glProjLayer = null;
        glBaseLayer = null;
        xrFrame = null;

        controllers = [];
        controllerInputSources = [];

        currentSize = new Vector2();
        currentPixelRatio = null;

        cameraL = new PerspectiveCamera();
        cameraL.layers.enable(1);
        cameraL.viewport = new Vector4();

        cameraR = new PerspectiveCamera();
        cameraR.layers.enable(2);
        cameraR.viewport = new Vector4();

        cameras = [cameraL, cameraR];

        cameraXR = new ArrayCamera();
        cameraXR.layers.enable(1);
        cameraXR.layers.enable(2);

        _currentDepthNear = null;
        _currentDepthFar = null;

        cameraAutoUpdate = true;
        enabled = false;
        isPresenting = false;

        depthSensing = new WebXRDepthSensing();

        animation = new WebGLAnimation();
    }

    // ...