import three.constants.LinearFilter;
import three.constants.LinearMipmapLinearFilter;
import three.constants.ClampToEdgeWrapping;
import three.loaders.FileLoader;
import three.textures.DataTexture;
import three.loaders.Loader;

class DataTextureLoader extends Loader {

    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):DataTexture {
        var scope = this;
        var texture = new DataTexture();

        var loader = new FileLoader(this.manager);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setPath(this.path);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(buffer:Dynamic) {
            var texData:Dynamic;
            
            try {
                texData = scope.parse(buffer);
            } catch (error:Dynamic) {
                if (onError != null) {
                    onError(error);
                } else {
                    trace(error);
                    return;
                }
            }

            if (texData.image != null) {
                texture.image = texData.image;
            } else if (texData.data != null) {
                texture.image.width = texData.width;
                texture.image.height = texData.height;
                texture.image.data = texData.data;
            }

            texture.wrapS = texData.wrapS != null ? texData.wrapS : ClampToEdgeWrapping;
            texture.wrapT = texData.wrapT != null ? texData.wrapT : ClampToEdgeWrapping;

            texture.magFilter = texData.magFilter != null ? texData.magFilter : LinearFilter;
            texture.minFilter = texData.minFilter != null ? texData.minFilter : LinearFilter;

            texture.anisotropy = texData.anisotropy != null ? texData.anisotropy : 1;

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

            if (onLoad != null) {
                onLoad(texture, texData);
            }

        }, onProgress, onError);

        return texture;
    }
}