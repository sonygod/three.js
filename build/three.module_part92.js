class CompressedCubeTexture extends CompressedTexture {

	constructor( images, format, type ) {

		super( undefined, images[ 0 ].width, images[ 0 ].height, format, type, CubeReflectionMapping );

		this.isCompressedCubeTexture = true;
		this.isCubeTexture = true;

		this.image = images;

	}

}