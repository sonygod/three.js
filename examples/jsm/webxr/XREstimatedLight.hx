package three.js.examples.webxr;

import three.js.DirectionLight;
import three.js.Group;
import three.js.LightProbe;
import three.js.WebGLCubeRenderTarget;

class SessionLightProbe {
    public var xrLight:Dynamic;
    public var renderer:Dynamic;
    public var lightProbe:LightProbe;
    public var xrWebGLBinding:Dynamic;
    public var estimationStartCallback:Void->Void;
    public var frameCallback:Float->XRFrame->Void;

    public function new(xrLight:Dynamic, renderer:Dynamic, lightProbe:LightProbe, environmentEstimation:Bool, estimationStartCallback:Void->Void) {
        this.xrLight = xrLight;
        this.renderer = renderer;
        this.lightProbe = lightProbe;
        this.xrWebGLBinding = null;
        this.estimationStartCallback = estimationStartCallback;
        this.frameCallback = onXRFrame.bind(this);

        var session:Dynamic = renderer.xr.getSession();

        if (environmentEstimation && 'XRWebGLBinding' in untyped __js__('window')) {
            var cubeRenderTarget:WebGLCubeRenderTarget = new WebGLCubeRenderTarget(16);
            xrLight.environment = cubeRenderTarget.texture;

            var gl:Dynamic = renderer.getContext();

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

    public function updateReflection():Void {
        var textureProperties:Dynamic = renderer.properties.get(xrLight.environment);

        if (textureProperties) {
            var cubeMap:Dynamic = xrWebGLBinding.getReflectionCubeMap(lightProbe);

            if (cubeMap) {
                textureProperties.__webglTexture = cubeMap;
                xrLight.environment.needsPMREMUpdate = true;
            }
        }
    }

    public function onXRFrame(time:Float, xrFrame:Dynamic):Void {
        if (!xrLight) return;

        var session:Dynamic = xrFrame.session;
        session.requestAnimationFrame(frameCallback);

        var lightEstimate:Dynamic = xrFrame.getLightEstimate(lightProbe);
        if (lightEstimate) {
            xrLight.lightProbe.sh.fromArray(lightEstimate.sphericalHarmonicsCoefficients);
            xrLight.lightProbe.intensity = 1.0;

            var intensityScalar:Float = Math.max(1.0,
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

    public function dispose():Void {
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

    public function new(renderer:Dynamic, environmentEstimation:Bool = true) {
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

        renderer.xr.addEventListener('sessionstart', () => {
            var session:Dynamic = renderer.xr.getSession();

            if ('requestLightProbe' in session) {
                session.requestLightProbe({
                    reflectionFormat: session.preferredReflectionFormat
                }).then((probe:Dynamic) => {
                    sessionLightProbe = new SessionLightProbe(this, renderer, probe, environmentEstimation, () => {
                        estimationStarted = true;
                        dispatchEvent({ type: 'estimationstart' });
                    });
                });
            }
        });

        renderer.xr.addEventListener('sessionend', () => {
            if (sessionLightProbe != null) {
                sessionLightProbe.dispose();
                sessionLightProbe = null;
            }

            if (estimationStarted) {
                dispatchEvent({ type: 'estimationend' });
            }
        });

        dispose = () => {
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