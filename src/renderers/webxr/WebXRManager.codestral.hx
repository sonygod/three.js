import three.cameras.ArrayCamera;
import three.core.EventDispatcher;
import three.cameras.PerspectiveCamera;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.MathUtils;
import three.renderers.webgl.WebGLAnimation;
import three.renderers.WebGLRenderTarget;
import three.renderers.webxr.WebXRController;
import three.textures.DepthTexture;
import three.constants.DepthFormat;
import three.constants.DepthStencilFormat;
import three.constants.RGBAFormat;
import three.constants.UnsignedByteType;
import three.constants.UnsignedIntType;
import three.constants.UnsignedInt248Type;
import three.renderers.webxr.WebXRDepthSensing;

class WebXRManager extends EventDispatcher {

    private var scope:WebXRManager;
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
    private var depthSensing:WebXRDepthSensing;
    private var attributes:Dynamic;
    private var initialRenderTarget:WebGLRenderTarget;
    private var newRenderTarget:WebGLRenderTarget;
    private var controllers:Array<WebXRController>;
    private var controllerInputSources:Array<Dynamic>;
    private var currentSize:Vector2;
    private var currentPixelRatio:Float;
    private var cameraL:PerspectiveCamera;
    private var cameraR:PerspectiveCamera;
    private var cameras:Array<PerspectiveCamera>;
    private var cameraXR:ArrayCamera;
    private var _currentDepthNear:Float;
    private var _currentDepthFar:Float;
    private var onAnimationFrameCallback:Dynamic;
    private var animation:WebGLAnimation;

    public function new(renderer:three.WebGLRenderer, gl:WebGLRenderingContext) {
        super();

        scope = this;
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
        attributes = gl.getContextAttributes();

        initialRenderTarget = null;
        newRenderTarget = null;

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

        this.cameraAutoUpdate = true;
        this.enabled = false;

        this.isPresenting = false;

        onAnimationFrameCallback = null;
        animation = new WebGLAnimation();
        animation.setAnimationLoop(onAnimationFrame);
    }

    public function getController(index:Int):Dynamic {
        var controller:WebXRController = controllers[index];

        if (controller == null) {
            controller = new WebXRController();
            controllers[index] = controller;
        }

        return controller.getTargetRaySpace();
    }

    public function getControllerGrip(index:Int):Dynamic {
        var controller:WebXRController = controllers[index];

        if (controller == null) {
            controller = new WebXRController();
            controllers[index] = controller;
        }

        return controller.getGripSpace();
    }

    public function getHand(index:Int):Dynamic {
        var controller:WebXRController = controllers[index];

        if (controller == null) {
            controller = new WebXRController();
            controllers[index] = controller;
        }

        return controller.getHandSpace();
    }

    private function onSessionEvent(event:Dynamic) {
        var controllerIndex:Int = controllerInputSources.indexOf(event.inputSource);

        if (controllerIndex == -1) {
            return;
        }

        var controller:WebXRController = controllers[controllerIndex];

        if (controller != null) {
            controller.update(event.inputSource, event.frame, customReferenceSpace || referenceSpace);
            controller.dispatchEvent({type: event.type, data: event.inputSource});
        }
    }

    private function onSessionEnd() {
        session.removeEventListener('select', onSessionEvent);
        session.removeEventListener('selectstart', onSessionEvent);
        session.removeEventListener('selectend', onSessionEvent);
        session.removeEventListener('squeeze', onSessionEvent);
        session.removeEventListener('squeezestart', onSessionEvent);
        session.removeEventListener('squeezeend', onSessionEvent);
        session.removeEventListener('end', onSessionEnd);
        session.removeEventListener('inputsourceschange', onInputSourcesChange);

        for (index in 0...controllers.length) {
            var inputSource:Dynamic = controllerInputSources[index];

            if (inputSource == null) continue;

            controllerInputSources[index] = null;

            controllers[index].disconnect(inputSource);
        }

        _currentDepthNear = null;
        _currentDepthFar = null;

        depthSensing.reset();

        session = null;
        newRenderTarget = null;

        animation.stop();

        scope.isPresenting = false;

        scope.dispatchEvent({type: 'sessionend'});
    }

