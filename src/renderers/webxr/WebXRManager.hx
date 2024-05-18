import haxe.ds.StringMap;
import three.cameras.ArrayCamera;
import three.core.EventDispatcher;
import three.cameras.PerspectiveCamera;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.MathUtils;
import three.webgl.WebGLAnimation;
import three.webgl.WebGLRenderTarget;
import three.webxr.WebXRController;
import three.textures.DepthTexture;
import three.constants.DepthFormat;
import three.constants.DepthStencilFormat;
import three.constants.RGBAFormat;
import three.constants.UnsignedByteType;
import three.constants.UnsignedIntType;
import three.constants.UnsignedInt248Type;
import three.webxr.WebXRDepthSensing;

class WebXRManager extends EventDispatcher {

	public var renderer:Dynamic;
	public var gl:Dynamic;

	private var _session:Dynamic;
	private var _framebufferScaleFactor:Float = 1.0;
	private var _referenceSpace:Dynamic;
	private var _referenceSpaceType:String = "local-floor";
	private var _foveation:Float = 1.0;
	private var _customReferenceSpace:Dynamic;
	private var _pose:Dynamic;
	private var _glBinding:Dynamic;
	private var _glProjLayer:Dynamic;
	private var _glBaseLayer:Dynamic;
	private var _xrFrame:Dynamic;
	private var _depthSensing:WebXRDepthSensing;
	private var _attributes:Dynamic;
	private var _initialRenderTarget:WebGLRenderTarget;
	private var _newRenderTarget:WebGLRenderTarget;
	private var _controllers:Array<WebXRController>;
	private var _controllerInputSources:Array<Dynamic>;
	private var _currentSize:Vector2;
	private var _currentPixelRatio:Float;
	private var _cameraL:PerspectiveCamera;
	private var _cameraR:PerspectiveCamera;
	private var _cameras:Array<PerspectiveCamera>;
	private var _cameraXR:ArrayCamera;
	private var _currentDepthNear:Float;
	private var _currentDepthFar:Float;
	private var _cameraAutoUpdate:Bool;
	private var _enabled:Bool;
	private var _isPresenting:Bool;

	public function new(renderer:Dynamic, gl:Dynamic) {
		super();
		this._renderer = renderer;
		this._gl = gl;
		this._controllers = [];
		this._controllerInputSources = [];
		this._currentSize = new Vector2(0, 0);
		this._cameraL = new PerspectiveCamera();
		this._cameraR = new PerspectiveCamera();
		this._cameras = [this._cameraL, this._cameraR];
		this._cameraXR = new ArrayCamera();
		this._cameraAutoUpdate = true;
		this._enabled = false;
		this._isPresenting = false;
		this._depthSensing = new WebXRDepthSensing();
		this._attributes = this._gl.getContextAttributes();
		this._currentPixelRatio = this._renderer.getPixelRatio();
	}

	// Implement the rest of the class methods and properties here, following the same structure as the JavaScript code.

}