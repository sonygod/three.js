import three.cameras.ArrayCamera;
import three.core.EventDispatcher;
import three.cameras.PerspectiveCamera;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.MathUtils;
import three.renderers.webgl.WebGLAnimation;
import three.renderers.WebGLRenderTarget;
import three.xr.WebXRController;
import three.textures.DepthTexture;
import three.constants.Constants;
import three.xr.WebXRDepthSensing;
import js.Browser;

class WebXRManager extends EventDispatcher {

	public var cameraAutoUpdate : Bool;
	public var enabled(default,null) : Bool;
	public var isPresenting(default,null) : Bool;

	var renderer : Dynamic;
	var gl: Dynamic;
	
	var session: Dynamic = null;
	
	var framebufferScaleFactor: Float = 1.0;
	
	var referenceSpace: Dynamic = null;
	var referenceSpaceType: String = 'local-floor';
	var foveation: Float = 1.0; // Set default foveation to maximum.
	var customReferenceSpace: Dynamic = null;
	
	var pose: Dynamic = null;
	var glBinding: Dynamic = null;
	var glProjLayer: Dynamic = null;
	var glBaseLayer: Dynamic = null;
	var xrFrame: Dynamic = null;
	
	var depthSensing: WebXRDepthSensing;
	var attributes: Dynamic;
	
	var initialRenderTarget: WebGLRenderTarget = null;
	var newRenderTarget: WebGLRenderTarget = null;
	
	var controllers: Array<WebXRController> = [];
	var controllerInputSources: Array<Dynamic> = [];
	
	var currentSize: Vector2 = new Vector2();
	var currentPixelRatio: Float = null;
	
	var cameraL: PerspectiveCamera = new PerspectiveCamera();
	var cameraR: PerspectiveCamera = new PerspectiveCamera();
	var cameras: Array<PerspectiveCamera>;
	var cameraXR: ArrayCamera = new ArrayCamera();
	
	var _currentDepthNear: Float = null;
	var _currentDepthFar: Float = null;
	
	public function new(renderer, gl) {
		
		super();
		
		this.renderer = renderer;
		this.gl = gl;

		depthSensing = new WebXRDepthSensing();
		attributes = gl.getContextAttributes();
		
		cameraL.layers.enable(1);
		cameraL.viewport = new Vector4();
		
		cameraR.layers.enable(2);
		cameraR.viewport = new Vector4();
		
		cameras = [cameraL, cameraR];
		
		cameraXR.layers.enable(1);
		cameraXR.layers.enable(2);
		
		cameraAutoUpdate = true;
		enabled = false;
		isPresenting = false;
		
	}
	
	public function getController(index: Int): Dynamic {
		
		var controller = controllers[index];
		
		if (controller == null) {
			
			controller = new WebXRController();
			controllers[index] = controller;
			
		}
		
		return controller.getTargetRaySpace();
		
	}
	
	public function getControllerGrip(index: Int): Dynamic {
		
		var controller = controllers[index];
		
		if (controller == null) {
			
			controller = new WebXRController();
			controllers[index] = controller;
			
		}
		
		return controller.getGripSpace();
		
	}
	
	public function getHand(index: Int): Dynamic {
		
		var controller = controllers[index];
		
		if (controller == null) {
			
			controller = new WebXRController();
			controllers[index] = controller;
			
		}
		
		return controller.getHandSpace();
		
	}
	
	function onSessionEvent(event: Dynamic) {
		
		var controllerIndex = controllerInputSources.indexOf(event.inputSource);
		
		if (controllerIndex == -1) {
			
			return;
			
		}
		
		var controller = controllers[controllerIndex];
		
		if (controller != null) {
			
			controller.update(event.inputSource, event.frame, customReferenceSpace != null ? customReferenceSpace : referenceSpace);
			controller.dispatchEvent({ type: event.type, data: event.inputSource });
			
		}
		
	}
	
