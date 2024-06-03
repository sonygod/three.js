import three.textures.Texture;
import three.constants.ClampToEdgeWrapping;
import three.constants.NearestFilter;

class DataArrayTexture extends Texture
{
    public var isDataArrayTexture:Bool = true;
    public var image:Dynamic;
    public var layerUpdates:haxe.ds.IntMap<Bool>;

    public function new(data:Dynamic = null, width:Int = 1, height:Int = 1, depth:Int = 1)
    {
        super(null);

        this.image = { data: data, width: width, height: height, depth: depth };

        this.magFilter = NearestFilter;
        this.minFilter = NearestFilter;

        this.wrapR = ClampToEdgeWrapping;

        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;

        this.layerUpdates = new haxe.ds.IntMap<Bool>();
    }

    public function addLayerUpdate(layerIndex:Int):Void
    {
        this.layerUpdates.set(layerIndex, true);
    }

    public function clearLayerUpdates():Void
    {
        this.layerUpdates.clear();
    }
}