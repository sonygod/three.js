package three.js.src.loaders;

import three.js.src.loaders.ImageLoader;
import three.js.src.textures.CubeTexture;
import three.js.src.Loader;
import three.js.src.constants.SRGBColorSpace;

class CubeTextureLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(urls:Array<String>, onLoad:CubeTexture->Void, onProgress:Float->Void, onError:String->Void):CubeTexture {
        var texture = new CubeTexture();
        texture.colorSpace = SRGBColorSpace;

        var loader = new ImageLoader(this.manager);
        loader.crossOrigin = this.crossOrigin;
        loader.path = this.path;

        var loaded:Int = 0;

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