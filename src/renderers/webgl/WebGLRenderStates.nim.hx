import WebGLLights.WebGLLights;

class WebGLRenderState {
    var lights:WebGLLights;
    var lightsArray:Array<Dynamic>;
    var shadowsArray:Array<Dynamic>;

    public function new(extensions:Dynamic) {
        this.lights = new WebGLLights(extensions);
        this.lightsArray = [];
        this.shadowsArray = [];
    }

    public function init(camera:Dynamic) {
        this.state.camera = camera;
        this.lightsArray.length = 0;
        this.shadowsArray.length = 0;
    }

    public function pushLight(light:Dynamic) {
        this.lightsArray.push(light);
    }

    public function pushShadow(shadowLight:Dynamic) {
        this.shadowsArray.push(shadowLight);
    }

    public function setupLights(useLegacyLights:Bool) {
        this.lights.setup(this.lightsArray, useLegacyLights);
    }

    public function setupLightsView(camera:Dynamic) {
        this.lights.setupView(this.lightsArray, camera);
    }

    public var state:Dynamic = {
        lightsArray: this.lightsArray,
        shadowsArray: this.shadowsArray,
        camera: null,
        lights: this.lights,
        transmissionRenderTarget: {}
    };
}

class WebGLRenderStates {
    var renderStates:Map<Dynamic, Array<WebGLRenderState>>;

    public function new(extensions:Dynamic) {
        this.renderStates = new Map<Dynamic, Array<WebGLRenderState>>();
    }

    public function get(scene:Dynamic, renderCallDepth:Int = 0):WebGLRenderState {
        var renderStateArray = this.renderStates.get(scene);
        var renderState:WebGLRenderState;

        if (renderStateArray == null) {
            renderState = new WebGLRenderState(extensions);
            this.renderStates.set(scene, [renderState]);
        } else {
            if (renderCallDepth >= renderStateArray.length) {
                renderState = new WebGLRenderState(extensions);
                renderStateArray.push(renderState);
            } else {
                renderState = renderStateArray[renderCallDepth];
            }
        }

        return renderState;
    }

    public function dispose() {
        this.renderStates = new Map<Dynamic, Array<WebGLRenderState>>();
    }
}