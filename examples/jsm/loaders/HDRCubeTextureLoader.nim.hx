import three.CubeTexture;
import three.DataTexture;
import three.FileLoader;
import three.FloatType;
import three.HalfFloatType;
import three.LinearFilter;
import three.LinearSRGBColorSpace;
import three.Loader;
import three.RGBELoader;

class HDRCubeTextureLoader extends Loader {

	public var hdrLoader:RGBELoader;
	public var type:Dynamic;

	public function new(manager:Dynamic) {
		super(manager);
		this.hdrLoader = new RGBELoader();
		this.type = HalfFloatType;
	}

	public function load(urls:Array<String>, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):CubeTexture {
		var texture:CubeTexture = new CubeTexture();
		texture.type = this.type;

		switch (texture.type) {
			case FloatType:
				texture.colorSpace = LinearSRGBColorSpace;
				texture.minFilter = LinearFilter;
				texture.magFilter = LinearFilter;
				texture.generateMipmaps = false;
				break;
			case HalfFloatType:
				texture.colorSpace = LinearSRGBColorSpace;
				texture.minFilter = LinearFilter;
				texture.magFilter = LinearFilter;
				texture.generateMipmaps = false;
				break;
		}

		var loaded:Int = 0;

		function loadHDRData(i:Int, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
			var fileLoader:FileLoader = new FileLoader(this.manager);
			fileLoader.setPath(this.path);
			fileLoader.setResponseType('arraybuffer');
			fileLoader.setWithCredentials(this.withCredentials);
			fileLoader.load(urls[i], function(buffer:Dynamic) {
				loaded++;
				var texData:Dynamic = this.hdrLoader.parse(buffer);
				if (!texData) return;
				if (texData.data !== undefined) {
					var dataTexture:DataTexture = new DataTexture(texData.data, texData.width, texData.height);
					dataTexture.type = texture.type;
					dataTexture.colorSpace = texture.colorSpace;
					dataTexture.format = texture.format;
					dataTexture.minFilter = texture.minFilter;
					dataTexture.magFilter = texture.magFilter;
					dataTexture.generateMipmaps = texture.generateMipmaps;
					texture.images[i] = dataTexture;
				}
				if (loaded === 6) {
					texture.needsUpdate = true;
					if (onLoad) onLoad(texture);
				}
			}, onProgress, onError);
		}

		for (i in 0...urls.length) {
			loadHDRData(i, onLoad, onProgress, onError);
		}

		return texture;
	}

	public function setDataType(value:Dynamic):HDRCubeTextureLoader {
		this.type = value;
		this.hdrLoader.setDataType(value);
		return this;
	}
}