import three.textures.Texture;
import three.constants.ClampToEdgeWrapping;
import three.constants.NearestFilter;

class DataArrayTexture extends Texture {

    public var isDataArrayTexture:Bool;
    public var image:{data:Dynamic, width:Int, height:Int, depth:Int};
    public var layerUpdates:Set<Int>;

    public function new(data:Dynamic = null, width:Int = 1, height:Int = 1, depth:Int = 1) {

        super(null);

        this.isDataArrayTexture = true;

        this.image = { data: data, width: width, height: height, depth: depth };

        this.magFilter = NearestFilter;
        this.minFilter = NearestFilter;

        this.wrapR = ClampToEdgeWrapping;

        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;

        this.layerUpdates = new Set();

    }

    public function addLayerUpdate(layerIndex:Int):Void {
        this.layerUpdates.add(layerIndex);
    }

    public function clearLayerUpdates():Void {
        this.layerUpdates.clear();
    }

}