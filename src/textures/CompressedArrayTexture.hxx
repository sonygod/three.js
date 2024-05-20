import three.js.src.constants.ClampToEdgeWrapping;
import three.js.src.textures.CompressedTexture.CompressedTexture;

class CompressedArrayTexture extends CompressedTexture {

	public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, depth:Int, format:Int, type:Int) {
		super(mipmaps, width, height, format, type);

		this.isCompressedArrayTexture = true;
		this.image.depth = depth;
		this.wrapR = ClampToEdgeWrapping;

		this.layerUpdates = new Set();
	}

	public function addLayerUpdates(layerIndex:Int):Void {
		this.layerUpdates.add(layerIndex);
	}

	public function clearLayerUpdates():Void {
		this.layerUpdates.clear();
	}

}

typedef CompressedArrayTextureType = CompressedArrayTexture;