import WebGLLights from "./WebGLLights";

class WebGLRenderState {
  public lights: WebGLLights;
  public lightsArray: Array<Dynamic>;
  public shadowsArray: Array<Dynamic>;
  public camera: Dynamic;
  public transmissionRenderTarget: Dynamic;

  public function new(extensions: Dynamic) {
    this.lights = new WebGLLights(extensions);
    this.lightsArray = new Array<Dynamic>();
    this.shadowsArray = new Array<Dynamic>();
    this.camera = null;
    this.transmissionRenderTarget = {};
  }

  public function init(camera: Dynamic) {
    this.camera = camera;
    this.lightsArray.length = 0;
    this.shadowsArray.length = 0;
  }

  public function pushLight(light: Dynamic) {
    this.lightsArray.push(light);
  }

  public function pushShadow(shadowLight: Dynamic) {
    this.shadowsArray.push(shadowLight);
  }

  public function setupLights(useLegacyLights: Bool) {
    this.lights.setup(this.lightsArray, useLegacyLights);
  }

  public function setupLightsView(camera: Dynamic) {
    this.lights.setupView(this.lightsArray, camera);
  }
}

class WebGLRenderStates {
  private renderStates: WeakMap<Dynamic, Array<WebGLRenderState>>;

  public function new(extensions: Dynamic) {
    this.renderStates = new WeakMap<Dynamic, Array<WebGLRenderState>>();
  }

  public function get(scene: Dynamic, renderCallDepth: Int = 0): WebGLRenderState {
    var renderStateArray = this.renderStates.get(scene);
    var renderState: WebGLRenderState;

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
    this.renderStates = new WeakMap<Dynamic, Array<WebGLRenderState>>();
  }
}

class WebGLRenderStates {
  private renderStates: WeakMap<Dynamic, Array<WebGLRenderState>>;

  public function new(extensions: Dynamic) {
    this.renderStates = new WeakMap<Dynamic, Array<WebGLRenderState>>();
  }

  public function get(scene: Dynamic, renderCallDepth: Int = 0): WebGLRenderState {
    var renderStateArray = this.renderStates.get(scene);
    var renderState: WebGLRenderState;

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
    this.renderStates = new WeakMap<Dynamic, Array<WebGLRenderState>>();
  }
}

export class WebGLRenderStates {
  public static function get(extensions: Dynamic): WebGLRenderStates {
    return new WebGLRenderStates(extensions);
  }
}