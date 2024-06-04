import three.extras.controls.OrbitControls;
import three.core.EventDispatcher;
import three.core.Object3D;
import three.math.Vector2;
import three.core.WebGLRenderer;
import three.scenes.Scene;
import three.cameras.PerspectiveCamera;

class ElementProxyReceiver extends EventDispatcher {

	public var left:Float;
	public var top:Float;
	public var width:Float;
	public var height:Float;
	public var style:Dynamic;

	public function new() {
		super();
		style = {};
	}

	public function get clientWidth():Float {
		return width;
	}

	public function get clientHeight():Float {
		return height;
	}

	public function setPointerCapture(id:Int):Void {
		// no-op
	}

	public function releasePointerCapture(id:Int):Void {
		// no-op
	}

	public function getBoundingClientRect():Dynamic {
		return {
			left: left,
			top: top,
			width: width,
			height: height,
			right: left + width,
			bottom: top + height,
		};
	}

	public function handleEvent(data:Dynamic):Void {
		if (data.type == "size") {
			left = data.left;
			top = data.top;
			width = data.width;
			height = data.height;
			return;
		}

		data.preventDefault = function():Void {};
		data.stopPropagation = function():Void {};
		dispatchEvent(data);
	}

	public function focus():Void {
		// no-op
	}
}

class ProxyManager {

	public var targets:Map<Int, ElementProxyReceiver>;

	public function new() {
		targets = new Map();
	}

	public function makeProxy(data:Dynamic):Void {
		var id = data.id;
		var proxy = new ElementProxyReceiver();
		targets.set(id, proxy);
	}

	public function getProxy(id:Int):ElementProxyReceiver {
		return targets.get(id);
	}

	public function handleEvent(data:Dynamic):Void {
		targets.get(data.id).handleEvent(data.data);
	}
}

var proxyManager = new ProxyManager();

function start(data:Dynamic):Void {
	var proxy = proxyManager.getProxy(data.canvasId);
	proxy.ownerDocument = proxy; // HACK!
	js.Lib.global.document = {}; // HACK!
	var canvas = js.Lib.document.getElementById(data.canvas) as js.html.CanvasElement;
	var renderer = new WebGLRenderer(canvas);
	var scene = new Scene();
	var camera = new PerspectiveCamera(75, 1, 0.1, 1000);
	var controls = new OrbitControls(camera, canvas);
	controls.inputElement = proxy;
	// Add your scene setup and rendering loop here
	// ...
}

function makeProxy(data:Dynamic):Void {
	proxyManager.makeProxy(data);
}

var handlers = {
	start: start,
	makeProxy: makeProxy,
	event: proxyManager.handleEvent,
};

js.Lib.global.onmessage = function(e:js.html.MessageEvent) {
	var fn = handlers[e.data.type];
	if (fn != null) {
		fn(e.data);
	} else {
		throw new Error("no handler for type: " + e.data.type);
	}
};