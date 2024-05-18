package three.js.examples.jm.loaders;

import three js.loaders.Loader;
import three.js.textures.CubeTexture;
import three.js.textures.DataTexture;
import three.js.loaders.FileLoader;
import three.js.core.FloatType;
import three.js.core.HalfFloatType;
import three.js.core.LinearFilter;
import three.js.core.LinearSRGBColorSpace;
import three.js.loaders.RGBELoader;

class HDRCubeTextureLoader extends Loader {

    var hdrLoader:RGBELoader;
    var type:FloatType;

    public function new(manager:LoaderManager) {
        super(manager);
        this.hdrLoader = new RGBELoader();
        this.type = HalfFloatType;
    }

    public function load(urls:Array<String>, onLoad:CubeTexture->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):CubeTexture {
        var texture = new CubeTexture();
        texture.type = this.type;

        switch (texture.type) {
            case FloatType:
                texture.colorSpace = LinearSRGBColorSpace;
                texture.minFilter = LinearFilter;
                texture.magFilter = LinearFilter;
                texture.generateMipmaps = false;
            case HalfFloatType:
                texture.colorSpace = LinearSRGBColorSpace;
                texture.minFilter = LinearFilter;
                texture.magFilter = LinearFilter;
                texture.generateMipmaps = false;
        }

        var scope = this;
        var loaded = 0;

        function loadHDRData(i:Int, onLoad:CubeTexture->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
            var fileLoader = new FileLoader(scope.manager);
            fileLoader.setPath(scope.path);
            fileLoader.setResponseType('arraybuffer');
            fileLoader.setWithCredentials(scope.withCredentials);
            fileLoader.load(urls[i], function(buffer:ArrayBuffer) {
                loaded++;

                var texData = scope.hdrLoader.parse(buffer);
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

    public function setDataType(value:FloatType):HDRCubeTextureLoader {
        this.type = value;
        this.hdrLoader.setDataType(value);
        return this;
    }
}