package three;

import three.Texture;

class DataArrayTexture extends Texture {
    public var isDataArrayTexture:Bool = true;

    public var image:{
        data:Dynamic,
        width:Int,
        height:Int,
        depth:Int
    };

    public var layerUpdates:Set<Int> = new Set();

    public function new(?data:Dynamic, width:Int = 1, height:Int = 1, depth:Int = 1) {
        super(null);

        this.image = { data: data, width: width, height: height, depth: depth };

        magFilter = NearestFilter;
        minFilter = NearestFilter;

        wrapR = ClampToEdgeWrapping;

        generateMipmaps = false;
        flipY = false;
        unpackAlignment = 1;
    }

    public function addLayerUpdate(layerIndex:Int) {
        layerUpdates.add(layerIndex);
    }

    public function clearLayerUpdates() {
        layerUpdates.clear();
    }
}