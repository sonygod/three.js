package three.js.src.renderers.webxr;

import three.ArrayCamera;
import three.EventDispatcher;
import three.PerspectiveCamera;
import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.math.MathUtils;
import three.renderers.webgl.WebGLAnimation;
import three.renderers.WebGLRenderTarget;
import three.webxr.WebXRController;
import three.textures.DepthTexture;
import three.constants.DepthFormat;
import three.constants.DepthStencilFormat;
import three.constants.RGBAFormat;
import three.constants.UnsignedByteType;
import three.constants.UnsignedIntType;
import three.constants.UnsignedInt248Type;
import three.webxr.WebXRDepthSensing;

class WebXRManager extends EventDispatcher {
    public var session:NullXRSession;
    public var framebufferScaleFactor:Float = 1.0;
    public var referenceSpace:NullXRReferenceSpace;
    public var referenceSpaceType:String = 'local-floor';
    public var foveation:Float = 1.0;
    public var customReferenceSpace:NullXRReferenceSpace;
    public var pose:NullXRPose;
    public var glBinding:NullXRWebGLBinding;
    public var glProjLayer:NullXRWebGLLayer;
    public var glBaseLayer:NullXRWebGLLayer;
    public var xrFrame:NullXRFrame;
    public var initialRenderTarget:NullWebGLRenderTarget;
    public var newRenderTarget:NullWebGLRenderTarget;
    public var controllers:Array<WebXRController>;
    public var controllerInputSources:Array<XRInputSource>;
    public var currentSize:Vector2;
    public var currentPixelRatio:Null<Float>;
    public var cameraL:PerspectiveCamera;
    public var cameraR:PerspectiveCamera;
    public var cameraXR:ArrayCamera;
    public var _currentDepthNear:Null<Float>;
    public var _currentDepthFar:Null<Float>;
    public var cameraAutoUpdate:Bool = true;
    public var enabled:Bool = false;
    public var isPresenting:Bool = false;
    public var depthSensing:WebXRDepthSensing;

    public function new(renderer:WebGLRenderer, gl:WebGLContext) {
        super();
        scope = this;
        session = null;
        // ...
    }

    public function getController(index:Int):WebXRController {
        // ...
    }

    public function getControllerGrip(index:Int):WebXRController {
        // ...
    }

    public function getHand(index:Int):WebXRController {
        // ...
    }

    private function onSessionEvent(event:XRSessionEvent):Void {
        // ...
    }

    private function onSessionEnd():Void {
        // ...
    }

    public function setFramebufferScaleFactor(value:Float):Void {
        // ...
    }

    public function setReferenceSpaceType(value:String):Void {
        // ...
    }

    public function getReferenceSpace():NullXRReferenceSpace {
        // ...
    }

    public function setReferenceSpace(space:NullXRReferenceSpace):Void {
        // ...
    }

    public function getBaseLayer():NullXRWebGLLayer {
        // ...
    }

    public function getBinding():NullXRWebGLBinding {
        // ...
    }

    public function getFrame():NullXRFrame {
        // ...
    }

    public function getSession():NullXRSession {
        // ...
    }

    public function setSession(value:NullXRSession):Void {
        // ...
    }

    public function getEnvironmentBlendMode():Null<String> {
        // ...
    }

    private function onInputSourcesChange(event:XRInputSourcesChangeEvent):Void {
        // ...
    }

    private function updateCamera(camera:Camera, parent:NullObject3D):Void {
        // ...
    }

    public function update():Void {
        // ...
    }

    private function setUserCamera(camera:Camera, cameraXR:Camera, parent:NullObject3D):Void {
        // ...
    }

    public function getCamera():Camera {
        return cameraXR;
    }

    public function getFoveation():Null<Float> {
        // ...
    }

    public function setFoveation(value:Float):Void {
        // ...
    }

    public function hasDepthSensing():Bool {
        // ...
    }

    private function onAnimationFrame(time:Float, frame:XRFrame):Void {
        // ...
    }

    public function setAnimationLoop(callback:Void->Void):Void {
        // ...
    }

    public function dispose():Void {
        // ...
    }
}