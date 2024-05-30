import three.constants.ClampToEdgeWrapping;
import three.textures.CompressedTexture;

class CompressedArrayTexture extends CompressedTexture {

    public var isCompressedArrayTexture:Bool = true;
    public var image:Dynamic;
    public var wrapR:Dynamic;
    public var layerUpdates:Set<Dynamic>;

    public function new(mipmaps:Dynamic, width:Dynamic, height:Dynamic, depth:Dynamic, format:Dynamic, type:Dynamic) {
        super(mipmaps, width, height, format, type);

        this.image.depth = depth;
        this.wrapR = ClampToEdgeWrapping;

        this.layerUpdates = new Set<Dynamic>();
    }

    public function addLayerUpdates(layerIndex:Dynamic) {
        this.layerUpdates.add(layerIndex);
    }

    public function clearLayerUpdates() {
        this.layerUpdates.clear();
    }

}

export haxe.macro.ExprDef.export('CompressedArrayTexture');