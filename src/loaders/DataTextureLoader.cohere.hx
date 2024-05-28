import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.IBitmapDrawable;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;

class DataTextureLoader extends Loader {
	public function new(manager:BaseLoader) {
		super(manager);
	}

	public function load(url:String, onLoad:Texture -> Void, onProgress:Float -> Void, onError:Dynamic -> Void):DataTexture {
		var scope = this;
		var texture = new DataTexture();
		var loader = new FileLoader(manager);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(requestHeader);
		loader.setPath(path);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(buffer:ByteArray) {
			var texData:Dynamic;
			try {
				texData = scope.parse(buffer);
			} catch(error:Dynamic) {
				if (onError != null) {
					onError(error);
				} else {
					trace(error);
					return;
				}
			}

			if (texData.image != null) {
				texture.image = cast texData.image;
			} else if (texData.data != null) {
				texture.image = new BitmapData(texData.width, texData.height, false, 0x00000000, texData.data);
			}

			texture.wrapS = if (texData.wrapS != null) texData.wrapS else ClampToEdgeWrapping;
			texture.wrapT = if (texData.wrapT != null) texData.wrapT else ClampToEdgeWrapping;

			texture.magFilter = if (texData.magFilter != null) texData.magFilter else LinearFilter;
			texture.minFilter = if (texData.minFilter != null) texData.minFilter else LinearFilter;

			texture.anisotropy = if (texData.anisotropy != null) texData.anisotropy else 1;

			if (texData.colorSpace != null) {
				texture.colorSpace = texData.colorSpace;
			}

			if (texData.flipY != null) {
				texture.flipY = texData.flipY;
			}

			if (texData.format != null) {
				texture.format = texData.format;
			}

			if (texData.type != null) {
				texture.type = texData.type;
			}

			if (texData.mipmaps != null) {
				texture.mipmaps = texData.mipmaps;
				texture.minFilter = LinearMipmapLinearFilter; // presumably...
			}

			if (texData.mipmapCount == 1) {
				texture.minFilter = LinearFilter;
			}

			if (texData.generateMipmaps != null) {
				texture.generateMipmaps = texData.generateMipmaps;
			}

			texture.needsUpdate = true;

			if (onLoad != null) onLoad(texture);
		}, onProgress, onError);

		return texture;
	}

	public function parse(buffer:ByteArray):Dynamic {
		throw 'parse() must be implemented in derived class';
	}
}

enum ClampToEdgeWrapping { }

enum LinearFilter { }

enum LinearMipmapLinearFilter { }

class DataTexture extends Texture {
	public var anisotropy:Float;
	public var colorSpace:String;
	public var flipY:Bool;
	public var format:PixelFormat;
	public var generateMipmaps:Bool;
	public var image:IBitmapDrawable;
	public var magFilter:TextureFilter;
	public var minFilter:TextureFilter;
	public var mipmaps:Bool;
	public var mipmapCount:Int;
	public var needsUpdate:Bool;
	public var type:TextureDataType;
	public var wrapS:TextureWrapMode;
	public var wrapT:TextureWrapMode;

	public function new() {
		super();
		anisotropy = 1;
		magFilter = LinearFilter;
		minFilter = LinearFilter;
		wrapS = ClampToEdgeWrapping;
		wrapT = ClampToEdgeWrapping;
	}
}

class FileLoader extends EventDispatcher implements IEventDispatcher {
	public function new(manager:LoaderManager) {
		super();
	}

	public function load(url:String, onLoad:ByteArray -> Void, onProgress:Float -> Void, onError:Dynamic -> Void):Void {
		throw 'load() must be implemented in subclass';
	}

	public function setPath(path:String):Void;

	public function setResponseType(responseType:String):Void;

	public function setRequestHeader(requestHeader:String):Void;

	public function setWithCredentials(withCredentials:Bool):Void;
}

class Loader extends EventDispatcher implements IEventDispatcher {
	public function new(manager:LoaderManager) {
		super();
	}
}

class LoaderManager { }

