import three.constants.ClampToEdgeWrapping;
import three.textures.CompressedTexture;

class CompressedArrayTexture extends CompressedTexture {

    public function new(mipmaps:Array<any>, width:Int, height:Int, depth:Int, format:Int, type:Int) {
        super(mipmaps, width, height, format, type);

        this.isCompressedArrayTexture = true;
        this.image.depth = depth;
        this.wrapR = ClampToEdgeWrapping;

        this.layerUpdates = new haxe.ds.IntMap<Bool>();
    }

    public function addLayerUpdates(layerIndex:Int):Void {
        this.layerUpdates.set(layerIndex, true);
    }

    public function clearLayerUpdates():Void {
        this.layerUpdates = new haxe.ds.IntMap<Bool>();
    }

}