package three.js.src.renderers.webxr;

import three.js.src.cameras.ArrayCamera;
import three.js.src.cameras.PerspectiveCamera;
import three.js.src.core.EventDispatcher;
import three.js.src.math.Vector2;
import three.js.src.math.Vector3;
import three.js.src.math.Vector4;
import three.js.src.math.MathUtils;
import three.js.src.renderers.webgl.WebGLAnimation;
import three.js.src.WebGLRenderTarget;
import three.js.src.renderers.webxr.WebXRController;
import three.js.src.textures.DepthTexture;
import three.js.src.constants.*;
import three.js.src.renderers.webxr.WebXRDepthSensing;

class WebXRManager extends EventDispatcher {

    var cameraL:PerspectiveCamera;
    var cameraR:PerspectiveCamera;
    var cameras:Array<PerspectiveCamera>;
    var cameraXR:ArrayCamera;
    var _currentDepthNear:Float;
    var _currentDepthFar:Float;
    var controllers:Array<WebXRController>;
    var controllerInputSources:Array<Dynamic>;
    var currentSize:Vector2;
    var currentPixelRatio:Float;
    var initialRenderTarget:Dynamic;
    var newRenderTarget:WebGLRenderTarget;
    var glBaseLayer:Dynamic;
    var glProjLayer:Dynamic;
    var glBinding:Dynamic;
    var xrFrame:Dynamic;
    var session:Dynamic;
    var framebufferScaleFactor:Float;
    var referenceSpaceType:String;
    var referenceSpace:Dynamic;
    var customReferenceSpace:Dynamic;
    var foveation:Float;
    var pose:Dynamic;
    var depthSensing:WebXRDepthSensing;
    var cameraLPos:Vector3;
    var cameraRPos:Vector3;
    var animation:WebGLAnimation;
    var onAnimationFrameCallback:Dynamic;

    public function new(renderer:Dynamic, gl:Dynamic) {
        super();

        var scope = this;

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

        depthSensing = new WebXRDepthSensing();
        var attributes = gl.getContextAttributes();

        initialRenderTarget = null;
        newRenderTarget = null;

        controllers = [];
        controllerInputSources = [];

        currentSize = new Vector2();
        currentPixelRatio = null;

        cameraL = new PerspectiveCamera();
        cameraL.layers.enable( 1 );
        cameraL.viewport = new Vector4();

        cameraR = new PerspectiveCamera();
        cameraR.layers.enable( 2 );
        cameraR.viewport = new Vector4();

        cameras = [ cameraL, cameraR ];

        cameraXR = new ArrayCamera();
        cameraXR.layers.enable( 1 );
        cameraXR.layers.enable( 2 );

        _currentDepthNear = null;
        _currentDepthFar = null;

        cameraAutoUpdate = true;
        enabled = false;

        isPresenting = false;

        cameraLPos = new Vector3();
        cameraRPos = new Vector3();

        animation = new WebGLAnimation();
        animation.setAnimationLoop(onAnimationFrame);

    }

    public function getController(index:Int):Dynamic {

        var controller = controllers[index];

        if (controller === undefined) {

            controller = new WebXRController();
            controllers[index] = controller;

        }

        return controller.getTargetRaySpace();

    }

    public function getControllerGrip(index:Int):Dynamic {

        var controller = controllers[index];

        if (controller === undefined) {

            controller = new WebXRController();
            controllers[index] = controller;

        }

        return controller.getGripSpace();

    }

    public function getHand(index:Int):Dynamic {

        var controller = controllers[index];

        if (controller === undefined) {

            controller = new WebXRController();
            controllers[index] = controller;

        }

        return controller.getHandSpace();

    }

    public function setFramebufferScaleFactor(value:Float):Void {

        framebufferScaleFactor = value;

        if (scope.isPresenting === true) {

            trace('THREE.WebXRManager: Cannot change framebuffer scale while presenting.');

        }

    }

    public function setReferenceSpaceType(value:String):Void {

        referenceSpaceType = value;

        if (scope.isPresenting === true) {

            trace('THREE.WebXRManager: Cannot change reference space type while presenting.');

        }

    }

    public function getReferenceSpace():Dynamic {

        return customReferenceSpace || referenceSpace;

    }

    public function setReferenceSpace(space:Dynamic):Void {

        customReferenceSpace = space;

    }

    public function getBaseLayer():Dynamic {

        return glProjLayer !== null ? glProjLayer : glBaseLayer;

    }

    public function getBinding():Dynamic {

        return glBinding;

    }

    public function getFrame():Dynamic {

        return xrFrame;

    }

    public function getSession():Dynamic {

        return session;

    }

