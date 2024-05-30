import three.js.Lib;

class SessionLightProbe {
    public var xrLight:XREstimatedLight;
    public var renderer:three.js.Renderer;
    public var lightProbe:three.js.LightProbe;
    public var xrWebGLBinding:XRWebGLBinding;
    public var estimationStartCallback:Void->Void;
    public var frameCallback:Float->XRFrame->Void;

    public function new(xrLight:XREstimatedLight, renderer:three.js.Renderer, lightProbe:three.js.LightProbe, environmentEstimation:Bool, estimationStartCallback:Void->Void) {
        this.xrLight = xrLight;
        this.renderer = renderer;
        this.lightProbe = lightProbe;
        this.xrWebGLBinding = null;
        this.estimationStartCallback = estimationStartCallback;
        this.frameCallback = onXRFrame;

        var session:XRSession = renderer.xr.getSession();

        if (environmentEstimation && XRWebGLBinding.exists) {
            var cubeRenderTarget:WebGLCubeRenderTarget = new WebGLCubeRenderTarget(16);
            xrLight.environment = cubeRenderTarget.texture;

            var gl:WebGLRenderingContext = renderer.getContext();

            switch (session.preferredReflectionFormat) {
                case 'srgba8':
                    gl.getExtension('EXT_sRGB');
                    break;
                case 'rgba16f':
                    gl.getExtension('OES_texture_half_float');
                    break;
            }

            this.xrWebGLBinding = new XRWebGLBinding(session, gl);

            lightProbe.addEventListener('reflectionchange', updateReflection);

        }

        session.requestAnimationFrame(frameCallback);
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
        if (xrLight == null) return;

        var session:XRSession = xrFrame.session;
        session.requestAnimationFrame(frameCallback);

        var lightEstimate = xrFrame.getLightEstimate(lightProbe);
        if (lightEstimate != null) {
            xrLight.lightProbe.sh.fromArray(lightEstimate.sphericalHarmonicsCoefficients);
            xrLight.lightProbe.intensity = 1.0;

            var intensityScalar = Math.max(1.0,
                Math.max(lightEstimate.primaryLightIntensity.x,
                    Math.max(lightEstimate.primaryLightIntensity.y,
                        lightEstimate.primaryLightIntensity.z)));

            xrLight.directionalLight.color.setRGB(
                lightEstimate.primaryLightIntensity.x / intensityScalar,
                lightEstimate.primaryLightIntensity.y / intensityScalar,
                lightEstimate.primaryLightIntensity.z / intensityScalar);
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
    public var environment:Texture;

    public function new(renderer:three.js.Renderer, environmentEstimation:Bool = true) {
        super();

        lightProbe = new LightProbe();
        lightProbe.intensity = 0;
        add(lightProbe);

        directionalLight = new DirectionalLight();
        directionalLight.intensity = 0;
        add(directionalLight);

        environment = null;

        var sessionLightProbe:SessionLightProbe = null;
        var estimationStarted:Bool = false;

        renderer.xr.addEventListener('sessionstart', () -> {
            var session:XRSession = renderer.xr.getSession();

            if (Reflect.hasField(session, 'requestLightProbe')) {
                session.requestLightProbe({
                    reflectionFormat: session.preferredReflectionFormat
                }).then((probe) -> {
                    sessionLightProbe = new SessionLightProbe(this, renderer, probe, environmentEstimation, () -> {
                        estimationStarted = true;
                        dispatchEvent({type: 'estimationstart'});
                    });
                });
            }
        });

        renderer.xr.addEventListener('sessionend', () -> {
            if (sessionLightProbe != null) {
                sessionLightProbe.dispose();
                sessionLightProbe = null;
            }

            if (estimationStarted) {
                dispatchEvent({type: 'estimationend'});
            }
        });

        dispose = () -> {
            if (sessionLightProbe != null) {
                sessionLightProbe.dispose();
                sessionLightProbe = null;
            }

            remove(lightProbe);
            lightProbe = null;

            remove(directionalLight);
            directionalLight = null;

            environment = null;
        };
    }
}