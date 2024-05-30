import three.textures.Texture;
import three.constants.ClampToEdgeWrapping;
import three.constants.NearestFilter;

class Data3DTexture extends Texture {

	public var isData3DTexture:Bool;
	public var image:{ data:Dynamic, width:Int, height:Int, depth:Int };
	public var magFilter:Dynamic;
	public var minFilter:Dynamic;
	public var wrapR:Dynamic;
	public var generateMipmaps:Bool;
	public var flipY:Bool;
	public var unpackAlignment:Int;

	public function new( data:Dynamic = null, width:Int = 1, height:Int = 1, depth:Int = 1 ) {
		super(null);

		this.isData3DTexture = true;

		this.image = { data: data, width: width, height: height, depth: depth };

		this.magFilter = NearestFilter;
		this.minFilter = NearestFilter;

		this.wrapR = ClampToEdgeWrapping;

		this.generateMipmaps = false;
		this.flipY = false;
		this.unpackAlignment = 1;
	}
}