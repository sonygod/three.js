import three.Texture;
import three.LinearFilter;

class StorageTexture extends Texture {

    public var image:Dynamic;

    public function new(width:Int = 1, height:Int = 1) {
        super();

        this.image = { width: width, height: height };

        this.magFilter = LinearFilter.LINEAR;
        this.minFilter = LinearFilter.LINEAR;

        this.isStorageTexture = true;
    }

}