import three.CubeTexture;
import three.DataTexture;
import three.FileLoader;
import three.TextureDataType;
import three.TextureFilter;
import three.TextureColorSpace;
import three.Loader;
import three.loaders.RGBELoader;

class HDRCubeTextureLoader extends Loader {
    var hdrLoader: RGBELoader;
    var type: TextureDataType;

    public function new(manager?: three.LoadingManager) {
        super(manager);

        hdrLoader = new RGBELoader();
        type = TextureDataType.HalfFloatType;
    }

    public function load(urls: Array<String>, onLoad: Function, onProgress: Function, onError: Function): CubeTexture {
        var texture = new CubeTexture();

        texture.type = type;

        switch (texture.type) {
            case TextureDataType.FloatType:
                texture.colorSpace = TextureColorSpace.LinearSRGBColorSpace;
                texture.minFilter = TextureFilter.LinearFilter;
                texture.magFilter = TextureFilter.LinearFilter;
                texture.generateMipmaps = false;
                break;

            case TextureDataType.HalfFloatType:
                texture.colorSpace = TextureColorSpace.LinearSRGBColorSpace;
                texture.minFilter = TextureFilter.LinearFilter;
                texture.magFilter = TextureFilter.LinearFilter;
                texture.generateMipmaps = false;
                break;
        }

        var loaded = 0;

        var loadHDRData = function(i: Int) {
            var fileLoader = new FileLoader(manager);
            fileLoader.setPath(path);
            fileLoader.setResponseType('arraybuffer');
            fileLoader.setWithCredentials(withCredentials);
            fileLoader.load(urls[i], function(buffer: ArrayBuffer) {
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
            loadHDRData(i);
        }

        return texture;
    }

    public function setDataType(value: TextureDataType): HDRCubeTextureLoader {
        type = value;
        hdrLoader.setDataType(value);

        return this;
    }
}