	function onSessionEnd() {
		
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
		
		// restore framebuffer/rendering state
		
		renderer.setRenderTarget(initialRenderTarget);
		
		glBaseLayer = null;
		glProjLayer = null;
		glBinding = null;
		session = null;
		newRenderTarget = null;
		
		//
		
		animation.stop();
		
		isPresenting = false;
		
		renderer.setPixelRatio(currentPixelRatio);
		renderer.setSize(currentSize.width, currentSize.height, false);
		
		dispatchEvent({ type: 'sessionend' });
		
	}
	
	public function setFramebufferScaleFactor(value: Float) {
		
		framebufferScaleFactor = value;
		
		if (isPresenting == true) {
			
			trace('THREE.WebXRManager: Cannot change framebuffer scale while presenting.');
			
		}
		
	}
	
	public function setReferenceSpaceType(value: String) {
		
		referenceSpaceType = value;
		
		if (isPresenting == true) {
			
			trace('THREE.WebXRManager: Cannot change reference space type while presenting.');
			
		}
		
	}
	
	public function getReferenceSpace(): Dynamic {
		
		return customReferenceSpace != null ? customReferenceSpace : referenceSpace;
		
	}
	
	public function setReferenceSpace(space: Dynamic) {
		
		customReferenceSpace = space;
		
	}
	
	public function getBaseLayer(): Dynamic {
		
		return glProjLayer != null ? glProjLayer : glBaseLayer;
		
	}
	
	public function getBinding(): Dynamic {
		
		return glBinding;
		
	}
	
	public function getFrame(): Dynamic {
		
		return xrFrame;
		
	}
	
	public function getSession(): Dynamic {
		
		return session;
		
	}
	
	public function setSession(value: Dynamic) : Void {
		
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
				
				// await gl.makeXRCompatible();
				
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
				
				glBaseLayer = new Browser.window.XRWebGLLayer(session, gl, layerInit);
				
				session.updateRenderState({ baseLayer: glBaseLayer });
				
				renderer.setPixelRatio(1);
				renderer.setSize(glBaseLayer.framebufferWidth, glBaseLayer.framebufferHeight, false);
				
				newRenderTarget = new WebGLRenderTarget(
					glBaseLayer.framebufferWidth,
					glBaseLayer.framebufferHeight,
					{
						format: Constants.RGBAFormat,
						type: Constants.UnsignedByteType,
						colorSpace: renderer.outputColorSpace,
						stencilBuffer: attributes.stencil
					}
				);
				
			} else {
				
				var depthFormat: Int = null;
				var depthType: Int = null;
				var glDepthFormat: Int = null;
				
				if (attributes.depth) {
					
					glDepthFormat = attributes.stencil ? gl.DEPTH24_STENCIL8 : gl.DEPTH_COMPONENT24;
					depthFormat = attributes.stencil ? Constants.DepthStencilFormat : Constants.DepthFormat;
					depthType = attributes.stencil ? Constants.UnsignedInt248Type : Constants.UnsignedIntType;
					
				}
				
				var projectionlayerInit = {
					colorFormat: gl.RGBA8,
					depthFormat: glDepthFormat,
					scaleFactor: framebufferScaleFactor
				};
				
				glBinding = new Browser.window.XRWebGLBinding(session, gl);
				
				glProjLayer = glBinding.createProjectionLayer(projectionlayerInit);
				
				session.updateRenderState({ layers: [glProjLayer] });
				
				renderer.setPixelRatio(1);
				renderer.setSize(glProjLayer.textureWidth, glProjLayer.textureHeight, false);
				
				newRenderTarget = new WebGLRenderTarget(
					glProjLayer.textureWidth,
					glProjLayer.textureHeight,
					{
						format: Constants.RGBAFormat,
						type: Constants.UnsignedByteType,
						depthTexture: new DepthTexture(glProjLayer.textureWidth, glProjLayer.textureHeight, depthType, undefined, undefined, undefined, undefined, undefined, undefined, depthFormat),
						stencilBuffer: attributes.stencil,
						colorSpace: renderer.outputColorSpace,
						samples: attributes.antialias ? 4 : 0,
						resolveDepthBuffer: (glProjLayer.ignoreDepthValues == false)
					}
				);
				
			}
			
