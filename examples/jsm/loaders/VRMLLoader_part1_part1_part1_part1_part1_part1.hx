import chevrotain.Buffer;
import chevrotain.Lexer;
import chevrotain.LexerError;
import chevrotain.Token;
import chevrotain.TokenType;
import js.html.FileLoader;
import js.html.URL;
import js.typedarrays.Float32Array;
import js.typedarrays.Uint8Array;
import js.typedarrays.Uint8ClampedArray;
import openfl.geom.Matrix3D;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Vector2;
import openfl.geom.Vector3;
import openfl.geom.Vector4;
import openfl.math.ColorMatrix;
import openfl.math.Shader;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.ByteArray;
import three.AnimationClip;
import three.AnimationMixer;
import three.AnimationObjectGroup;
import three.Box2;
import three.Box3;
import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.Cylinder2;
import three.Cylinder3;
import three.Euler;
import three.Face3;
import three.Float32BufferAttribute;
import three.FrontSide;
import three.Geometry;
import three.IndexedGeometry;
import three.Line3;
import three.LinearFilter;
import three.LogarithmicDepthBufferExponentialFog;
import three.Matrix4;
import three.Mesh;
import three.MeshBasicMaterial;
import three.MeshPhongMaterial;
import three.MeshToonMaterial;
import three.NearestFilter;
import three.Object3D;
import three.OrthographicCamera;
import three.PerspectiveCamera;
import three.Plane;
import three.Quaternion;
import three.Raycaster;
import three.RepeatWrapping;
import three.RenderTargetOptions;
import three.Scene;
import three.ShaderMaterial;
import three.Sphere2;
import three.Sphere3;
import three.SphereGeometry;
import three.SphereBufferGeometry;
import three.Sprite;
import three.Texture;
import three.TextureLoader;
import three.UniformsUtils;
import three.Vector2;
import three.Vector3;
import three.WebGLRenderer;
import three.WebGLRenderTarget;
import three.WebGLRenderTargetOptions;

class VRMLLoader extends Loader {

	public var path:String;
	public var requestHeader:Dynamic;
	public var withCredentials:Bool;
	public var manager:LoaderManager;

	public function new(manager:LoaderManager) {
		super(manager);
		this.path = "";
		this.requestHeader = {};
		this.withCredentials = false;
		this.manager = manager;
	}

	public function load(url:String, onLoad:Void -> Void, onProgress:Int -> Void, onError:Dynamic):Void {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function (text:String) {
			try {
				onLoad(scope.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:String):Dynamic {
		// ...
	}
}