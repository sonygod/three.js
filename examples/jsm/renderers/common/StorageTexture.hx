package three.js.examples.jm.renderers.common;

import three.Texture;
import three.filters.LinearFilter;

class StorageTexture extends Texture {

    public function new(?width:Int = 1, ?height:Int = 1) {
        super();

        this.image = { width: width, height: height };

        this.magFilter = LinearFilter;
        this.minFilter = LinearFilter;

        this.isStorageTexture = true;
    }

}

// Export the class as the default export
@:keep
@:expose("default")
class _Default {
    public static function getDefault():Class<Dynamic> {
        return StorageTexture;
    }
}