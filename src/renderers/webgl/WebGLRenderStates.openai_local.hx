import three.renderers.webgl.WebGLLights;

class WebGLRenderState {
    public var lights:WebGLLights;
    public var lightsArray:Array<Dynamic>;
    public var shadowsArray:Array<Dynamic>;
    public var state:Dynamic;

    public function new(extensions:Dynamic) {
        this.lights = new WebGLLights(extensions);
        this.lightsArray = [];
        this.shadowsArray = [];

        this.state = {
            lightsArray: this.lightsArray,
            shadowsArray: this.shadowsArray,
            camera: null,
            lights: this.lights,
            transmissionRenderTarget: {}
        };
    }

    public function init(camera:Dynamic):Void {
        this.state.camera = camera;
        this.lightsArray = [];
        this.shadowsArray = [];
    }

    public function pushLight(light:Dynamic):Void {
        this.lightsArray.push(light);
    }

    public function pushShadow(shadowLight:Dynamic):Void {
        this.shadowsArray.push(shadowLight);
    }

    public function setupLights(useLegacyLights:Bool):Void {
        this.lights.setup(this.lightsArray, useLegacyLights);
    }

    public function setupLightsView(camera:Dynamic):Void {
        this.lights.setupView(this.lightsArray, camera);
    }
}

class WebGLRenderStates {
    var renderStates:haxe.ds.WeakMap<Dynamic, Array<WebGLRenderState>>;

    public function new(extensions:Dynamic) {
        this.renderStates = new haxe.ds.WeakMap();
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

    public function dispose():Void {
        this.renderStates = new haxe.ds.WeakMap();
    }
}

@:expose("WebGLRenderStates")
class WebGLRenderStatesExport {
    public static function create(extensions:Dynamic):WebGLRenderStates {
        return new WebGLRenderStates(extensions);
    }
}