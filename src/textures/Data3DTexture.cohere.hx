import Texture from Texture;
import { ClampToEdgeWrapping, NearestFilter } from '../constants';

class Data3DTexture extends Texture {
	public var isData3DTexture:Bool = true;
	public var image:Image3D;
	public var magFilter:Int;
	public var minFilter:Int;
	public var wrapR:Int;
	public var generateMipmaps:Bool;
	public var flipY:Bool;
	public var unpackAlignment:Int;

	public function new(data:Null<Data> = null, width:Int, height:Int, depth:Int) {
		super();
		image = { data: data, width: width, height: height, depth: depth };
		magFilter = NearestFilter;
		minFilter = NearestFilter;
		wrapR = ClampToEdgeWrapping;
		generateMipmaps = false;
		flipY = false;
		unpackAlignment = 1;
	}
}