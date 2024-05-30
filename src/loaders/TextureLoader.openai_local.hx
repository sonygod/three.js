import three.loaders.ImageLoader;
import three.textures.Texture;
import three.loaders.Loader;

class TextureLoader extends Loader {

    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(
        url:String, 
        onLoad:Dynamic -> Void, 
        onProgress:Dynamic -> Void, 
        onError:Dynamic -> Void
    ):Texture {

        var texture = new Texture();

        var loader = new ImageLoader(this.manager);
        loader.setCrossOrigin(this.crossOrigin);
        loader.setPath(this.path);

        loader.load(url, function(image:Dynamic):Void {
            texture.image = image;
            texture.needsUpdate = true;

            if (onLoad != null) {
                onLoad(texture);
            }
        }, onProgress, onError);

        return texture;
    }
}

@:native("TextureLoader")
extern class TextureLoaderExtern extends Loader {
    public function new(manager:LoaderManager);
    public function load(
        url:String, 
        onLoad:Dynamic -> Void, 
        onProgress:Dynamic -> Void, 
        onError:Dynamic -> Void
    ):Texture;
}