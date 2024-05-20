import three.js.src.renderers.webgl.WebGLLights;

class WebGLRenderState {

	var lights:WebGLLights;
	var lightsArray:Array<Dynamic>;
	var shadowsArray:Array<Dynamic>;
	var state:{
		lightsArray:Array<Dynamic>,
		shadowsArray:Array<Dynamic>,
		camera:Dynamic,
		lights:WebGLLights,
		transmissionRenderTarget:Dynamic
	};

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

	public function init(camera:Dynamic):Void {
		state.camera = camera;
		lightsArray.length = 0;
		shadowsArray.length = 0;
	}

	public function pushLight(light:Dynamic):Void {
		lightsArray.push(light);
	}

	public function pushShadow(shadowLight:Dynamic):Void {
		shadowsArray.push(shadowLight);
	}

	public function setupLights(useLegacyLights:Bool):Void {
		lights.setup(lightsArray, useLegacyLights);
	}

	public function setupLightsView(camera:Dynamic):Void {
		lights.setupView(lightsArray, camera);
	}
}

class WebGLRenderStates {

	var renderStates:WeakMap<Dynamic, Array<WebGLRenderState>>;

	public function new(extensions:Dynamic) {
		renderStates = new WeakMap();
	}

	public function get(scene:Dynamic, renderCallDepth:Int = 0):WebGLRenderState {
		var renderStateArray = renderStates.get(scene);
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

	public function dispose():Void {
		renderStates = new WeakMap();
	}
}