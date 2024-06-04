import Texture from "./Texture";
import {ClampToEdgeWrapping, NearestFilter} from "../constants";

class Data3DTexture extends Texture {

	public var isData3DTexture:Bool = true;

	public var image: {
		data:Dynamic,
		width:Int,
		height:Int,
		depth:Int
	};

	public function new(data:Dynamic = null, width:Int = 1, height:Int = 1, depth:Int = 1) {
		super(null);

		this.image = {data:data, width:width, height:height, depth:depth};

		this.magFilter = NearestFilter;
		this.minFilter = NearestFilter;

		this.wrapR = ClampToEdgeWrapping;

		this.generateMipmaps = false;
		this.flipY = false;
		this.unpackAlignment = 1;
	}

}

export class Data3DTexture {
	static inline function create(data:Dynamic = null, width:Int = 1, height:Int = 1, depth:Int = 1) {
		return new Data3DTexture(data, width, height, depth);
	}
}