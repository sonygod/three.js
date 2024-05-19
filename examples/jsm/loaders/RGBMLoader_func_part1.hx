import three.textures.DataTextureLoader;
import three.textures.CubeTexture;
import three.textures.TextureFormat;
import three.textures.TextureFilter;
import three.textures.TextureType;
import three.utils.TextureUtils;

class RGBMLoader extends DataTextureLoader {

	public var type:TextureType;
	public var maxRange:Int;

	public function new(manager: flash.display.LoaderContext) {
		super(manager);
		this.type = TextureType.HalfFloatType;
		this.maxRange = 7;
	}

	public function setDataType(value:TextureType):RGBMLoader {
		this.type = value;
		return this;
	}

	public function setMaxRange(value:Int):RGBMLoader {
		this.maxRange = value;
		return this;
	}

	override public function loadCubemap(urls:Array<String>, onLoad:Array<CubeTexture>, onProgress:Function, onError:Function):CubeTexture {
		var texture:CubeTexture = new CubeTexture();
		for (i in 0...6) {
			texture.images[i] = undefined;
		}
		var loaded:Int = 0;
		var scope:RGBMLoader = this;
		function loadTexture(i:Int) {
			this.load(urls[i], function (image:flash.display.BitmapData) {
				texture.images[i] = image;
				loaded++;
				if (loaded === 6) {
					texture.needsUpdate = true;
					if (onLoad != null) onLoad(texture);
				}
			}, undefined, onError);
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

	override public function loadCubemapAsync(urls:Array<String>, onProgress:Function):Promise<CubeTexture> {
		return new Promise<CubeTexture>(function (resolve, reject) {
			this.loadCubemap(urls, resolve, onProgress, reject);
		});
	}

	override public function parse(buffer:ArrayBufferView):Dynamic {
		var img = UPNG.decode(buffer);
		var rgba = UPNG.toRGBA8(img)[0];
		var data = new Uint8Array(rgba);
		var size = img.width * img.height * 4;
		var output = ( this.type === TextureType.HalfFloatType ) ? new Uint16Array(size) : new Float32Array(size);
		// decode RGBM
		for (i in 0...data.length step 4) {
			var r = data[i + 0] / 255;
			var g = data[i + 1] / 255;
			var b = data[i + 2] / 255;
			var a = data[i + 3] / 255;
			if (this.type === TextureType.HalfFloatType) {
				output[i + 0] = TextureUtils.toHalfFloat(Math.min(r * a * this.maxRange, 65504));
				output[i + 1] = TextureUtils.toHalfFloat(Math.min(g * a * this.maxRange, 65504));
				output[i + 2] = TextureUtils.toHalfFloat(Math.min(b * a * this.maxRange, 65504));
				output[i + 3] = TextureUtils.toHalfFloat(1);
			} else {
				output[i + 0] = r * a * this.maxRange;
				output[i + 1] = g * a * this.maxRange;
				output[i + 2] = b * a * this.maxRange;
				output[i + 3] = 1;
			}
		}
		return {
			width:img.width,
			height:img.height,
			data:output,
			format:TextureFormat.RGBAFormat,
			type:this.type,
			flipY:true
		};
	}

}

// from https://github.com/photopea/UPNG.js (MIT License)

class UPNG {
	
	// Add implementation of the UPNG methods here

}