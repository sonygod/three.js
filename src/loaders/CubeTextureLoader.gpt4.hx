import three.loaders.ImageLoader;
import three.textures.CubeTexture;
import three.loaders.Loader;
import three.constants.SRGBColorSpace;

class CubeTextureLoader extends Loader {

    public function new( manager:Dynamic ) {
        super( manager );
    }

    public function load( urls:Array<String>, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic ):CubeTexture {
        var texture = new CubeTexture();
        texture.colorSpace = SRGBColorSpace;

        var loader = new ImageLoader( this.manager );
        loader.setCrossOrigin( this.crossOrigin );
        loader.setPath( this.path );

        var loaded = 0;

        function loadTexture( i:Int ):Void {
            loader.load( urls[i], function ( image:Dynamic ):Void {
                texture.images[i] = image;
                loaded++;
                if ( loaded == 6 ) {
                    texture.needsUpdate = true;
                    if ( onLoad != null ) onLoad( texture );
                }
            }, null, onError );
        }

        for ( i in 0...urls.length ) {
            loadTexture( i );
        }

        return texture;
    }

}