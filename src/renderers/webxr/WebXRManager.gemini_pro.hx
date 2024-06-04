import three.cameras.ArrayCamera;
import three.cameras.PerspectiveCamera;
import three.core.EventDispatcher;
import three.math.MathUtils;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.renderers.webgl.WebGLAnimation;
import three.renderers.webgl.WebGLRenderTarget;
import three.textures.DepthTexture;
import three.constants.DepthFormat;
import three.constants.DepthStencilFormat;
import three.constants.RGBAFormat;
import three.constants.UnsignedByteType;
import three.constants.UnsignedIntType;
import three.constants.UnsignedInt248Type;
import webxr.WebXRController;
import webxr.WebXRDepthSensing;

class WebXRManager extends EventDispatcher {

	public var cameraAutoUpdate:Bool = true;
	public var enabled:Bool = false;
	public var isPresenting:Bool = false;

	private var session:Dynamic = null;
	private var framebufferScaleFactor:Float = 1.0;
	private var referenceSpace:Dynamic = null;
	private var referenceSpaceType:String = "local-floor";
	private var foveation:Float = 1.0;
	private var customReferenceSpace:Dynamic = null;
	private var pose:Dynamic = null;
	private var glBinding:Dynamic = null;
	private var glProjLayer:Dynamic = null;
	private var glBaseLayer:Dynamic = null;
	private var xrFrame:Dynamic = null;
	private var depthSensing:WebXRDepthSensing;
	private var attributes:Dynamic = null;
	private var initialRenderTarget:WebGLRenderTarget = null;
	private var newRenderTarget:WebGLRenderTarget = null;
	private var controllers:Array<WebXRController> = [];
	private var controllerInputSources:Array<Dynamic> = [];
	private var currentSize:Vector2 = new Vector2();
	private var currentPixelRatio:Float = null;
	private var cameraL:PerspectiveCamera = new PerspectiveCamera();
	private var cameraR:PerspectiveCamera = new PerspectiveCamera();
	private var cameras:Array<PerspectiveCamera> = [cameraL, cameraR];
	private var cameraXR:ArrayCamera = new ArrayCamera();
	private var _currentDepthNear:Float = null;
	private var _currentDepthFar:Float = null;
	private var cameraLPos:Vector3 = new Vector3();
	private var cameraRPos:Vector3 = new Vector3();
	private var onAnimationFrameCallback:Dynamic = null;
	private var animation:WebGLAnimation = new WebGLAnimation();

