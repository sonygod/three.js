import h3d.CubeTexture;
import h3d.DataTexture;
import h3d.FileLoader;
import h3d.FloatType;
import h3d.HalfFloatType;
import h3d.LinearFilter;
import h3d.LinearSRGBColorSpace;
import h3d.Loader;
import h3d.RGBELoader;

class HDRCubeTextureLoader extends Loader {
    public var hdrLoader:RGBELoader;
    public var type:Int;

    public function new(manager:Loader) {
        super(manager);
        hdrLoader = new RGBELoader();
        type = HalfFloatType;
    }

    public function load(urls:Array<String>, onLoad:CubeTexture->Void, onProgress:Float->Void, onError:Dynamic->Void):CubeTexture {
        var texture = new CubeTexture();
        texture.type = type;

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

        var scope = this;
        var loaded = 0;

        function loadHDRData(i:Int, onLoad:Void->Void, onProgress:Float->Void, onError:Dynamic->Void) {
            var fileLoader = new FileLoader(scope.manager);
            fileLoader.path = scope.path;
            fileLoader.responseType = 'arraybuffer';
            fileLoader.withCredentials = scope.withCredentials;
            fileLoader.load(urls[i], function(buffer) {
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

    public function setDataType(value:Int):HDRCubeTextureLoader {
        type = value;
        hdrLoader.dataType = value;
        return this;
    }
}

class Export {
    public static function get HDRCubeTextureLoader() : HDRCubeTextureLoader;
}