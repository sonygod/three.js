import three.Texture;
import three.LinearFilter;

class StorageTexture extends Texture {

    public function new(width:Int = 1, height:Int = 1) {
        super();

        this.image = { width: width, height: height };

        this.magFilter = LinearFilter;
        this.minFilter = LinearFilter;

        this.isStorageTexture = true;
    }
}

export StorageTexture;