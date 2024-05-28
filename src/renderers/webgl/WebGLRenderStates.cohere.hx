import js.WebGLLights;

class WebGLRenderState {
    var lights = new WebGLLights(extensions);
    var lightsArray = [];
    var shadowsArray = [];
    var state = { lightsArray: lightsArray, shadowsArray: shadowsArray, camera: null, lights: lights, transmissionRenderTarget: {} };

    public function new(extensions) {
        init(null);
    }

    public function init(camera:Camera) {
        state.camera = camera;
        lightsArray.length = 0;
        shadowsArray.length = 0;
    }

    public function pushLight(light) {
        lightsArray.push(light);
    }

    public function pushShadow(shadowLight) {
        shadowsArray.push(shadowLight);
    }

    public function setupLights(useLegacyLights:Bool) {
        lights.setup(lightsArray, useLegacyLights);
    }

    public function setupLightsView(camera:Camera) {
        lights.setupView(lightsArray, camera);
    }

    public function getState():RenderState {
        return state;
    }
}

class WebGLRenderStates {
    static var renderStates = new WeakMap();

    public static function get(scene:Dynamic, renderCallDepth:Int = 0):WebGLRenderState {
        var renderStateArray = renderStates.get(scene);
        if (renderStateArray == null) {
            var renderState = new WebGLRenderState(null);
            renderStates.set(scene, [renderState]);
            return renderState;
        } else {
            if (renderCallDepth >= renderStateArray.length) {
                var renderState = new WebGLRenderState(null);
                renderStateArray.push(renderState);
            } else {
                var renderState = renderStateArray[renderCallDepth];
            }
            return renderState;
        }
    }

    public static function dispose() {
        renderStates = new WeakMap();
    }
}