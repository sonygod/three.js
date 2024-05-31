import three.js.examples.jsm.lights.DirectionalLight;
import three.js.examples.jsm.lights.LightProbe;
import three.js.examples.jsm.lights.WebGLCubeRenderTarget;
import three.js.examples.jsm.objects.Group;

class SessionLightProbe {

	public var xrLight:Dynamic;
	public var renderer:Dynamic;
	public var lightProbe:LightProbe;
	public var xrWebGLBinding:Dynamic;
	public var estimationStartCallback:Dynamic;
	public var frameCallback:Dynamic;

	public function new(xrLight:Dynamic, renderer:Dynamic, lightProbe:LightProbe, environmentEstimation:Bool, estimationStartCallback:Dynamic) {
		this.xrLight = xrLight;
		this.renderer = renderer;
		this.lightProbe = lightProbe;
		this.xrWebGLBinding = null;
		this.estimationStartCallback = estimationStartCallback;
		this.frameCallback = this.onXRFrame.bind(this);

		var session = renderer.xr.getSession();

		if (environmentEstimation && 'XRWebGLBinding' in window) {
			var cubeRenderTarget = new WebGLCubeRenderTarget(16);
			xrLight.environment = cubeRenderTarget.texture;

			var gl = renderer.getContext();

			switch (session.preferredReflectionFormat) {
				case 'srgba8':
					gl.getExtension('EXT_sRGB');
					break;
				case 'rgba16f':
					gl.getExtension('OES_texture_half_float');
					break;
			}

			this.xrWebGLBinding = new XRWebGLBinding(session, gl);

			lightProbe.addEventListener('reflectionchange', function() {
				this.updateReflection();
			});
		}

		session.requestAnimationFrame(this.frameCallback);
	}

	public function updateReflection() {
		var textureProperties = renderer.properties.get(xrLight.environment);

		if (textureProperties) {
			var cubeMap = xrWebGLBinding.getReflectionCubeMap(lightProbe);

			if (cubeMap) {
				textureProperties.__webglTexture = cubeMap;
				xrLight.environment.needsPMREMUpdate = true;
			}
		}
	}

	public function onXRFrame(time:Float, xrFrame:Dynamic) {
		if (!this.xrLight) {
			return;
		}

		var session = xrFrame.session;
		session.requestAnimationFrame(this.frameCallback);

		var lightEstimate = xrFrame.getLightEstimate(lightProbe);
		if (lightEstimate) {
			var intensityScalar = Math.max(1.0, Math.max(lightEstimate.primaryLightIntensity.x, Math.max(lightEstimate.primaryLightIntensity.y, lightEstimate.primaryLightIntensity.z)));

			xrLight.lightProbe.sh.fromArray(lightEstimate.sphericalHarmonicsCoefficients);
			xrLight.lightProbe.intensity = 1.0;

			xrLight.directionalLight.color.setRGB(lightEstimate.primaryLightIntensity.x / intensityScalar, lightEstimate.primaryLightIntensity.y / intensityScalar, lightEstimate.primaryLightIntensity.z / intensityScalar);
			xrLight.directionalLight.intensity = intensityScalar;
			xrLight.directionalLight.position.copy(lightEstimate.primaryLightDirection);

			if (this.estimationStartCallback) {
				this.estimationStartCallback();
				this.estimationStartCallback = null;
			}
		}
	}

	public function dispose() {
		this.xrLight = null;
		this.renderer = null;
		this.lightProbe = null;
		this.xrWebGLBinding = null;
	}
}

class XREstimatedLight extends Group {

	public var lightProbe:LightProbe;
	public var directionalLight:DirectionalLight;
	public var environment:Dynamic;
	public var sessionLightProbe:Dynamic;
	public var estimationStarted:Bool;

	public function new(renderer:Dynamic, environmentEstimation:Bool = true) {
		super();

		this.lightProbe = new LightProbe();
		this.lightProbe.intensity = 0;
		this.add(this.lightProbe);

		this.directionalLight = new DirectionalLight();
		this.directionalLight.intensity = 0;
		this.add(this.directionalLight);

		this.environment = null;

		this.sessionLightProbe = null;
		this.estimationStarted = false;

		renderer.xr.addEventListener('sessionstart', function() {
			var session = renderer.xr.getSession();

			if ('requestLightProbe' in session) {
				session.requestLightProbe({
					reflectionFormat: session.preferredReflectionFormat
				}).then(function(probe) {
					this.sessionLightProbe = new SessionLightProbe(this, renderer, probe, environmentEstimation, function() {
						this.estimationStarted = true;
						this.dispatchEvent({type: 'estimationstart'});
					});
				});
			}
		});

		renderer.xr.addEventListener('sessionend', function() {
			if (this.sessionLightProbe) {
				this.sessionLightProbe.dispose();
				this.sessionLightProbe = null;
			}

			if (this.estimationStarted) {
				this.dispatchEvent({type: 'estimationend'});
			}
		});

		this.dispose = function() {
			if (this.sessionLightProbe) {
				this.sessionLightProbe.dispose();
				this.sessionLightProbe = null;
			}

			this.remove(this.lightProbe);
			this.lightProbe = null;

			this.remove(this.directionalLight);
			this.directionalLight = null;

			this.environment = null;
		};
	}
}