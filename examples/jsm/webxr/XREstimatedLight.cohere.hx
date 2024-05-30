package;

import js.WebGLRenderingContext;
import js.WebXR.XRFrame;
import js.WebXR.XRFrameRequestCallback;
import js.WebXR.XRLightEstimate;
import js.WebXR.XRSession;
import js.WebXR.XRWebGLBinding;
import js.three.Group;
import js.three.LightProbe;
import js.three.WebGLCubeRenderTarget;
import js.three.DirectionalLight;

class SessionLightProbe {
    public var xrLight:Dynamic;
    public var renderer:Dynamic;
    public var lightProbe:LightProbe;
    public var xrWebGLBinding:XRWebGLBinding;
    public var estimationStartCallback:Dynamic;
    public var frameCallback:XRFrameRequestCallback;

    public function new(xrLight:Dynamic, renderer:Dynamic, lightProbe:LightProbe, environmentEstimation:Bool, estimationStartCallback:Dynamic) {
        this.xrLight = xrLight;
        this.renderer = renderer;
        this.lightProbe = lightProbe;
        this.estimationStartCallback = estimationStartCallback;
        this.frameCallback = $bind(this, 'onXRFrame');

        var session = renderer.xr.getSession();

        if (environmentEstimation && js.Sys.exists(window, 'XRWebGLBinding')) {
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

            lightProbe.addEventListener('reflectionchange', $bind(this, 'updateReflection'));
        }

        session.requestAnimationFrame(this.frameCallback);
    }

    public function updateReflection() {
        var textureProperties = renderer.properties.get(xrLight.environment);

        if (textureProperties != null) {
            var cubeMap = xrWebGLBinding.getReflectionCubeMap(lightProbe);

            if (cubeMap != null) {
                textureProperties.__webglTexture = cubeMap;
                xrLight.environment.needsPMREMUpdate = true;
            }
        }
    }

    public function onXRFrame(time:Float, xrFrame:XRFrame) {
        if (xrLight == null) {
            return;
        }

        var session = xrFrame.session;
        session.requestAnimationFrame(frameCallback);

        var lightEstimate = xrFrame.getLightEstimate(lightProbe);
        if (lightEstimate != null) {
            xrLight.lightProbe.sh.fromArray(lightEstimate.sphericalHarmonicsCoefficients);
            xrLight.lightProbe.intensity = 1.0;

            var intensityScalar = Math.max(1.0, Math.max(lightEstimate.primaryLightIntensity.x, Math.max(lightEstimate.primaryLightIntensity.y, lightEstimate.primaryLightIntensity.z)));

            xrLight.directionalLight.color.setRGB(lightEstimate.primaryLightIntensity.x / intensityScalar, lightEstimate.primaryLightIntensity.y / intensityScalar, lightEstimate.primaryLightIntensity.z / intensityScalar);
            xrLight.directionalLight.intensity = intensityScalar;
            xrLight.directionalLight.position.copy(lightEstimate.primaryLightDirection);

            if (estimationStartCallback != null) {
                estimationStartCallback();
                estimationStartCallback = null;
            }
        }
    }

    public function dispose() {
        xrLight = null;
        renderer = null;
        lightProbe = null;
        xrWebGLBinding = null;
    }
}

class XREstimatedLight extends Group {
    public var lightProbe:LightProbe;
    public var directionalLight:DirectionalLight;
    public var environment:Dynamic;
    public var sessionLightProbe:SessionLightProbe;
    public var estimationStarted:Bool;

    public function new(renderer:Dynamic, environmentEstimation:Bool = true) {
        super();

        lightProbe = new LightProbe();
        lightProbe.intensity = 0;
        this.add(lightProbe);

        directionalLight = new DirectionalLight();
        directionalLight.intensity = 0;
        this.add(directionalLight);

        environment = null;
        sessionLightProbe = null;
        estimationStarted = false;

        renderer.xr.addEventListener('sessionstart', $bind(this, 'onSessionStart'));
        renderer.xr.addEventListener('sessionend', $bind(this, 'onSessionEnd'));

        this.dispose = $bind(this, 'dispose');
    }

    public function onSessionStart() {
        var session = renderer.xr.getSession();

        if (js.Sys.exists(session, 'requestLightProbe')) {
            session.requestLightProbe({ reflectionFormat: session.preferredReflectionFormat }).then(function(probe) {
                sessionLightProbe = new SessionLightProbe(this, renderer, probe, environmentEstimation, function() {
                    estimationStarted = true;
                    this.dispatchEvent({ type: 'estimationstart' });
                });
            });
        }
    }

    public function onSessionEnd() {
        if (sessionLightProbe != null) {
            sessionLightProbe.dispose();
            sessionLightProbe = null;
        }

        if (estimationStarted) {
            this.dispatchEvent({ type: 'estimationend' });
        }
    }

    public function dispose() {
        if (sessionLightProbe != null) {
            sessionLightProbe.dispose();
            sessionLightProbe = null;
        }

        this.remove(lightProbe);
        lightProbe = null;

        this.remove(directionalLight);
        directionalLight = null;

        environment = null;
    }
}