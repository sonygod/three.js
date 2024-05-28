package three.loaders;

import three.textures.CubeTexture;
import three.loaders.ImageLoader;
import three.loaders.Loader;
import three.constants.SRGBColorSpace;

class CubeTextureLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(urls:Array<String>, onLoad:Cubetexture->Void, onProgress:Float->Void, onError:String->Void):CubeTexture {
        var texture = new CubeTexture();
        texture.colorSpace = SRGBColorSpace;

        var loader = new ImageLoader(this.manager);
        loader.crossOrigin = this.crossOrigin;
        loader.path = this.path;

        var loaded = 0;

        function loadTexture(i:Int) {
            loader.load(urls[i], function(image:js.html.Image) {
                texture.images[i] = image;
                loaded++;

                if (loaded == 6) {
                    texture.needsUpdate = true;
                    if (onLoad != null) onLoad(texture);
                }
            }, null, onError);
        }

        for (i in 0...urls.length) {
            loadTexture(i);
        }

        return texture;
    }
}