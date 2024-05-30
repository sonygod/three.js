import three.loaders.ImageLoader;
import three.textures.Texture;
import three.loaders.Loader;

class TextureLoader extends Loader {

    public function new(manager:Loader.Manager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Texture {

        var texture:Texture = new Texture();

        var loader:ImageLoader = new ImageLoader(this.manager);
        loader.setCrossOrigin(this.crossOrigin);
        loader.setPath(this.path);

        loader.load(url, function(image) {
            texture.image = image;
            texture.needsUpdate = true;

            if (onLoad != null) {
                onLoad(texture);
            }
        }, onProgress, onError);

        return texture;
    }
}

export haxe.macro.Expose({
    TextureLoader: TextureLoader
});