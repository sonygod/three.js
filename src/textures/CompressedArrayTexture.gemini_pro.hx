import haxe.ds.Set;
import three.constants.ClampToEdgeWrapping;
import three.textures.CompressedTexture;

class CompressedArrayTexture extends CompressedTexture {

	public var isCompressedArrayTexture:Bool;
	public var layerUpdates:Set<Int>;
	public var image:Dynamic; // Assuming `image` is a custom object with `depth` property

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