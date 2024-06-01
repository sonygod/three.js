package ;

import kha.graphics4.CubeReflectionMapping;
import kha.Image;
import kha.graphics4.TextureFormat;
import kha.graphics4.TextureType;

class CompressedCubeTexture extends CompressedTexture {

	public var image(default, null) : Array<Image>;

	public function new(images : Array<Image>, format : TextureFormat, type : TextureType) {
		super(null, images[0].width, images[0].height, format, type, CubeReflectionMapping);

		this.isCompressedCubeTexture = true;
		this.isCubeTexture = true;

		this.image = images;
	}

}