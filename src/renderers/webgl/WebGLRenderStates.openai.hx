package three.renderers.webgl;

import three.lights.WebGLLights;

class WebGLRenderState {
    var lights:WebGLLights;
    var lightsArray:Array<Dynamic>;
    var shadowsArray:Array<Dynamic>;
    var state:Dynamic;

    public function new(extensions:Dynamic) {
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

    public function init(camera:Dynamic) {
        state.camera = camera;
        lightsArray.splice(0, lightsArray.length);
        shadowsArray.splice(0, shadowsArray.length);
    }

    public function pushLight(light:Dynamic) {
        lightsArray.push(light);
    }

    public function pushShadow(shadowLight:Dynamic) {
        shadowsArray.push(shadowLight);
    }

    public function setupLights(useLegacyLights:Bool) {
        lights.setup(lightsArray, useLegacyLights);
    }

    public function setupLightsView(camera:Dynamic) {
        lights.setupView(lightsArray, camera);
    }
}

class WebGLRenderStates {
    var renderStates: WeakMap<Dynamic, Array<WebGLRenderState>>;

    public function new(extensions:Dynamic) {
        renderStates = new WeakMap();
    }

    public function get(scene:Dynamic, renderCallDepth:Int = 0):WebGLRenderState {
        var renderStateArray:Array<WebGLRenderState> = renderStates.get(scene);
        var renderState:WebGLRenderState;

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
        renderStates = new WeakMap();
    }
}