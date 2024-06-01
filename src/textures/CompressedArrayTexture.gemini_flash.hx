import three.textures.CompressedTexture;
import three.constants.Wrapping;

class CompressedArrayTexture extends CompressedTexture {

	public var isCompressedArrayTexture:Bool;
	public var layerUpdates:Set<Int>;

	public function new(mipmaps:Dynamic, width:Int, height:Int, depth:Int, format:Int, type:Int) {

		super(mipmaps, width, height, format, type);

		this.isCompressedArrayTexture = true;
		cast(this.image, Dynamic).depth = depth;
		this.wrapR = Wrapping.ClampToEdgeWrapping;

		this.layerUpdates = new Set<Int>();

	}

	public function addLayerUpdates(layerIndex:Int):Void {

		this.layerUpdates.add(layerIndex);

	}

	public function clearLayerUpdates():Void {

		this.layerUpdates.clear();

	}

}