	public function new(renderer:Dynamic, gl:Dynamic) {
		super();

		depthSensing = new WebXRDepthSensing();
		attributes = gl.getContextAttributes();

		cameraL.layers.enable(1);
		cameraL.viewport = new Vector4();
		cameraR.layers.enable(2);
		cameraR.viewport = new Vector4();
		cameraXR.layers.enable(1);
		cameraXR.layers.enable(2);

		animation.setAnimationLoop(onAnimationFrame);

		// Set default foveation to maximum.
		foveation = 1.0;

		this.setFramebufferScaleFactor = function(value:Float) {
			framebufferScaleFactor = value;
			if (isPresenting) {
				console.warn("THREE.WebXRManager: Cannot change framebuffer scale while presenting.");
			}
		};

		this.setReferenceSpaceType = function(value:String) {
			referenceSpaceType = value;
			if (isPresenting) {
				console.warn("THREE.WebXRManager: Cannot change reference space type while presenting.");
			}
		};

		this.getReferenceSpace = function() {
			return customReferenceSpace || referenceSpace;
		};

		this.setReferenceSpace = function(space:Dynamic) {
			customReferenceSpace = space;
		};

		this.getBaseLayer = function() {
			return glProjLayer != null ? glProjLayer : glBaseLayer;
		};

		this.getBinding = function() {
			return glBinding;
		};

		this.getFrame = function() {
			return xrFrame;
		};

		this.getSession = function() {
			return session;
		};

		this.setSession = function(value:Dynamic) {
			session = value;
			if (session != null) {
				initialRenderTarget = renderer.getRenderTarget();
				session.addEventListener("select", onSessionEvent);
				session.addEventListener("selectstart", onSessionEvent);
				session.addEventListener("selectend", onSessionEvent);
				session.addEventListener("squeeze", onSessionEvent);
				session.addEventListener("squeezestart", onSessionEvent);
				session.addEventListener("squeezeend", onSessionEvent);
				session.addEventListener("end", onSessionEnd);
				session.addEventListener("inputsourceschange", onInputSourcesChange);
				if (attributes.xrCompatible != true) {
					gl.makeXRCompatible().then(function() {});
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
					session.updateRenderState({baseLayer: glBaseLayer});
					renderer.setPixelRatio(1);
					renderer.setSize(glBaseLayer.framebufferWidth, glBaseLayer.framebufferHeight, false);
					newRenderTarget = new WebGLRenderTarget(glBaseLayer.framebufferWidth, glBaseLayer.framebufferHeight, {
						format: RGBAFormat,
						type: UnsignedByteType,
						colorSpace: renderer.outputColorSpace,
						stencilBuffer: attributes.stencil
					});
				} else {
					var depthFormat:Int = null;
					var depthType:Int = null;
					var glDepthFormat:Int = null;
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
					newRenderTarget = new WebGLRenderTarget(glProjLayer.textureWidth, glProjLayer.textureHeight, {
						format: RGBAFormat,
						type: UnsignedByteType,
						depthTexture: new DepthTexture(glProjLayer.textureWidth, glProjLayer.textureHeight, depthType, null, null, null, null, null, null, depthFormat),
						stencilBuffer: attributes.stencil,
						colorSpace: renderer.outputColorSpace,
						samples: attributes.antialias ? 4 : 0,
						resolveDepthBuffer: (glProjLayer.ignoreDepthValues == false)
					});
				}
				newRenderTarget.isXRRenderTarget = true; // TODO Remove this when possible, see #23278
				this.setFoveation(foveation);
				customReferenceSpace = null;
				session.requestReferenceSpace(referenceSpaceType).then(function(space) {
					referenceSpace = space;
				});
				animation.setContext(session);
				animation.start();
				isPresenting = true;
				this.dispatchEvent({type: "sessionstart"});
			}
		};

		this.getEnvironmentBlendMode = function() {
			if (session != null) {
				return session.environmentBlendMode;
			}
			return null;
		};

		this.getController = function(index:Int) {
			var controller = controllers[index];
			if (controller == null) {
				controller = new WebXRController();
				controllers[index] = controller;
			}
			return controller.getTargetRaySpace();
		};

		this.getControllerGrip = function(index:Int) {
			var controller = controllers[index];
			if (controller == null) {
				controller = new WebXRController();
				controllers[index] = controller;
			}
			return controller.getGripSpace();
		};

		this.getHand = function(index:Int) {
			var controller = controllers[index];
			if (controller == null) {
				controller = new WebXRController();
				controllers[index] = controller;
			}
			return controller.getHandSpace();
		};

		this.getFoveation = function() {
			if (glProjLayer == null && glBaseLayer == null) {
				return null;
			}
			return foveation;
		};

		this.setFoveation = function(value:Float) {
			// 0 = no foveation = full resolution
			// 1 = maximum foveation = the edges render at lower resolution
			foveation = value;
			if (glProjLayer != null) {
				glProjLayer.fixedFoveation = value;
			}
			if (glBaseLayer != null && glBaseLayer.fixedFoveation != null) {
				glBaseLayer.fixedFoveation = value;
			}
		};

		this.hasDepthSensing = function() {
			return depthSensing.texture != null;
		};

		this.setAnimationLoop = function(callback:Dynamic) {
			onAnimationFrameCallback = callback;
		};

		this.dispose = function() {};

		function onSessionEvent(event:Dynamic) {
			var controllerIndex = controllerInputSources.indexOf(event.inputSource);
			if (controllerIndex == - 1) {
				return;
			}
			var controller = controllers[controllerIndex];
			if (controller != null) {
				controller.update(event.inputSource, event.frame, customReferenceSpace || referenceSpace);
				controller.dispatchEvent({type: event.type, data: event.inputSource});
			}
		}

		function onSessionEnd() {
			session.removeEventListener("select", onSessionEvent);
			session.removeEventListener("selectstart", onSessionEvent);
			session.removeEventListener("selectend", onSessionEvent);
			session.removeEventListener("squeeze", onSessionEvent);
			session.removeEventListener("squeezestart", onSessionEvent);
			session.removeEventListener("squeezeend", onSessionEvent);
			session.removeEventListener("end", onSessionEnd);
			session.removeEventListener("inputsourceschange", onInputSourcesChange);
			for (var i = 0; i < controllers.length; i++) {
				var inputSource = controllerInputSources[i];
				if (inputSource == null) continue;
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
			this.dispatchEvent({type: "sessionend"});
		}

		function onInputSourcesChange(event:Dynamic) {
			// Notify disconnected
			for (var i = 0; i < event.removed.length; i++) {
				var inputSource = event.removed[i];
				var index = controllerInputSources.indexOf(inputSource);
				if (index >= 0) {
					controllerInputSources[index] = null;
					controllers[index].disconnect(inputSource);
				}
			}
			// Notify connected
			for (var i = 0; i < event.added.length; i++) {
				var inputSource = event.added[i];
				var controllerIndex = controllerInputSources.indexOf(inputSource);
				if (controllerIndex == - 1) {
					// Assign input source a controller that currently has no input source
					for (var i = 0; i < controllers.length; i++) {
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
					if (controllerIndex == - 1) break;
				}
				var controller = controllers[controllerIndex];
				if (controller != null) {
					controller.connect(inputSource);
				}
			}
		}

		function setProjectionFromUnion(camera:ArrayCamera, cameraL:PerspectiveCamera, cameraR:PerspectiveCamera) {
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

		function updateCamera(camera:PerspectiveCamera, parent:Dynamic) {
			if (parent == null) {
				camera.matrixWorld.copy(camera.matrix);
			} else {
				camera.matrixWorld.multiplyMatrices(parent.matrixWorld, camera.matrix);
			}
			camera.matrixWorldInverse.copy(camera.matrixWorld).invert();
		}

		this.updateCamera = function(camera:PerspectiveCamera) {
			if (session == null) return;
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
			for (var i = 0; i < cameras.length; i++) {
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
		};

		function updateUserCamera(camera:PerspectiveCamera, cameraXR:ArrayCamera, parent:Dynamic) {
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

		this.getCamera = function() {
			return cameraXR;
		};

		function onAnimationFrame(time:Float, frame:Dynamic) {
			pose = frame.getViewerPose(customReferenceSpace || referenceSpace);
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
				for (var i = 0; i < views.length; i++) {
					var view = views[i];
					var viewport:Dynamic = null;
					if (glBaseLayer != null) {
						viewport = glBaseLayer.getViewport(view);
					} else {
						var glSubImage = glBinding.getViewSubImage(glProjLayer, view);
						viewport = glSubImage.viewport;
						// For side-by-side projection, we only produce a single texture for both eyes.
						if (i == 0) {
							renderer.setRenderTargetTextures(newRenderTarget, glSubImage.colorTexture, glProjLayer.ignoreDepthValues ? null : glSubImage.depthStencilTexture);
							renderer.setRenderTarget(newRenderTarget);
						}
					}
					var camera = cameras[i];
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
				if (enabledFeatures && enabledFeatures.includes("depth-sensing")) {
					var depthData = glBinding.getDepthInformation(views[0]);
					if (depthData && depthData.isValid && depthData.texture) {
						depthSensing.init(renderer, depthData, session.renderState);
					}
				}
			}
			//
			for (var i = 0; i < controllers.length; i++) {
				var inputSource = controllerInputSources[i];
				var controller = controllers[i];
				if (inputSource != null && controller != null) {
					controller.update(inputSource, frame, customReferenceSpace || referenceSpace);
				}
			}
			depthSensing.render(renderer, cameraXR);
			if (onAnimationFrameCallback != null) onAnimationFrameCallback(time, frame);
			if (frame.detectedPlanes) {
				this.dispatchEvent({type: "planesdetected", data: frame});
			}
			xrFrame = null;
		}
	}
}