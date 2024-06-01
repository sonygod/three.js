import three.textures.Texture;
import three.constants.Wrapping;
import three.constants.Filters;

class DataArrayTexture extends Texture {

    public isDataArrayTexture:Bool = true;
    public layerUpdates:Set<Int>;

    public function new(data:Dynamic = null, width:Int = 1, height:Int = 1, depth:Int = 1) {
        super(null);

        this.image = { data: data, width: width, height: height, depth: depth };

        this.magFilter = Filters.NearestFilter;
        this.minFilter = Filters.NearestFilter;

        this.wrapR = Wrapping.ClampToEdgeWrapping;

        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;

        this.layerUpdates = new Set<Int>();
    }

    public function addLayerUpdate(layerIndex:Int):Void {
        this.layerUpdates.add(layerIndex);
    }

    public function clearLayerUpdates():Void {
        this.layerUpdates = new Set<Int>();
    }

}