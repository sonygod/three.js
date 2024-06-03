import three.constants.Wrapping;
import three.loaders.FileLoader;
import three.textures.DataTexture;
import three.loaders.Loader;

class DataTextureLoader extends Loader {
    public function new(manager:Loader.Manager) {
        super(manager);
    }

    public function load(url:String, onLoad:Null<(texture:DataTexture, texData:Dynamic)->Void>, onProgress:Null<(event:ProgressEvent)->Void>, onError:Null<(event:ErrorEvent)->Void>):DataTexture {
        var texture = new DataTexture();

        var loader = new FileLoader(this.manager);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setPath(this.path);
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, (buffer:ArrayBuffer) -> {
            var texData:Dynamic;

            try {
                texData = this.parse(buffer);
            } catch (error:Dynamic) {
                if (onError != null) {
                    onError(error);
                } else {
                    trace(error);
                    return;
                }
            }

            if (Reflect.hasField(texData, "image")) {
                texture.image = texData.image;
            } else if (Reflect.hasField(texData, "data")) {
                texture.image.width = Std.int(texData.width);
                texture.image.height = Std.int(texData.height);
                texture.image.data = texData.data;
            }

            texture.wrapS = Reflect.hasField(texData, "wrapS") ? texData.wrapS : Wrapping.ClampToEdgeWrapping;
            texture.wrapT = Reflect.hasField(texData, "wrapT") ? texData.wrapT : Wrapping.ClampToEdgeWrapping;

            texture.magFilter = Reflect.hasField(texData, "magFilter") ? texData.magFilter : Wrapping.LinearFilter;
            texture.minFilter = Reflect.hasField(texData, "minFilter") ? texData.minFilter : Wrapping.LinearFilter;

            texture.anisotropy = Reflect.hasField(texData, "anisotropy") ? texData.anisotropy : 1;

            if (Reflect.hasField(texData, "colorSpace")) {
                texture.colorSpace = texData.colorSpace;
            }

            if (Reflect.hasField(texData, "flipY")) {
                texture.flipY = texData.flipY;
            }

            if (Reflect.hasField(texData, "format")) {
                texture.format = texData.format;
            }

            if (Reflect.hasField(texData, "type")) {
                texture.type = texData.type;
            }

            if (Reflect.hasField(texData, "mipmaps")) {
                texture.mipmaps = texData.mipmaps;
                texture.minFilter = Wrapping.LinearMipmapLinearFilter;
            }

            if (Std.int(texData.mipmapCount) == 1) {
                texture.minFilter = Wrapping.LinearFilter;
            }

            if (Reflect.hasField(texData, "generateMipmaps")) {
                texture.generateMipmaps = texData.generateMipmaps;
            }

            texture.needsUpdate = true;

            if (onLoad != null) onLoad(texture, texData);
        }, onProgress, onError);

        return texture;
    }

    public function parse(buffer:ArrayBuffer):Dynamic {
        // This method should be implemented by subclasses
        return null;
    }
}