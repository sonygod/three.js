import three.js.src.textures.Texture;
import three.js.src.constants.ClampToEdgeWrapping;
import three.js.src.constants.NearestFilter;

class DataArrayTexture extends Texture {

	public function new(data:Null<Dynamic> = null, width:Int = 1, height:Int = 1, depth:Int = 1) {
		super(null);

		this.isDataArrayTexture = true;

		this.image = { data: data, width: width, height: height, depth: depth };

		this.magFilter = NearestFilter;
		this.minFilter = NearestFilter;

		this.wrapR = ClampToEdgeWrapping;

		this.generateMipmaps = false;
		this.flipY = false;
		this.unpackAlignment = 1;

		this.layerUpdates = new Set();
	}

	public function addLayerUpdate(layerIndex:Int):Void {
		this.layerUpdates.add(layerIndex);
	}

	public function clearLayerUpdates():Void {
		this.layerUpdates.clear();
	}
}