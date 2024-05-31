package ;

import three.Loaders.FileLoader;
import three.Textures.CubeTexture;
import three.Textures.DataTexture;
import three.Loaders.Loader;
import three.Constants.LinearFilter;
import three.Constants.LinearSRGBColorSpace;
import three.Constants.FloatType;
import three.Constants.HalfFloatType;
import three.Loaders.RGBELoader;

class HDRCubeTextureLoader extends Loader {

    public var hdrLoader : RGBELoader;
    public var type(default, set_type) : Int;

    public function new(manager : Dynamic = null) {
        super(manager);
        this.hdrLoader = new RGBELoader();
        this.type = HalfFloatType;
    }

    public function load(urls : Array<String>, onLoad : CubeTexture->Void, ?onProgress : Dynamic->Void, ?onError : Dynamic->Void) : CubeTexture {
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

        function loadHDRData(i : Int, onLoad : Void->Void, ?onProgress : Dynamic->Void, ?onError : Dynamic->Void) {
            new FileLoader(scope.manager)
                .setPath(scope.path)
                .setResponseType("arraybuffer")
                .setWithCredentials(scope.withCredentials)
                .load(urls[i], function(buffer : js.html.ArrayBuffer) {
                    loaded++;
                    var texData = scope.hdrLoader.parse(buffer);

                    if (texData != null && texData.data != null) {
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
            loadHDRData(i, function() {
                if (onLoad != null) onLoad(texture);
            }, onProgress, onError);
        }

        return texture;
    }

    public function setDataType(value : Int) : HDRCubeTextureLoader {
        this.type = value;
        this.hdrLoader.setDataType(value);
        return this;
    }

    function set_type(value : Int) : Int {
        this.type = value;
        return value;
    }
}