enum PixelFormat { }

class Texture extends EventDispatcher implements IEventDispatcher {
	public var id:Int;
	public var uuid:String;
	public var name:String;
	public var image:IBitmapDrawable;
	public var mipmaps:Bool;
	public var wrapS:TextureWrapMode;
	public var wrapT:TextureWrapMode;
	public var magFilter:TextureFilter;
	public var minFilter:TextureFilter;
	public var format:PixelFormat;
	public var type:TextureDataType;
	public var anisotropy:Float;
	public var offset:Vector2;
	public var repeat:Vector2;
	public var center:Vector2;
	public var rotation:Float;
	public var generateMipmaps:Bool;
	public var premultiplyAlpha:Bool;
	public var flipY:Bool;
	public var unpackAlignment:Int;
	public var encoding:TextureEncoding;
	public var version:Int;
	public var needsUpdate:Bool;
	public var onUpdate:Void -> Void;
	public var userData:Dynamic;
	public var width:Float;
	public var height:Float;
	public var depth:Float;
	public var isDataTexture:Bool;
	public var isCompressedTexture:Bool;
	public var isCubeTexture:Bool;
	public var is2DArrayTexture:Bool;
	public var is3DTexture:Bool;
	public var lastUsed:Float;
	public var lastUsedTime:Float;
	public var map:TextureMap;
	public var matrixAutoUpdate:Bool;
	public var matrix:Matrix;
	public var drawWidth:Int;
	public var drawHeight:Int;
	public var frame:Int;
	public var frames:Int;
	public var time:Float;
	public var loop:Bool;
	public var playedTime:Float;
	public var offsetX:Float;
	public var offsetY:Float;
	public var shader:Shader;
	public var colorTransform:ColorTransform;
	public var rect:Rectangle;
	public var root:DisplayObject;
	public var currentFrameLabel:String;
	public var currentFrameIndex:Int;
	public var currentAnimation:String;
	public var animations:Array<String>;
	public var textureIndex:Int;
	public var numTextures:Int;
	public var textureScale:Float;
	public var baseTexture:BaseTexture;

	public function new() {
		super();
		id = 0;
		uuid = '';
		name = '';
		mipmaps = false;
		wrapS = ClampToEdgeWrapping;
		wrapT = ClampToEdgeWrapping;
		magFilter = LinearFilter;
		minFilter = LinearFilter;
		anisotropy = 1;
		format = PixelFormat.RGBA;
		type = TextureDataType.UnsignedByte;
		offset = new Vector2();
		repeat = new Vector2(1, 1);
		center = new Vector2();
		rotation = 0;
		generateMipmaps = false;
		premultiplyAlpha = false;
		flipY = false;
		unpackAlignment = 4;
		encoding = TextureEncoding.Linear;
		version = 0;
		needsUpdate = false;
		onUpdate = null;
		userData = null;
		width = 0;
		height = 0;
		depth = 0;
		isDataTexture = false;
		isCompressedTexture = false;
		isCubeTexture = false;
		is2DArrayTexture = false;
		is3DTexture = false;
		lastUsed = 0;
		lastUsedTime = 0;
		map = null;
		matrixAutoUpdate = true;
		matrix = new Matrix();
		drawWidth = 0;
		drawHeight = 0;
		frame = 0;
		frames = 0;
		time = 0;
		loop = false;
		playedTime = 0;
		offsetX = 0;
		offsetY = 0;
		shader = null;
		colorTransform = null;
		rect = new Rectangle();
		root = null;
		currentFrameLabel = '';
		currentFrameIndex = -1;
		currentAnimation = '';
		animations = [];
		textureIndex = -1;
		numTextures = 1;
		textureScale = 1;
		baseTexture = null;
	}
}

enum TextureDataType { }

enum TextureEncoding { }

enum TextureFilter { }

enum TextureWrapMode { }

class Vector2 {
	public var x:Float;
	public var y:Float;

	public function new(x:Float = 0, y:Float = 0) {
		this.x = x;
		this.y = y;
	}
}