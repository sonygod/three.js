import three.DirectionalLight;
import three.Group;
import three.LightProbe;
import three.WebGLCubeRenderTarget;
import three.WebGLRenderer;
import three.Texture;
import three.TextureProperties;
import three.Material;

class SessionLightProbe {
	public var xrLight:XREstimatedLight;
	public var renderer:WebGLRenderer;
	public var lightProbe:LightProbe;
	public var xrWebGLBinding:Dynamic = null;
	public var estimationStartCallback:Void->Void = null;
	public var frameCallback:Float->Dynamic = null;

	public function new(xrLight:XREstimatedLight, renderer:WebGLRenderer, lightProbe:LightProbe, environmentEstimation:Bool, estimationStartCallback:Void->Void) {
		this.xrLight = xrLight;
		this.renderer = renderer;
		this.lightProbe = lightProbe;
		this.xrWebGLBinding = null;
		this.estimationStartCallback = estimationStartCallback;
		this.frameCallback = this.onXRFrame;

		// TODO: This needs to be replaced with something more reliable
		if (environmentEstimation && js.Lib.exists(js.Browser.window, "XRWebGLBinding")) {
			var cubeRenderTarget = new WebGLCubeRenderTarget(16);
			xrLight.environment = cubeRenderTarget.texture;
			var gl = renderer.getContext();
			switch (renderer.xr.getSession().preferredReflectionFormat) {
				case "srgba8":
					gl.getExtension("EXT_sRGB");
				case "rgba16f":
					gl.getExtension("OES_texture_half_float");
			}
			this.xrWebGLBinding = new js.Browser.window.XRWebGLBinding(renderer.xr.getSession(), gl);
			this.lightProbe.addEventListener("reflectionchange", this.updateReflection);
		}
		renderer.xr.getSession().requestAnimationFrame(this.frameCallback);
	}

	public function updateReflection() {
		var textureProperties = renderer.properties.get(xrLight.environment);
		if (textureProperties != null) {
			var cubeMap = this.xrWebGLBinding.getReflectionCubeMap(this.lightProbe);
			if (cubeMap != null) {
				textureProperties.__webglTexture = cubeMap;
				xrLight.environment.needsPMREMUpdate = true;
			}
		}
	}

	public function onXRFrame(time:Float, xrFrame:Dynamic) {
		if (this.xrLight == null) {
			return;
		}
		var session = xrFrame.session;
		session.requestAnimationFrame(this.frameCallback);
		var lightEstimate = xrFrame.getLightEstimate(this.lightProbe);
		if (lightEstimate != null) {
			this.xrLight.lightProbe.sh.fromArray(lightEstimate.sphericalHarmonicsCoefficients);
			this.xrLight.lightProbe.intensity = 1.0;
			var intensityScalar = Math.max(1.0, Math.max(lightEstimate.primaryLightIntensity.x, Math.max(lightEstimate.primaryLightIntensity.y, lightEstimate.primaryLightIntensity.z)));
			this.xrLight.directionalLight.color.setRGB(lightEstimate.primaryLightIntensity.x / intensityScalar, lightEstimate.primaryLightIntensity.y / intensityScalar, lightEstimate.primaryLightIntensity.z / intensityScalar);
			this.xrLight.directionalLight.intensity = intensityScalar;
			this.xrLight.directionalLight.position.copy(lightEstimate.primaryLightDirection);
			if (this.estimationStartCallback != null) {
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
	public var environment:Texture;
	public var sessionLightProbe:SessionLightProbe = null;
	public var estimationStarted:Bool = false;

	public function new(renderer:WebGLRenderer, environmentEstimation:Bool = true) {
		super();
		this.lightProbe = new LightProbe();
		this.lightProbe.intensity = 0;
		this.add(this.lightProbe);
		this.directionalLight = new DirectionalLight();
		this.directionalLight.intensity = 0;
		this.add(this.directionalLight);
		this.environment = null;
		renderer.xr.addEventListener("sessionstart", this.onSessionStart(renderer, environmentEstimation));
		renderer.xr.addEventListener("sessionend", this.onSessionEnd);
	}

	public function onSessionStart(renderer:WebGLRenderer, environmentEstimation:Bool):Dynamic->Void {
		return function(e:Dynamic) {
			var session = renderer.xr.getSession();
			if (js.Lib.exists(session, "requestLightProbe")) {
				session.requestLightProbe({ reflectionFormat: session.preferredReflectionFormat }).then(function(probe:LightProbe) {
					this.sessionLightProbe = new SessionLightProbe(this, renderer, probe, environmentEstimation, function() {
						this.estimationStarted = true;
						this.dispatchEvent({ type: "estimationstart" });
					});
				});
			}
		};
	}

	public function onSessionEnd(e:Dynamic) {
		if (this.sessionLightProbe != null) {
			this.sessionLightProbe.dispose();
			this.sessionLightProbe = null;
		}
		if (this.estimationStarted) {
			this.dispatchEvent({ type: "estimationend" });
		}
	}

	public function dispose() {
		if (this.sessionLightProbe != null) {
			this.sessionLightProbe.dispose();
			this.sessionLightProbe = null;
		}
		this.remove(this.lightProbe);
		this.lightProbe = null;
		this.remove(this.directionalLight);
		this.directionalLight = null;
		this.environment = null;
	}
}