    public function setFramebufferScaleFactor(value:Float) {
        framebufferScaleFactor = value;

        if (scope.isPresenting) {
            trace('THREE.WebXRManager: Cannot change framebuffer scale while presenting.');
        }
    }

    public function setReferenceSpaceType(value:String) {
        referenceSpaceType = value;

        if (scope.isPresenting) {
            trace('THREE.WebXRManager: Cannot change reference space type while presenting.');
        }
    }

    public function getReferenceSpace():Dynamic {
        return customReferenceSpace || referenceSpace;
    }

    public function setReferenceSpace(space:Dynamic) {
        customReferenceSpace = space;
    }

    public function getBaseLayer():Dynamic {
        return glProjLayer != null ? glProjLayer : glBaseLayer;
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

    public async function setSession(value:Dynamic) {
        session = value;

        if (session != null) {
            initialRenderTarget = renderer.getRenderTarget();

            session.addEventListener('select', onSessionEvent);
            session.addEventListener('selectstart', onSessionEvent);
            session.addEventListener('selectend', onSessionEvent);
            session.addEventListener('squeeze', onSessionEvent);
            session.addEventListener('squeezestart', onSessionEvent);
            session.addEventListener('squeezeend', onSessionEvent);
            session.addEventListener('end', onSessionEnd);
            session.addEventListener('inputsourceschange', onInputSourcesChange);

            if (attributes.xrCompatible != true) {
                await gl.makeXRCompatible();
            }

            currentPixelRatio = renderer.getPixelRatio();
            renderer.getSize(currentSize);

            if (session.renderState.layers == null) {
                var layerInit:Dynamic = {
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
                var depthFormat:Dynamic = null;
                var depthType:Dynamic = null;
                var glDepthFormat:Dynamic = null;

                if (attributes.depth) {
                    glDepthFormat = attributes.stencil ? gl.DEPTH24_STENCIL8 : gl.DEPTH_COMPONENT24;
                    depthFormat = attributes.stencil ? DepthStencilFormat : DepthFormat;
                    depthType = attributes.stencil ? UnsignedInt248Type : UnsignedIntType;
                }

                var projectionlayerInit:Dynamic = {
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
                        depthTexture: new DepthTexture(
                            glProjLayer.textureWidth,
                            glProjLayer.textureHeight,
                            depthType,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            depthFormat
                        ),
                        stencilBuffer: attributes.stencil,
                        colorSpace: renderer.outputColorSpace,
                        samples: attributes.antialias ? 4 : 0,
                        resolveDepthBuffer: (glProjLayer.ignoreDepthValues == false)
                    }
                );
            }

            newRenderTarget.isXRRenderTarget = true;

            this.setFoveation(foveation);

            customReferenceSpace = null;
            referenceSpace = await session.requestReferenceSpace(referenceSpaceType);

            animation.setContext(session);
            animation.start();

            scope.isPresenting = true;

            scope.dispatchEvent({type: 'sessionstart'});
        }
    }

    private function onInputSourcesChange(event:Dynamic) {
        for (i in 0...event.removed.length) {
            var inputSource:Dynamic = event.removed[i];
            var index:Int = controllerInputSources.indexOf(inputSource);

            if (index >= 0) {
                controllerInputSources[index] = null;
                controllers[index].disconnect(inputSource);
            }
        }

        for (i in 0...event.added.length) {
            var inputSource:Dynamic = event.added[i];

            var controllerIndex:Int = controllerInputSources.indexOf(inputSource);

            if (controllerIndex == -1) {
                for (j in 0...controllers.length) {
                    if (j >= controllerInputSources.length) {
                        controllerInputSources.push(inputSource);
                        controllerIndex = j;
                        break;
                    } else if (controllerInputSources[j] == null) {
                        controllerInputSources[j] = inputSource;
                        controllerIndex = j;
                        break;
                    }
                }

                if (controllerIndex == -1) break;
            }

            var controller:WebXRController = controllers[controllerIndex];

            if (controller != null) {
                controller.connect(inputSource);
            }
        }
    }

    private function setProjectionFromUnion(camera:ArrayCamera, cameraL:PerspectiveCamera, cameraR:PerspectiveCamera) {
        var cameraLPos:Vector3 = new Vector3().setFromMatrixPosition(cameraL.matrixWorld);
        var cameraRPos:Vector3 = new Vector3().setFromMatrixPosition(cameraR.matrixWorld);

        var ipd:Float = cameraLPos.distanceTo(cameraRPos);

        var projL:Array<Float> = cameraL.projectionMatrix.elements;
        var projR:Array<Float> = cameraR.projectionMatrix.elements;

        var near:Float = projL[14] / (projL[10] - 1);
        var far:Float = projL[14] / (projL[10] + 1);
        var topFov:Float = (projL[9] + 1) / projL[5];
        var bottomFov:Float = (projL[9] - 1) / projL[5];

        var leftFov:Float = (projL[8] - 1) / projL[0];
        var rightFov:Float = (projR[8] + 1) / projR[0];
        var left:Float = near * leftFov;
        var right:Float = near * rightFov;

        var zOffset:Float = ipd / (-leftFov + rightFov);
        var xOffset:Float = zOffset * -leftFov;

        cameraL.matrixWorld.decompose(camera.position, camera.quaternion, camera.scale);
        camera.translateX(xOffset);
        camera.translateZ(zOffset);
        camera.matrixWorld.compose(camera.position, camera.quaternion, camera.scale);
        camera.matrixWorldInverse.copy(camera.matrixWorld).invert();

        var near2:Float = near + zOffset;
        var far2:Float = far + zOffset;
        var left2:Float = left - xOffset;
        var right2:Float = right + (ipd - xOffset);
        var top2:Float = topFov * far / far2 * near2;
        var bottom2:Float = bottomFov * far / far2 * near2;

        camera.projectionMatrix.makePerspective(left2, right2, top2, bottom2, near2, far2);
        camera.projectionMatrixInverse.copy(camera.projectionMatrix).invert();
    }

    private function updateCamera(camera:PerspectiveCamera, parent:PerspectiveCamera) {
        if (parent == null) {
            camera.matrixWorld.copy(camera.matrix);
        } else {
            camera.matrixWorld.multiplyMatrices(parent.matrixWorld, camera.matrix);
        }

        camera.matrixWorldInverse.copy(camera.matrixWorld).invert();
    }

    public function updateCamera(camera:PerspectiveCamera) {
        if (session == null) return;

        if (depthSensing.texture != null) {
            camera.near = depthSensing.depthNear;
            camera.far = depthSensing.depthFar;
        }

        cameraXR.near = cameraR.near = cameraL.near = camera.near;
        cameraXR.far = cameraR.far = cameraL.far = camera.far;

        if (_currentDepthNear != cameraXR.near || _currentDepthFar != cameraXR.far) {
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

        var parent:PerspectiveCamera = camera.parent;
        var cameraList:Array<PerspectiveCamera> = cameraXR.cameras;

        updateCamera(cameraXR, parent);

        for (i in 0...cameraList.length) {
            updateCamera(cameraList[i], parent);
        }

        if (cameraList.length == 2) {
            setProjectionFromUnion(cameraXR, cameraL, cameraR);
        } else {
            cameraXR.projectionMatrix.copy(cameraL.projectionMatrix);
        }

        updateUserCamera(camera, cameraXR, parent);
    }

    private function updateUserCamera(camera:PerspectiveCamera, cameraXR:ArrayCamera, parent:PerspectiveCamera) {
        if (parent == null) {
            camera.matrix.copy(cameraXR.matrixWorld);
        } else {
            camera.matrix.copy(parent.matrixWorld);
            camera.matrix.invert();
            camera.matrix.multiply(cameraXR.matrixWorld);
        }

        camera.matrix.decompose(camera.position, camera.quaternion, camera.scale);
        camera.updateMatrixWorld(true);

        camera.projectionMatrix.copy(cameraXR.projectionMatrix);
        camera.projectionMatrixInverse.copy(cameraXR.projectionMatrixInverse);

        if (camera.isPerspectiveCamera) {
            camera.fov = MathUtils.RAD2DEG * 2 * Math.atan(1 / camera.projectionMatrix.elements[5]);
            camera.zoom = 1;
        }
    }

    public function getCamera():ArrayCamera {
        return cameraXR;
    }

    public function getFoveation():Float {
        if (glProjLayer == null && glBaseLayer == null) {
            return null;
        }

        return foveation;
    }

    public function setFoveation(value:Float) {
        foveation = value;

        if (glProjLayer != null) {
            glProjLayer.fixedFoveation = value;
        }

        if (glBaseLayer != null && glBaseLayer.fixedFoveation != null) {
            glBaseLayer.fixedFoveation = value;
        }
    }

    public function hasDepthSensing():Bool {
        return depthSensing.texture != null;
    }

    private function onAnimationFrame(time:Float, frame:Dynamic) {
        pose = frame.getViewerPose(customReferenceSpace || referenceSpace);
        xrFrame = frame;

        if (pose != null) {
            var views:Array<Dynamic> = pose.views;

            if (glBaseLayer != null) {
                renderer.setRenderTargetFramebuffer(newRenderTarget, glBaseLayer.framebuffer);
                renderer.setRenderTarget(newRenderTarget);
            }

            var cameraXRNeedsUpdate:Bool = false;

            if (views.length != cameraXR.cameras.length) {
                cameraXR.cameras.length = 0;
                cameraXRNeedsUpdate = true;
            }

            for (i in 0...views.length) {
                var view:Dynamic = views[i];

                var viewport:Dynamic = null;

                if (glBaseLayer != null) {
                    viewport = glBaseLayer.getViewport(view);
                } else {
                    var glSubImage:Dynamic = glBinding.getViewSubImage(glProjLayer, view);
                    viewport = glSubImage.viewport;

                    if (i == 0) {
                        renderer.setRenderTargetTextures(
                            newRenderTarget,
                            glSubImage.colorTexture,
                            glProjLayer.ignoreDepthValues ? null : glSubImage.depthStencilTexture
                        );

                        renderer.setRenderTarget(newRenderTarget);
                    }
                }

                var camera:PerspectiveCamera = cameras[i];

                if (camera == null) {
                    camera = new PerspectiveCamera();
                    camera.layers.enable(i);
                    camera.viewport = new Vector4();
                    cameras[i] = camera;
                }

                camera.matrix.fromArray(view.transform.matrix);
                camera.matrix.decompose(camera.position, camera.quaternion, camera.scale);
                camera.projectionMatrix.fromArray(view.projectionMatrix);
                camera.projectionMatrixInverse.copy(camera.projectionMatrix).invert();
                camera.viewport.set(viewport.x, viewport.y, viewport.width, viewport.height);

                if (i == 0) {
                    cameraXR.matrix.copy(camera.matrix);
                    cameraXR.matrix.decompose(cameraXR.position, cameraXR.quaternion, cameraXR.scale);
                }

                if (cameraXRNeedsUpdate) {
                    cameraXR.cameras.push(camera);
                }
            }

            var enabledFeatures:Array<String> = session.enabledFeatures;

            if (enabledFeatures != null && enabledFeatures.indexOf('depth-sensing') != -1) {
                var depthData:Dynamic = glBinding.getDepthInformation(views[0]);

                if (depthData != null && depthData.isValid && depthData.texture != null) {
                    depthSensing.init(renderer, depthData, session.renderState);
                }
            }
        }

        for (i in 0...controllers.length) {
            var inputSource:Dynamic = controllerInputSources[i];
            var controller:WebXRController = controllers[i];

            if (inputSource != null && controller != null) {
                controller.update(inputSource, frame, customReferenceSpace || referenceSpace);
            }
        }

        depthSensing.render(renderer, cameraXR);

        if (onAnimationFrameCallback != null) onAnimationFrameCallback(time, frame);

        if (frame.detectedPlanes) {
            scope.dispatchEvent({type: 'planesdetected', data: frame});
        }

        xrFrame = null;
    }

    public function setAnimationLoop(callback:Dynamic) {
        onAnimationFrameCallback = callback;
    }

    public function dispose() {
    }
}