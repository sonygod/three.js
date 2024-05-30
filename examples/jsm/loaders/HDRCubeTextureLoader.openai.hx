package three.examples.loaders;

import three.CubeTexture;
import three.DataTexture;
import three.FileLoader;
import three.FloatType;
import three.HalfFloatType;
import three.LinearFilter;
import three.LinearSRGBColorSpace;
import three.Loader;

class HDRCubeTextureLoader extends Loader {
    var hdrLoader:RGBELoader;
    var type:HalfFloatType;

    public function new(manager:LoaderManager) {
        super(manager);
        this.hdrLoader = new RGBELoader();
        this.type = HalfFloatType;
    }

    public function load(urls:Array<String>, onLoad:CubeTexture->Void, onProgress:Float->Void, onError:String->Void):CubeTexture {
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

        var loaded:Int = 0;

        function loadHDRData(i:Int, onLoad:CubeTexture->Void, onProgress:Float->Void, onError:String->Void) {
            var loader = new FileLoader(manager);
            loader.setPath(path);
            loader.setResponseType('arraybuffer');
            loader.setWithCredentials(withCredentials);
            loader.load(urls[i], function(buffer:ArrayBuffer) {
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

    public function setDataType(value:HalfFloatType):HDRCubeTextureLoader {
        this.type = value;
        this.hdrLoader.setDataType(value);
        return this;
    }
}