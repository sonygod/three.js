import js.Browser.WeakMap;
import threejs.renderers.webgl.WebGLLights;

class WebGLRenderState {
    var lights: WebGLLights;
    var lightsArray: Array<Dynamic>;
    var shadowsArray: Array<Dynamic>;
    var state: Dynamic;

    public function new(extensions: Dynamic) {
        lights = new WebGLLights(extensions);
        lightsArray = [];
        shadowsArray = [];
        state = {
            lightsArray: lightsArray,
            shadowsArray: shadowsArray,
            camera: null,
            lights: lights,
            transmissionRenderTarget: {}
        };
    }

    public function init(camera: Dynamic) {
        state.camera = camera;
        lightsArray = [];
        shadowsArray = [];
    }

    public function pushLight(light: Dynamic) {
        lightsArray.push(light);
    }

    public function pushShadow(shadowLight: Dynamic) {
        shadowsArray.push(shadowLight);
    }

    public function setupLights(useLegacyLights: Bool) {
        lights.setup(lightsArray, useLegacyLights);
    }

    public function setupLightsView(camera: Dynamic) {
        lights.setupView(lightsArray, camera);
    }
}

class WebGLRenderStates {
    var renderStates: WeakMap<Dynamic, Array<WebGLRenderState>>;

    public function new(extensions: Dynamic) {
        renderStates = new WeakMap<Dynamic, Array<WebGLRenderState>>();
    }

    public function get(scene: Dynamic, renderCallDepth: Int = 0): WebGLRenderState {
        var renderStateArray = renderStates.get(scene);
        var renderState: WebGLRenderState;

        if (renderStateArray == null) {
            renderState = new WebGLRenderState(extensions);
            renderStates.set(scene, [renderState]);
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
        renderStates = new WeakMap<Dynamic, Array<WebGLRenderState>>();
    }
}