    public function setSession(value:Dynamic):Void {

        session = value;

        if (session !== null) {

            initialRenderTarget = renderer.getRenderTarget();

            session.addEventListener('select', onSessionEvent);
            session.addEventListener('selectstart', onSessionEvent);
            session.addEventListener('selectend', onSessionEvent);
            session.addEventListener('squeeze', onSessionEvent);
            session.addEventListener('squeezestart', onSessionEvent);
            session.addEventListener('squeezeend', onSessionEvent);
            session.addEventListener('end', onSessionEnd);
            session.addEventListener('inputsourceschange', onInputSourcesChange);

            if (attributes.xrCompatible !== true) {

                gl.makeXRCompatible();

            }

            currentPixelRatio = renderer.getPixelRatio();
            renderer.getSize(currentSize);

            if (session.renderState.layers === undefined) {

                var layerInit = {
                    antialias: attributes.antialias,
                    alpha: true,
                    depth: attributes.depth,
                    stencil: attributes.stencil,
                    framebufferScaleFactor: framebufferScaleFactor
                };

                glBaseLayer = new XRWebGLLayer(session, gl, layerInit);

                session.updateRenderState({baseLayer: glBaseLayer});

                renderer.setPixelRatio(1);
                renderer.setSize(glBaseLayer.framebufferWidth, glBaseLayer.framebufferHeight, false);

                newRenderTarget = new WebGLRenderTarget(
                    glBaseLayer.framebufferWidth,
                    glBaseLayer.framebufferHeight,
                    {
                        format: RGBAFormat,
                        type: UnsignedByteType,
                        colorSpace: renderer.outputColorSpace,
                        stencilBuffer: attributes.stencil
                    }
                );

            } else {

                var depthFormat = null;
                var depthType = null;
                var glDepthFormat = null;

                if (attributes.depth) {

                    glDepthFormat = attributes.stencil ? gl.DEPTH24_STENCIL8 : gl.DEPTH_COMPONENT24;
                    depthFormat = attributes.stencil ? DepthStencilFormat : DepthFormat;
                    depthType = attributes.stencil ? UnsignedInt248Type : UnsignedIntType;

                }

                var projectionlayerInit = {
                    colorFormat: gl.RGBA8,
                    depthFormat: glDepthFormat,
                    scaleFactor: framebufferScaleFactor
                };

                glBinding = new XRWebGLBinding(session, gl);

                glProjLayer = glBinding.createProjectionLayer(projectionlayerInit);

                session.updateRenderState({layers: [glProjLayer]});

                renderer.setPixelRatio(1);
                renderer.setSize(glProjLayer.textureWidth, glProjLayer.textureHeight, false);

                newRenderTarget = new WebGLRenderTarget(
                    glProjLayer.textureWidth,
                    glProjLayer.textureHeight,
                    {
                        format: RGBAFormat,
                        type: UnsignedByteType,
                        depthTexture: new DepthTexture(glProjLayer.textureWidth, glProjLayer.textureHeight, depthType, undefined, undefined, undefined, undefined, undefined, undefined, depthFormat),
                        stencilBuffer: attributes.stencil,
                        colorSpace: renderer.outputColorSpace,
                        samples: attributes.antialias ? 4 : 0,
                        resolveDepthBuffer: (glProjLayer.ignoreDepthValues === false)
                    }
                );

            }

            newRenderTarget.isXRRenderTarget = true; // TODO Remove this when possible, see #23278

            setFoveation(foveation);

            customReferenceSpace = null;
            referenceSpace = session.requestReferenceSpace(referenceSpaceType);

            animation.setContext(session);
            animation.start();

            scope.isPresenting = true;

            scope.dispatchEvent({type: 'sessionstart'});

        }

    }

    public function getEnvironmentBlendMode():Dynamic {

        if (session !== null) {

            return session.environmentBlendMode;

        }

    }

    public function updateCamera(camera:Dynamic):Void {

        if (session === null) return;

        if (depthSensing.texture !== null) {

            camera.near = depthSensing.depthNear;
            camera.far = depthSensing.depthFar;

        }

        cameraXR.near = cameraR.near = cameraL.near = camera.near;
        cameraXR.far = cameraR.far = cameraL.far = camera.far;

        if (_currentDepthNear !== cameraXR.near || _currentDepthFar !== cameraXR.far) {

            session.updateRenderState({
                depthNear: cameraXR.near,
                depthFar: cameraXR.far
            });

            _currentDepthNear = cameraXR.near;
            _currentDepthFar = cameraXR.far;

            cameraL.near = _currentDepthNear;
            cameraL.far = _currentDepthFar;
            cameraR.near = _currentDepthNear;
            cameraR.far = _currentDepthFar;

            cameraL.updateProjectionMatrix();
            cameraR.updateProjectionMatrix();
            camera.updateProjectionMatrix();

        }

        var parent = camera.parent;
        var cameras = cameraXR.cameras;

        updateCamera(cameraXR, parent);

        for (i in cameras) {

            updateCamera(cameras[i], parent);

        }

        if (cameras.length === 2) {

            setProjectionFromUnion(cameraXR, cameraL, cameraR);

        } else {

            cameraXR.projectionMatrix.copy(cameraL.projectionMatrix);

        }

        updateUserCamera(camera, cameraXR, parent);

    }

    public function getCamera():ArrayCamera {

        return cameraXR;

    }

    public function getFoveation():Float {

        if (glProjLayer === null && glBaseLayer === null) {

            return undefined;

        }

        return foveation;

    }

    public function setFoveation(value:Float):Void {

        foveation = value;

        if (glProjLayer !== null) {

            glProjLayer.fixedFoveation = value;

        }

        if (glBaseLayer !== null && glBaseLayer.fixedFoveation !== undefined) {

            glBaseLayer.fixedFoveation = value;

        }

    }

    public function hasDepthSensing():Bool {

        return depthSensing.texture !== null;

    }

    public function setAnimationLoop(callback:Dynamic):Void {

        onAnimationFrameCallback = callback;

    }

    public function dispose():Void {}

}