package three.textures;

import three.constants.CubeReflectionMapping;
import three.textures.CompressedTexture;

class CompressedCubeTexture extends CompressedTexture {

	public var isCompressedCubeTexture:Bool = true;
	public var isCubeTexture:Bool = true;

	public var image:Array<Any>; // assuming images is an array of images

	public function new(images:Array<Any>, format:Any, type:Any) {
		super(undefined, images[0].width, images[0].height, format, type, CubeReflectionMapping);
		this.image = images;
	}
}