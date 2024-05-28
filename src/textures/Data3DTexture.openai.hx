package three.js.src.textures;

import three.js.src.Texture;
import three.js.src.constants.ClampToEdgeWrapping;
import three.js.src.constants.NearestFilter;

class Data3DTexture extends Texture {
	
	public var isData3DTexture:Bool = true;
	
	public function new(?data:Array<Float>, width:Int = 1, height:Int = 1, depth:Int = 1) {
		super(null);
		
		this.image = { data: data, width: width, height: height, depth: depth };
		
		magFilter = NearestFilter.NEAREST;
		minFilter = NearestFilter.NEAREST;
		
		wrapR = ClampToEdgeWrapping.CLAMP_TO_EDGE;
		
		generateMipmaps = false;
		flipY = false;
		unpackAlignment = 1;
	}
}