			// newRenderTarget.isXRRenderTarget = true; // TODO Remove this when possible, see #23278
			
			setFoveation(foveation);
			
			customReferenceSpace = null;
			// referenceSpace = await session.requestReferenceSpace(referenceSpaceType);
			
			animation.setContext(session);
			animation.start();
			
			isPresenting = true;
			
			dispatchEvent({ type: 'sessionstart' });
			
		}
		
	}
	
	public function getEnvironmentBlendMode(): Dynamic {
		
		if (session != null) {
			
			return session.environmentBlendMode;
			
		}
		
		return null;
	}
	
	function onInputSourcesChange(event: Dynamic) {
		
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
			
			var controllerIndex = controllerInputSources.indexOf(inputSource);
			
			if (controllerIndex == -1) {
				
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
				
			}
			
			var controller = controllers[controllerIndex];
			
			if (controller != null) {
				
				controller.connect(inputSource);
				
			}
			
		}
		
	}
	
	//
	
	var cameraLPos: Vector3 = new Vector3();
	var cameraRPos: Vector3 = new Vector3();
	
	/**
	 * Assumes 2 cameras that are parallel and share an X-axis, and that
	 * the cameras' projection and world matrices have already been set.
	 * And that near and far planes are identical for both cameras.
	 * Visualization of this technique: https://computergraphics.stackexchange.com/a/4765
	 */
	function setProjectionFromUnion(camera: ArrayCamera, cameraL: PerspectiveCamera, cameraR: PerspectiveCamera) {
		
		cameraLPos.setFromMatrixPosition(cameraL.matrixWorld);
		cameraRPos.setFromMatrixPosition(cameraR.matrixWorld);
		
		var ipd = cameraLPos.distanceTo(cameraRPos);
		
		var projL = cameraL.projectionMatrix.elements;
		var projR = cameraR.projectionMatrix.elements;
		
		// VR systems will have identical far and near planes, and
		// most likely identical top and bottom frustum extents.
		// Use the left camera for these values.
		var near = projL[14] / (projL[10] - 1);
		var far = projL[14] / (projL[10] + 1);
		var topFov = (projL[9] + 1) / projL[5];
		var bottomFov = (projL[9] - 1) / projL[5];
		
		var leftFov = (projL[8] - 1) / projL[0];
		var rightFov = (projR[8] + 1) / projR[0];
		var left = near * leftFov;
		var right = near * rightFov;
		
		// Calculate the new camera's position offset from the
		// left camera. xOffset should be roughly half `ipd`.
		var zOffset = ipd / (-leftFov + rightFov);
		var xOffset = zOffset * -leftFov;
		
		// TODO: Better way to apply this offset?
		cameraL.matrixWorld.decompose(camera.position, camera.quaternion, camera.scale);
		camera.translateX(xOffset);
		camera.translateZ(zOffset);
		camera.matrixWorld.compose(camera.position, camera.quaternion, camera.scale);
		camera.matrixWorldInverse.copy(camera.matrixWorld).invert();
		
		// Find the union of the frustum values of the cameras and scale
		// the values so that the near plane's position does not change in world space,
		// although must now be relative to the new union camera.
		var near2 = near + zOffset;
		var far2 = far + zOffset;
		var left2 = left - xOffset;
		var right2 = right + (ipd - xOffset);
		var top2 = topFov * far / far2 * near2;
		var bottom2 = bottomFov * far / far2 * near2;
		
		camera.projectionMatrix.makePerspective(left2, right2, top2, bottom2, near2, far2);
		camera.projectionMatrixInverse.copy(camera.projectionMatrix).invert();
		
	}
	
	function updateCamera(camera: Dynamic, parent: Dynamic) {
		
		if (parent == null) {
			
			camera.matrixWorld.copy(camera.matrix);
			
		} else {
			
			camera.matrixWorld.multiplyMatrices(parent.matrixWorld, camera.matrix);
			
		}
		
		camera.matrixWorldInverse.copy(camera.matrixWorld).invert();
		
	}
	
	public function updateCamera(camera: Dynamic) {
		
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
			
			// Note that the new renderState won't apply until the next frame. See #18320
			
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
	
	function updateUserCamera(camera: Dynamic, cameraXR: Dynamic, parent: Dynamic) {
		
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
	
	public function getCamera(): ArrayCamera {
		
		return cameraXR;
		
	}
	
	public function getFoveation(): Dynamic {
		
		if (glProjLayer == null && glBaseLayer == null) {
			
			return null;
			
		}
		
		return foveation;
		
	}
	
	public function setFoveation(value: Float) {
		
		// 0 = no foveation = full resolution
		// 1 = maximum foveation = the edges render at lower resolution
		
		foveation = value;
		
		if (glProjLayer != null) {
			
			glProjLayer.fixedFoveation = value;
			
		}
		
		if (glBaseLayer != null && Reflect.hasField(glBaseLayer, 'fixedFoveation')) {
			
			glBaseLayer.fixedFoveation = value;
			
		}
		
	}
	
	public function hasDepthSensing(): Bool {
		
		return depthSensing.texture != null;
		
	}
	
	// Animation Loop
	
	var onAnimationFrameCallback: Dynamic = null;
	
	function onAnimationFrame(time: Float, frame: Dynamic) {
		
		pose = frame.getViewerPose(customReferenceSpace != null ? customReferenceSpace : referenceSpace);
		xrFrame = frame;
		
		if (pose != null) {
			
			var views = pose.views;
			
			if (glBaseLayer != null) {
				
				renderer.setRenderTargetFramebuffer(newRenderTarget, glBaseLayer.framebuffer);
				renderer.setRenderTarget(newRenderTarget);
				
			}
			
			var cameraXRNeedsUpdate = false;
			
			// check if it's necessary to rebuild cameraXR's camera list
			
			if (views.length != cameraXR.cameras.length) {
				
				cameraXR.cameras.length = 0;
				cameraXRNeedsUpdate = true;
				
			}
			
			for (i in 0...views.length) {
				
				var view = views[i];
				
				var viewport: Dynamic = null;
				
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
							glProjLayer.ignoreDepthValues ? null : glSubImage.depthStencilTexture
						);
						
						renderer.setRenderTarget(newRenderTarget);
						
					}
					
				}
				
				var camera: PerspectiveCamera = cameras[i];
				
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
				
				if (cameraXRNeedsUpdate == true) {
					
					cameraXR.cameras.push(camera);
					
				}
				
			}
			
			//
			
			var enabledFeatures = session.enabledFeatures;
			
			if (enabledFeatures != null && enabledFeatures.includes('depth-sensing')) {
				
				var depthData = glBinding.getDepthInformation(views[0]);
				
				if (depthData != null && depthData.isValid && depthData.texture != null) {
					
					depthSensing.init(renderer, depthData, session.renderState);
					
				}
				
			}
			
		}
		
		//
		
		for (i in 0...controllers.length) {
			
			var inputSource = controllerInputSources[i];
			var controller = controllers[i];
			
			if (inputSource != null && controller != null) {
				
				controller.update(inputSource, frame, customReferenceSpace != null ? customReferenceSpace : referenceSpace);
				
			}
			
		}
		
		depthSensing.render(renderer, cameraXR);
		
		if (onAnimationFrameCallback != null) {
			onAnimationFrameCallback(time, frame);
		}
		
		if (frame.detectedPlanes != null) {
			
			dispatchEvent({ type: 'planesdetected', data: frame });
			
		}
		
		xrFrame = null;
		
	}
	
	var animation: WebGLAnimation = new WebGLAnimation();
	
	{
		animation.setAnimationLoop(onAnimationFrame);
	}
	
	public function setAnimationLoop(callback: Dynamic) {
		
		onAnimationFrameCallback = callback;
		
	}
	
	public function dispose() {
		
	}
	
}