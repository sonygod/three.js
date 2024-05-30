import three.js.src.cameras.ArrayCamera;
import three.js.src.core.EventDispatcher;
import three.js.src.cameras.PerspectiveCamera;
import three.js.src.math.Vector2;
import three.js.src.math.Vector3;
import three.js.src.math.Vector4;
import three.js.src.math.MathUtils;
import three.js.src.renderers.webgl.WebGLAnimation;
import three.js.src.renderers.WebGLRenderTarget;
import three.js.src.renderers.webxr.WebXRController;
import three.js.src.textures.DepthTexture;
import three.js.src.constants.DepthFormat;
import three.js.src.constants.DepthStencilFormat;
import three.js.src.constants.RGBAFormat;
import three.js.src.constants.UnsignedByteType;
import three.js.src.constants.UnsignedIntType;
import three.js.src.constants.UnsignedInt248Type;
import three.js.src.renderers.webxr.WebXRDepthSensing;

class WebXRManager extends EventDispatcher {

	public var cameraAutoUpdate:Bool;
	public var enabled:Bool;
	public var isPresenting:Bool;

	private var _currentDepthNear:Float;
	private var _currentDepthFar:Float;

	private var cameraL:PerspectiveCamera;
	private var cameraR:PerspectiveCamera;
	private var cameras:Array<PerspectiveCamera>;
	private var cameraXR:ArrayCamera;

	private var controllers:Array<WebXRController>;
	private var controllerInputSources:Array<Dynamic>;

	private var currentSize:Vector2;
	private var currentPixelRatio:Float;

	private var depthSensing:WebXRDepthSensing;
	private var attributes:Dynamic;

	private var initialRenderTarget:WebGLRenderTarget;
	private var newRenderTarget:WebGLRenderTarget;

	private var session:Dynamic;
	private var framebufferScaleFactor:Float;
	private var referenceSpace:Dynamic;
	private var referenceSpaceType:String;
	private var foveation:Float;
	private var customReferenceSpace:Dynamic;

	private var pose:Dynamic;
	private var glBinding:Dynamic;
	private var glProjLayer:Dynamic;
	private var glBaseLayer:Dynamic;
	private var xrFrame:Dynamic;

	public function new(renderer:Dynamic, gl:Dynamic) {
		super();

		cameraL = new PerspectiveCamera();
		cameraL.layers.enable(1);
		cameraL.viewport = new Vector4();

		cameraR = new PerspectiveCamera();
		cameraR.layers.enable(2);
		cameraR.viewport = new Vector4();

		cameras = [cameraL, cameraR];

		cameraXR = new ArrayCamera();
		cameraXR.layers.enable(1);
		cameraXR.layers.enable(2);

		depthSensing = new WebXRDepthSensing();
		attributes = gl.getContextAttributes();

		controllers = [];
		controllerInputSources = [];

		currentSize = new Vector2();
		currentPixelRatio = null;

		cameraAutoUpdate = true;
		enabled = false;
		isPresenting = false;

		// ...
	}

	// ...

	public function getCamera():ArrayCamera {
		return cameraXR;
	}

	public function getFoveation():Float {
		if (glProjLayer == null && glBaseLayer == null) {
			return undefined;
		}
		return foveation;
	}

	public function setFoveation(value:Float) {
		// 0 = no foveation = full resolution
		// 1 = maximum foveation = the edges render at lower resolution

		foveation = value;

		if (glProjLayer != null) {
			glProjLayer.fixedFoveation = value;
		}

		if (glBaseLayer != null && glBaseLayer.fixedFoveation != null) {
			glBaseLayer.fixedFoveation = value;
		}
	}

	public function hasDepthSensing():Bool {
		return depthSensing.texture != null;
	}

	// ...

	public function dispose() {}

}