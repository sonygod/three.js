import js.webxr.XRWebGLLayer;
import js.webxr.XRWebGLBinding;
import js.webxr.XRFrame;
import js.webxr.XRViewerPose;
import js.webxr.XRView;
import js.webxr.XRRenderState;
import js.webxr.XRInputSource;
import js.webxr.XRDepthInformation;
import js.webxr.XRSession;
import js.webxr.XRReferenceSpace;
import js.webxr.XRInputSourceEvent;
import js.webxr.XRInputSourcesChangeEvent;
import js.webgl.WebGLContextAttributes;
import js.webgl.WebGLTexture;
import js.webgl.WebGLRenderbuffer;
import js.webgl.WebGLFramebuffer;
import js.ArrayCamera;
import js.EventDispatcher;
import js.PerspectiveCamera;
import js.Vector2;
import js.Vector3;
import js.Vector4;
import js.WebGLAnimation;
import js.WebGLRenderTarget;
import js.WebXRController;
import js.WebXRDepthSensing;
import js.DepthTexture;
import js.DepthFormat;
import js.DepthStencilFormat;
import js.RGBAFormat;
import js.UnsignedByteType;
import js.UnsignedIntType;
import js.UnsignedInt248Type;

class WebXRManager extends EventDispatcher {

	public var cameraAutoUpdate:Bool;
	public var enabled:Bool;
	public var isPresenting:Bool;

	private var session:XRSession;
	private var framebufferScaleFactor:Float;
	private var referenceSpace:XRReferenceSpace;
	private var referenceSpaceType:String;
	private var foveation:Float;
	private var customReferenceSpace:XRReferenceSpace;
	private var pose:XRViewerPose;
	private var glBinding:XRWebGLBinding;
	private var glProjLayer:XRWebGLLayer;
	private var glBaseLayer:XRWebGLLayer;
	private var xrFrame:XRFrame;
	private var depthSensing:WebXRDepthSensing;
	private var attributes:WebGLContextAttributes;
	private var initialRenderTarget:WebGLRenderTarget;
	private var newRenderTarget:WebGLRenderTarget;
	private var controllers:Array<WebXRController>;
	private var controllerInputSources:Array<XRInputSource>;
	private var currentSize:Vector2;
	private var currentPixelRatio:Float;
	private var cameraL:PerspectiveCamera;
	private var cameraR:PerspectiveCamera;
	private var cameras:Array<PerspectiveCamera>;
	private var cameraXR:ArrayCamera;
	private var _currentDepthNear:Float;
	private var _currentDepthFar:Float;
	private var animation:WebGLAnimation;

	public function new(renderer:WebGLRenderer, gl:WebGLRenderingContext) {
		super();
		cameraAutoUpdate = true;
		enabled = false;
		isPresenting = false;
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
		animation = new WebGLAnimation();
		animation.setContext(session);
	}

	public function getController(index:Int):WebXRController {
		var controller = controllers[index];
		if (controller == null) {
			controller = new WebXRController();
			controllers[index] = controller;
		}
		return controller.getTargetRaySpace();
	}

	public function getControllerGrip(index:Int):WebXRController {
		var controller = controllers[index];
		if (controller == null) {
			controller = new WebXRController();
			controllers[index] = controller;
		}
		return controller.getGripSpace();
	}

	public function getHand(index:Int):WebXRController {
		var controller = controllers[index];
		if (controller == null) {
			controller = new WebXRController();
			controllers[index] = controller;
		}
		return controller.getHandSpace();
	}

