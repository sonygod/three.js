package three.js.src.textures;

import three.js.src.constants.ClampToEdgeWrapping;
import three.js.src.textures.CompressedTexture;

class CompressedArrayTexture extends CompressedTexture {

    public var isCompressedArrayTexture:Bool = true;
    public var layerUpdates:Set<Int>;

    public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, depth:Int, format:Dynamic, type:Dynamic) {
        super(mipmaps, width, height, format, type);

        this.image.depth = depth;
        this.wrapR = ClampToEdgeWrapping.CLAMP_TO_EDGE;

        layerUpdates = new Set<Int>();
    }

    public function addLayerUpdates(layerIndex:Int):Void {
        layerUpdates.add(layerIndex);
    }

    public function clearLayerUpdates():Void {
        layerUpdates.clear();
    }
}