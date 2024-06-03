import three.DirectionalLight;
import three.Group;
import three.LightProbe;
import three.WebGLCubeRenderTarget;
import js.Browser;

class SessionLightProbe {

    private var xrLight: XREstimatedLight;
    private var renderer: WebGLRenderer;
    private var lightProbe: LightProbe;
    private var xrWebGLBinding: Dynamic;
    private var estimationStartCallback: Void -> Void;
    private var frameCallback: js.Function;

    public function new(xrLight: XREstimatedLight, renderer: WebGLRenderer, lightProbe: LightProbe, environmentEstimation: Bool, estimationStartCallback: Void -> Void) {

        this.xrLight = xrLight;
        this.renderer = renderer;
        this.lightProbe = lightProbe;
        this.xrWebGLBinding = null;
        this.estimationStartCallback = estimationStartCallback;
        this.frameCallback = this.onXRFrame.bind(this);

        var session = renderer.xr.getSession();

        if (environmentEstimation && Browser.hasDefinition("XRWebGLBinding")) {

            var cubeRenderTarget = new WebGLCubeRenderTarget(16);
            xrLight.environment = cubeRenderTarget.texture;

            var gl = renderer.getContext();

            switch (session.preferredReflectionFormat) {

                case "srgba8":
                    gl.getExtension("EXT_sRGB");
                    break;

                case "rgba16f":
                    gl.getExtension("OES_texture_half_float");
                    break;

            }

            this.xrWebGLBinding = new js.webgl.XRWebGLBinding(session, gl);

            this.lightProbe.addEventListener("reflectionchange", () => {

                this.updateReflection();

            });

        }

        session.requestAnimationFrame(this.frameCallback);

    }

    public function updateReflection() {

        var textureProperties = this.renderer.properties.get(this.xrLight.environment);

        if (textureProperties != null) {

            var cubeMap = this.xrWebGLBinding.getReflectionCubeMap(this.lightProbe);

            if (cubeMap != null) {

                textureProperties.__webglTexture = cubeMap;

                this.xrLight.environment.needsPMREMUpdate = true;

            }

        }

    }

    public function onXRFrame(time: Float, xrFrame: Dynamic) {

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

    public var lightProbe: LightProbe;
    public var directionalLight: DirectionalLight;
    public var environment: Dynamic;

    private var sessionLightProbe: SessionLightProbe;
    private var estimationStarted: Bool;

    public function new(renderer: WebGLRenderer, environmentEstimation: Bool = true) {

        super();

        this.lightProbe = new LightProbe();
        this.lightProbe.intensity = 0;
        this.add(this.lightProbe);

        this.directionalLight = new DirectionalLight();
        this.directionalLight.intensity = 0;
        this.add(this.directionalLight);

        this.environment = null;

        renderer.xr.addEventListener("sessionstart", () => {

            var session = renderer.xr.getSession();

            if (js.Boot.hasField(session, "requestLightProbe")) {

                session.requestLightProbe({

                    reflectionFormat: session.preferredReflectionFormat

                }).then((probe) => {

                    this.sessionLightProbe = new SessionLightProbe(this, renderer, probe, environmentEstimation, () => {

                        this.estimationStarted = true;

                        this.dispatchEvent({ type: "estimationstart" });

                    });

                });

            }

        });

        renderer.xr.addEventListener("sessionend", () => {

            if (this.sessionLightProbe != null) {

                this.sessionLightProbe.dispose();
                this.sessionLightProbe = null;

            }

            if (this.estimationStarted) {

                this.dispatchEvent({ type: "estimationend" });

            }

        });

        this.dispose = () => {

            if (this.sessionLightProbe != null) {

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