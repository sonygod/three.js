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

	var hdrLoader:RGBELoader;
	var type:Int;

	public function new(manager:Loader) {
		super(manager);
		hdrLoader = new RGBELoader();
		type = HalfFloatType;
	}

	public function load(urls:Array<String>, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):CubeTexture {
		var texture = new CubeTexture();
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

		var loaded = 0;

		function loadHDRData(i:Int, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
			new FileLoader(manager)
				.setPath(path)
				.setResponseType('arraybuffer')
				.setWithCredentials(withCredentials)
				.load(urls[i], function(buffer) {
					loaded++;
					var texData = hdrLoader.parse(buffer);
					if (texData == null) return;
					if (texData.data != null) {
						var dataTexture = new DataTexture(texData.data, texData.width, texData.height);
						dataTexture.type = texture.type;
						dataTexture.colorSpace = texture.colorSpace;
						dataTexture.format = texture.format;
						dataTexture.minFilter = texture.minFilter;
						dataTexture.magFilter = texture.magFilter;
						dataTexture.generateMipmaps = texture.generateMipmaps;
						texture.images[i] = dataTexture;
					}
					if (loaded == 6) {
						texture.needsUpdate = true;
						if (onLoad != null) onLoad(texture);
					}
				}, onProgress, onError);
		}

		for (i in 0...urls.length) {
			loadHDRData(i, onLoad, onProgress, onError);
		}

		return texture;
	}

	public function setDataType(value:Int):HDRCubeTextureLoader {
		type = value;
		hdrLoader.setDataType(value);
		return this;
	}
}