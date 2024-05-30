import three.constants.ClampToEdgeWrapping;
import three.textures.CompressedTexture;

class CompressedArrayTexture extends CompressedTexture {

    public var isCompressedArrayTexture:Bool;
    public var wrapR:Int;
    public var layerUpdates:Set<Int>;

    public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, depth:Int, format:Int, type:Int) {
        super(mipmaps, width, height, format, type);
        this.isCompressedArrayTexture = true;
        this.image.depth = depth;
        this.wrapR = ClampToEdgeWrapping;

        this.layerUpdates = new Set<Int>();
    }

    public function addLayerUpdates(layerIndex:Int):Void {
        this.layerUpdates.add(layerIndex);
    }

    public function clearLayerUpdates():Void {
        this.layerUpdates.clear();
    }

}