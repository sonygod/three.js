import three.textures.Texture;
import three.loaders.ImageLoader;
import three.loaders.Loader;

class TextureLoader extends Loader {

    public function new(manager:Manager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Texture {
        var texture = new Texture();
        var loader = new ImageLoader(this.manager);
        loader.setCrossOrigin(this.crossOrigin);
        loader.setPath(this.path);

        loader.load(url, function(image:Image) {
            texture.image = image;
            texture.needsUpdate = true;

            if (onLoad != null) {
                onLoad(texture);
            }
        }, onProgress, onError);

        return texture;
    }
}