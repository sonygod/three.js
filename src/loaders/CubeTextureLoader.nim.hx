import three.loaders.ImageLoader;
import three.textures.CubeTexture;
import three.loaders.Loader;
import three.constants.SRGBColorSpace;

class CubeTextureLoader extends Loader {

    public function new(manager:Loader.Manager) {
        super(manager);
    }

    public function load(urls:Array<String>, onLoad:Null<Dynamic>, onProgress:Null<Dynamic>, onError:Null<Dynamic>):CubeTexture {
        var texture:CubeTexture = new CubeTexture();
        texture.colorSpace = SRGBColorSpace;

        var loader:ImageLoader = new ImageLoader(this.manager);
        loader.setCrossOrigin(this.crossOrigin);
        loader.setPath(this.path);

        var loaded:Int = 0;

        function loadTexture(i:Int) {
            loader.load(urls[i], function(image:Dynamic) {
                texture.images[i] = image;
                loaded++;
                if (loaded === 6) {
                    texture.needsUpdate = true;
                    if (onLoad != null) onLoad(texture);
                }
            }, onProgress, onError);
        }

        for (i in 0...urls.length) {
            loadTexture(i);
        }

        return texture;
    }

}

export haxe.macro.Expose(CubeTextureLoader);