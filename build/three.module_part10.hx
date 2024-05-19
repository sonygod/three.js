package three;

import haxe.ds.Set;

@:nativeGen
class DataArrayTexture extends Texture {

    public var isDataArrayTexture:Bool = true;
    public var image:{ data:Dynamic, width:Int, height:Int, depth:Int };
    public var magFilter:TextureFilter = NearestFilter;
    public var minFilter:TextureFilter = NearestFilter;
    public var wrapR:WrappingMode = ClampToEdgeWrapping;
    public var generateMipmaps:Bool = false;
    public var flipY:Bool = false;
    public var unpackAlignment:Int = 1;
    public var layerUpdates:Set<Int> = new Set<Int>();

    public function new(?data:Dynamic, width:Int = 1, height:Int = 1, depth:Int = 1) {
        super(null);
        this.image = { data: data, width: width, height: height, depth: depth };
    }

    public function addLayerUpdate(layerIndex:Int) {
        layerUpdates.add(layerIndex);
    }

    public function clearLayerUpdates() {
        layerUpdates.clear();
    }
}