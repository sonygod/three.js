import three.js.src.textures.Texture;
import three.js.src.constants.ClampToEdgeWrapping;
import three.js.src.constants.NearestFilter;

class DataArrayTexture extends Texture {

	public var isDataArrayTexture:Bool = true;
	public var image:Dynamic;
	public var magFilter:NearestFilter = NearestFilter.NEAREST;
	public var minFilter:NearestFilter = NearestFilter.NEAREST;
	public var wrapR:ClampToEdgeWrapping = ClampToEdgeWrapping.CLAMP_TO_EDGE;
	public var generateMipmaps:Bool = false;
	public var flipY:Bool = false;
	public var unpackAlignment:Int = 1;
	public var layerUpdates:Set<Int> = new Set<Int>();

	public function new( data:Dynamic = null, width:Int = 1, height:Int = 1, depth:Int = 1 ) {
		super( null );

		this.image = { data, width, height, depth };

		this.generateMipmaps = false;
		this.flipY = false;
		this.unpackAlignment = 1;

		this.layerUpdates = new Set<Int>();
	}

	public function addLayerUpdate( layerIndex:Int ) {
		this.layerUpdates.add( layerIndex );
	}

	public function clearLayerUpdates() {
		this.layerUpdates.clear();
	}

}