import three.ImageLoader;
import three.textures.CubeTexture;
import three.Loader;
import three.constants.SRGBColorSpace;

class CubeTextureLoader extends Loader {

    public function new(manager:Loader.Manager) {
        super(manager);
    }

    public function load(urls:Array<String>, onLoad:Null<(texture:CubeTexture) -> Void>, onProgress:Null<(event:ProgressEvent) -> Void>, onError:Null<(event:ErrorEvent) -> Void>):CubeTexture {
        var texture = new CubeTexture();
        texture.colorSpace = SRGBColorSpace;

        var loader = new ImageLoader(this.manager);
        loader.setCrossOrigin(this.crossOrigin);
        loader.setPath(this.path);

        var loaded = 0;

        var loadTexture = function(i:Int) {
            loader.load(urls[i], function(image) {
                texture.images[i] = image;
                loaded++;

                if (loaded === 6) {
                    texture.needsUpdate = true;

                    if (onLoad != null) onLoad(texture);
                }
            }, null, onError);
        };

        for (var i = 0; i < urls.length; ++i) {
            loadTexture(i);
        }

        return texture;
    }
}