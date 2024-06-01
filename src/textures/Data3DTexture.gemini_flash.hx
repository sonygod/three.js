package;

import haxe.io.Float32Array;

import Constants from "../Constants";

class Data3DTexture extends Texture {

    public var isData3DTexture:Bool = true;
    public var image(default, null):{ data:Float32Array, width:Int, height:Int, depth:Int };

    public function new(data:Float32Array = null, width:Int = 1, height:Int = 1, depth:Int = 1) {
        // We're going to add .setXXX() methods for setting properties later.
        // Users can still set in DataTexture3D directly.
        //
        //  const texture = new THREE.DataTexture3D( data, width, height, depth );
        //  texture.anisotropy = 16;
        //
        // See #14839

        super(null);

        this.image = { data: data, width: width, height: height, depth: depth };

        this.magFilter = Constants.NEAREST_FILTER;
        this.minFilter = Constants.NEAREST_FILTER;

        this.wrapR = Constants.CLAMP_TO_EDGE_WRAPPING;

        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;
    }

}