package three.textures;

import three.constants.ClampToEdgeWrapping;
import three.textures.CompressedTexture;

class CompressedArrayTexture extends CompressedTexture {

    public var isCompressedArrayTexture:Bool = true;
    public var layerUpdates:Set<Int>;

    public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, depth:Int, format:Int, type:Int) {
        super(mipmaps, width, height, format, type);
        this.image.depth = depth;
        this.wrapR = ClampToEdgeWrapping.CLAMP_TO_EDGE_WRAPPING;
        this.layerUpdates = new Set<Int>();
    }

    public function addLayerUpdates(layerIndex:Int) {
        this.layerUpdates.add(layerIndex);
    }

    public function clearLayerUpdates() {
        this.layerUpdates.clear();
    }

}