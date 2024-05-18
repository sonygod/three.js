import three.js.loaders.DataTextureLoader;
import three.js.textures.CubeTexture;
import three.js.textures.TextureFormat;
import three.js.textures.TextureFilter;
import three.js.textures.Type;
import three.js.utils.DataUtils;

class RGBMLoader extends DataTextureLoader {

	public var type:Type;
	public var maxRange:Int;

	public function new(manager: flash.display.LoaderContext = null) {
		super(manager);
		this.type = Type.HALF_FLOAT;
		this.maxRange = 7;
	}

	public function setDataType(value:Type):RGBMLoader {
		this.type = value;
		return this;
	}

	public function setMaxRange(value:Int):RGBMLoader {
		this.maxRange = value;
		return this;
	}

	public function loadCubemap(urls:Array<String>, onLoad: flash.events.EventDispatcher, onProgress: flash.events.EventDispatcher, onError: flash.events.EventDispatcher):CubeTexture {
		var texture:CubeTexture = new CubeTexture();

		for (i in 0...6) {
			texture.images[i] = null;
		}

		var loaded:Int = 0;
		var scope:RGBMLoader = this;

		function loadTexture(i:Int) {
			scope.load(urls[i], function (image:flash.display.BitmapData) {
				texture.images[i] = image;
				loaded++;

				if (loaded === 6) {
					texture.needsUpdate = true;
					if (onLoad != null) onLoad.dispatchEvent(new flash.events.Event(flash.events.Event.COMPLETE));
				}
			}, null, onError);
		}

		for (i in 0...urls.length) {
			loadTexture(i);
		}

		texture.type = this.type;
		texture.format = TextureFormat.RGBAFormat;
		texture.minFilter = TextureFilter.LinearFilter;
		texture.generateMipmaps = false;

		return texture;
	}

	public function loadCubemapAsync(urls:Array<String>, onProgress: flash.events.EventDispatcher):haxe.Promise<CubeTexture> {
		return haxe.Promise.wrap(function(resolve:Void->Void, reject:Void->Void) {
			this.loadCubemap(urls, resolve, onProgress, reject);
		});
	}

	public function parse(buffer:flash.utils.ByteArray):Dynamic {
		var img:flash.display.BitmapData = UPNG.decode(buffer);
		var rgba:Array<Int> = UPNG.toRGBA8(img)[0];

		var data:ArrayBuffer = new ArrayBuffer(rgba.length);
		var output:Uint16Array = (this.type === Type.HALF_FLOAT) ? new Uint16Array(data) : new Float32Array(data);

		// decode RGBM
		for (i in 0...rgba.length) {
			var r:Int = rgba[i + 0] / 255;
			var g:Int = rgba[i + 1] / 255;
			var b:Int = rgba[i + 2] / 255;
			var a:Int = rgba[i + 3] / 255;

			if (this.type === Type.HALF_FLOAT) {
				output[i + 0] = DataUtils.toHalfFloat(Math.min(r * a * this.maxRange, 65504));
				output[i + 1] = DataUtils.toHalfFloat(Math.min(g * a * this.maxRange, 65504));
				output[i + 2] = DataUtils.toHalfFloat(Math.min(b * a * this.maxRange, 65504));
				output[i + 3] = DataUtils.toHalfFloat(1);
			} else {
				output[i + 0] = r * a * this.maxRange;
				output[i + 1] = g * a * this.maxRange;
				output[i + 2] = b * a * this.maxRange;
				output[i + 3] = 1;
			}
		}

		return {
			width: img.width,
			height: img.height,
			data: output,
			format: TextureFormat.RGBAFormat,
			type: this.type,
			flipY: true
		};
	}
}

// from https://github.com/photopea/UPNG.js (MIT License)

class UPNG {

	public static function toRGBA8(out:Dynamic):Array<Uint8Array> {
		// ...
	}

	public static function decode(buff:flash.utils.ByteArray):Dynamic {
		// ...
	}

	private static function _decompress(out:Dynamic, dd:flash.utils.ByteArray, w:Int, h:Int):ArrayBuffer {
		// ...
	}

	private static function _inflate(data:flash.utils.ByteArray, buff:ArrayBuffer):ArrayBuffer {
		// ...
	}

	private static function inflateRaw(data:flash.utils.ByteArray, buff:ArrayBuffer):ArrayBuffer {
		// ...
	}

	private static function _IHDR(data:flash.utils.ByteArray, offset:Int, out:Dynamic):Void {
		// ...
	}

	private static function _filterZero(data:flash.utils.ByteArray, out:Dynamic, off:Int, w:Int, h:Int):flash.utils.ByteArray {
		// ...
	}

	private static function _readInterlace(data:flash.utils.ByteArray, out:Dynamic):ArrayBuffer {
		// ...
	}

	private static function _getBPP(out:Dynamic):Int {
		// ...
	}

	private static function _paeth(a:Int, b:Int, c:Int):Int {
		// ...
	}

	private static var _bin:Dynamic = {
		nextZero: function (data:flash.utils.ByteArray, p:Int):Int {
			// ...
		},
		readUshort: function (buff:flash.utils.ByteArray, p:Int):Int {
			// ...
		},
		writeUshort: function (buff:flash.utils.ByteArray, p:Int, n:Int):Void {
			// ...
		},
		readUint: function (buff:flash.utils.ByteArray, p:Int):Int {
			// ...
		},
		writeUint: function (buff:flash.utils.ByteArray, p:Int, n:Int):Void {
			// ...
		},
		readASCII: function (buff:flash.utils.ByteArray, p:Int, l:Int):String {
			// ...
		},
		writeASCII: function (data:flash.utils.ByteArray, p:Int, s:String):Void {
			// ...
		},
		readBytes: function (buff:flash.utils.ByteArray, p:Int, l:Int):Array<Int> {
			// ...
		},
		pad: function (n:Int):String {
			// ...
		},
		readUTF8: function (buff:flash.utils.ByteArray, p:Int, l:Int):String {
			// ...
		}
	};

	private static function _copyTile(sb:flash.utils.ByteArray, sw:Int, sh:Int, tb:flash.utils.ByteArray, tw:Int, th:Int, xoff:Int, yoff:Int, mode:Int):Bool {
		// ...
	}
}