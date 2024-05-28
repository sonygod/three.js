package three.js.src.renderers.webxr;

import js.html.webxr.XRSession;
import js.html.webxr.XRFrame;
import js.html.webxr.XRReferenceSpace;
import js.html.webxr.XRInputSource;
import js.html.webxr.XRPose;
import js.html.webgl.GL;
import js.html.webgl.RenderingContext;
import three.cameras.ArrayCamera;
import three.cameras.PerspectiveCamera;
import three.core.EventDispatcher;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.renderers.WebGLAnimation;
import three.renderers.WebGLRenderTarget;
import three.textures.DepthTexture;
import three.xr.WebXRController;
import three.xr.WebXRDepthSensing;

class WebXRManager extends EventDispatcher {
    private var cameraL:PerspectiveCamera;
    private var cameraR:PerspectiveCamera;
    private var cameraXR:ArrayCamera;
    private var renderer:RenderingContext;
    private var gl:GL;
    private var session:XRSession;
    private var referenceSpace:XRReferenceSpace;
    private var customReferenceSpace:XRReferenceSpace;
    private var controllers:Array<WebXRController>;
    private var controllerInputSources:Array<XRInputSource>;
    private var currentSize:Vector2;
    private var currentPixelRatio:Float;
    private var framebufferScaleFactor:Float;
    private var foveation:Float;
    private var depthSensing:WebXRDepthSensing;
    private var animation:WebGLAnimation;
    private var onAnimationFrameCallback:(Float, XRFrame)->Void;
    private var isPresenting:Bool;
    private var cameraAutoUpdate:Bool;
    private var enabled:Bool;

    public function new(renderer:RenderingContext, gl:GL) {
        super();
        this.renderer = renderer;
        this.gl = gl;
        cameraL = new PerspectiveCamera();
        cameraL.layers.enable(1);
        cameraL.viewport = new Vector4();

        cameraR = new PerspectiveCamera();
        cameraR.layers.enable(2);
        cameraR.viewport = new Vector4();

        cameraXR = new ArrayCamera();
        cameraXR.layers.enable(1);
        cameraXR.layers.enable(2);

        controllers = new Array<WebXRController>();
        controllerInputSources = new Array<XRInputSource>();
        currentSize = new Vector2();
        depthSensing = new WebXRDepthSensing();
    }

    // ...

    public function getController(index:Int):WebXRController {
        if (controllers[index] == null) {
            controllers[index] = new WebXRController();
        }
        return controllers[index].getTargetRaySpace();
    }

    public function getControllerGrip(index:Int):WebXRController {
        if (controllers[index] == null) {
            controllers[index] = new WebXRController();
        }
        return controllers[index].getGripSpace();
    }

    public function getHand(index:Int):WebXRController {
        if (controllers[index] == null) {
            controllers[index] = new WebXRController();
        }
        return controllers[index].getHandSpace();
    }

    // ...

    public function setFramebufferScaleFactor(value:Float):Void {
        framebufferScaleFactor = value;
    }

    public function setReferenceSpaceType(value:String):Void {
        referenceSpaceType = value;
    }

    public function getReferenceSpace():XRReferenceSpace {
        return customReferenceSpace != null ? customReferenceSpace : referenceSpace;
    }

    public function setReferenceSpace(space:XRReferenceSpace):Void {
        customReferenceSpace = space;
    }

    public function getBaseLayer():XRWebGLLayer {
        return glProjLayer != null ? glProjLayer : glBaseLayer;
    }

    public function getBinding():XRWebGLBinding {
        return glBinding;
    }

    public function getFrame():XRFrame {
        return xrFrame;
    }

    public function getSession():XRSession {
        return session;
    }

    public function setSession(value:XRSession):Void {
        session = value;
        // ...
    }

    // ...
}