package three.loaders;

import three.textures.Texture;
import three.loaders.Loader;
import three.loaders.ImageLoader;

class TextureLoader extends Loader {
    
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Texture->Void, onProgress:Float->Void, onError:String->Void):Texture {
        var texture:Texture = new Texture();

        var loader:ImageLoader = new ImageLoader(this.manager);
        loader.crossOrigin = this.crossOrigin;
        loader.path = this.path;

        loader.load(url, function(image:Any) {
            texture.image = image;
            texture.needsUpdate = true;

            if (onLoad != null) {
                onLoad(texture);
            }
        }, onProgress, onError);

        return texture;
    }
}