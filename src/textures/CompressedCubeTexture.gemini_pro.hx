import compressedTexture.CompressedTexture;
import three.constants.CubeReflectionMapping;

class CompressedCubeTexture extends CompressedTexture {

	public var isCompressedCubeTexture:Bool;
	public var isCubeTexture:Bool;

	public var image:Array<Dynamic>;

	public function new(images:Array<Dynamic>, format:Dynamic, type:Dynamic) {
		super(null, images[0].width, images[0].height, format, type, CubeReflectionMapping);

		this.isCompressedCubeTexture = true;
		this.isCubeTexture = true;

		this.image = images;
	}
}