	private function onSessionEvent(event:XRInputSourceEvent) {
		var controllerIndex = controllerInputSources.indexOf(event.inputSource);
		if (controllerIndex == -1) {
			return;
		}
		var controller = controllers[controllerIndex];
		if (controller != null) {
			controller.update(event.inputSource, event.frame, customReferenceSpace or referenceSpace);
			controller.dispatchEvent({ type: event.type, data: event.inputSource });
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
		for (i in 0...controllers.length) {
			var inputSource = controllerInputSources[i];
			if (inputSource == null) {
				continue;
			}
			controllerInputSources[i] = null;
			controllers[i].disconnect(inputSource);
		}
		_currentDepthNear = null;
		_currentDepthFar = null;
		depthSensing.reset();
		renderer.setRenderTarget(initialRenderTarget);
		glBaseLayer = null;
		glProjLayer = null;
		glBinding = null;
		session = null;
		newRenderTarget = null;
		animation.stop();
		isPresenting = false;
		renderer.setPixelRatio(currentPixelRatio);
		renderer.setSize(currentSize.width, currentSize.height, false);
		dispatchEvent({ type: 'sessionend' });
	}

	public function setFramebufferScaleFactor(value:Float) {
		framebufferScaleFactor = value;
		if (isPresenting) {
			trace('Cannot change framebuffer scale while presenting.');
		}
	}

	public function setReferenceSpaceType(value:String) {
		referenceSpaceType = value;
		if (isPresenting) {
			trace('Cannot change reference space type while presenting.');
		}
	}

	public function getReferenceSpace():XRReferenceSpace {
		return customReferenceSpace or referenceSpace;
	}

	public function setReferenceSpace(space:XRReferenceSpace) {
		customReferenceSpace = space;
	}

	public function getBaseLayer():XRWebGLLayer {
		return if (glProjLayer != null) glProjLayer else glBaseLayer;
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
				gl.makeXRCompatible();
			}
			currentPixelRatio = renderer.getPixelRatio();
			renderer.getSize(currentSize);
			if (session.renderState.layers == null) {
				var layerInit = {
					antialias: attributes.antialias,
					alpha: true,
					depth: attributes.depth,
					stencil: attributes.stencil,
					framebufferScaleFactor: framebufferScaleFactor
				};
				glBaseLayer = new XRWebGLLayer(session, gl, layerInit);
				session.updateRenderState({ baseLayer: glBaseLayer });
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
					glDepthFormat = if (attributes.stencil) gl.DEPTH24_STENCIL8 else gl.DEPTH_COMPONENT24;
					depthFormat = if (attributes.stencil) DepthStencilFormat else DepthFormat;
					depthType = if (attributes.stencil) UnsignedInt248Type else UnsignedIntType;
				}
				var projectionlayerInit = {
					colorFormat: gl.RGBA8,
					depthFormat: glDepthFormat,
					scaleFactor: framebufferScaleFactor
				};
				glBinding = new XRWebGLBinding(session, gl);
				glProjLayer = glBinding.createProjectionLayer(projectionlayerInit);
				session.updateRenderState({ layers: [glProjLayer] });
				renderer.setPixelRatio(1);
				renderer.setSize(glProjLayer.textureWidth, glProjLayer.textureHeight, false);
				newRenderTarget = new WebGLRenderTarget(
					glProjLayer.textureWidth,
					glProjLayer.textureHeight,
					{
						format: RGBAFormat,
						type: UnsignedByteType,
						depthTexture: new DepthTexture(glProjLayer.textureWidth, glProjLayer.textureHeight, depthType, null, null, null, null, null, null, depthFormat),
						stencilBuffer: attributes.stencil,
						colorSpace: renderer.outputColorSpace,
						samples: if (attributes.antialias) 4 else 0,
						resolveDepthBuffer: (glProjLayer.ignoreDepthValues != false)
					}
				);
			}
			newRenderTarget.isXRRenderTarget = true;
			this.setFoveation(foveation);
			customReferenceSpace = null;
			referenceSpace = session.requestReferenceSpace(referenceSpaceType);
			animation.start();
			isPresenting = true;
			dispatchEvent({ type: 'sessionstart' });
		}
	}

	public function getEnvironmentBlendMode():Dynamic {
		if (session != null) {
			return session.environmentBlendMode;
		}
	}

	private function onInputSourcesChange(event:XRInputSourcesChangeEvent) {
		// Notify disconnected
		for (i in 0...event.removed.length) {
			var inputSource = event.removed[i];
			var index = controllerInputSources.indexOf(inputSource);
			if (index >= 0) {
				controllerInputSources[index] = null;
				controllers[index].disconnect(inputSource);
			}
		}
		// Notify connected
		for (i in 0...event.added.length) {
			var inputSource = event.added[i];
			var controllerIndex:Int = -1;
			// Assign input source a controller that currently has no input source
			for (i in 0...controllers.length) {
				if (i >= controllerInputSources.length) {
					controllerInputSources.push(inputSource);
					controllerIndex = i;
					break;
				} else if (controllerInputSources[i] == null) {
					controllerInputSources[i] = inputSource;
					controllerIndex = i;
					break;
				}
			}
			// If all controllers do currently receive input we ignore new ones
			if (controllerIndex == -1) {
				break;
			}
			var controller = controllers[controllerIndex];
			if (controller != null) {
				controller.connect(inputSource);
			}
		}
	}

	private var cameraLPos:Vector3;
	private var cameraRPos:Vector3;

	public function updateCamera(camera:PerspectiveCamera):Void {
		if (session == null) {
			return;
		}
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
		var parent = camera.parent;
		var cameras = cameraXR.cameras;
		updateCamera(cameraXR, parent);
		for (i in 0...cameras.length) {
			updateCamera(cameras[i], parent);
		}
		// update projection matrix for proper view frustum culling
		if (cameras.length == 2) {
			setProjectionFromUnion(cameraXR, cameraL, cameraR);
		} else {
			// assume single camera setup (AR)
			cameraXR.projectionMatrix.copy(cameraL.projectionMatrix);
		}
		// update user camera and its children
		updateUserCamera(camera, cameraXR, parent);
	}

	private function updateCamera(camera:PerspectiveCamera, parent:PerspectiveCamera):Void {
		if (parent == null) {
			camera.matrixWorld.copy(camera.matrix);
		} else {
			camera.matrixWorld.multiplyMatrices(parent.matrixWorld, camera.matrix);
		}
		camera.matrixWorldInverse.copy(camera.matrixWorld).invert();
	}

	private function updateUserCamera(camera:PerspectiveCamera, cameraXR:ArrayCamera, parent:PerspectiveCamera):Void {
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
			camera.fov = RAD2DEG * 2 * Math.atan(1 / camera.projectionMatrix.elements[5]);
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
		// 0 = no foveation = full resolution
		// 1 = maximum foveation = the edges render at lower resolution
		foveation = value;
		if (glProjLayer != null) {
			glProjLayer.fixedFoveation = value;
		}
		if (glBaseLayer != null && glBaseLayer.fixedFoveation != null) {
			glBaseLayer.fixedFoveation = value;
		}
	}

	public
	public function hasDepthSensing():Bool {
		return depthSensing.texture != null;
	}

	// Animation Loop

	private var onAnimationFrameCallback:Dynamic;

	private function onAnimationFrame(time:Float, frame:XRFrame) {
		pose = frame.getViewerPose(customReferenceSpace or referenceSpace);
		xrFrame = frame;
		if (pose != null) {
			var views = pose.views;
			if (glBaseLayer != null) {
				renderer.setRenderTargetFramebuffer(newRenderTarget, glBaseLayer.framebuffer);
				renderer.setRenderTarget(newRenderTarget);
			}
			var cameraXRNeedsUpdate:Bool = false;
			// check if it's necessary to rebuild cameraXR's camera list
			if (views.length != cameraXR.cameras.length) {
				cameraXR.cameras.length = 0;
				cameraXRNeedsUpdate = true;
			}
			for (i in 0...views.length) {
				var view = views[i];
				var viewport:Dynamic = null;
				if (glBaseLayer != null) {
					viewport = glBaseLayer.getViewport(view);
				} else {
					var glSubImage = glBinding.getViewSubImage(glProjLayer, view);
					viewport = glSubImage.viewport;
					// For side-by-side projection, we only produce a single texture for both eyes.
					if (i == 0) {
						renderer.setRenderTargetTextures(
							newRenderTarget,
							glSubImage.colorTexture,
							if (glProjLayer.ignoreDepthValues) null else glSubImage.depthStencilTexture
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
			//
			var enabledFeatures = session.enabledFeatures;
			if (enabledFeatures && enabledFeatures.includes('depth-sensing')) {
				var depthData = glBinding.getDepthInformation(views[0]);
				if (depthData && depthData.isValid && depthData.texture) {
					depthSensing.init(renderer, depthData, session.renderState);
				}
			}
		}
		//
		for (i in 0...controllers.length) {
			var inputSource = controllerInputSources[i];
			var controller = controllers[i];
			if (inputSource != null && controller != null) {
				controller.update(inputSource, frame, customReferenceSpace or referenceSpace);
			}
		}
		depthSensing.render(renderer, cameraXR);
		if (onAnimationFrameCallback != null) {
			onAnimationFrameCallback(time, frame);
		}
		if (frame.detectedPlanes) {
			dispatchEvent({ type: 'planesdetected', data: frame });
		}
		xrFrame = null;
	}

	public function setAnimationLoop(callback:Dynamic):Void {
		onAnimationFrameCallback = callback;
	}

	public function dispose():Void {
		// ...
	}

}