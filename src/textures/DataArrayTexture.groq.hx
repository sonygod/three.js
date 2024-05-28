package three.js.src.textures;

import three.js.src.Texture;
import three.js.src.constants.ClampToEdgeWrapping;
import three.js.src.constants.NearestFilter;

class DataArrayTexture extends Texture {
    public var isDataArrayTexture:Bool;

    public var image:{
        data:Dynamic,
        width:Int,
        height:Int,
        depth:Int
    };

    public var layerUpdates:Set<Int>;

    public function new(?data:Dynamic, width:Int = 1, height:Int = 1, depth:Int = 1) {
        super(null);

        isDataArrayTexture = true;

        image = { data: data, width: width, height: height, depth: depth };

        magFilter = NearestFilter;
        minFilter = NearestFilter;

        wrapR = ClampToEdgeWrapping;

        generateMipmaps = false;
        flipY = false;
        unpackAlignment = 1;

        layerUpdates = new Set<Int>();
    }

    public function addLayerUpdate(layerIndex:Int) {
        layerUpdates.add(layerIndex);
    }

    public function clearLayerUpdates() {
        layerUpdates.clear();
    }
}