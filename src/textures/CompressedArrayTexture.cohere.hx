class CompressedArrayTexture extends CompressedTexture {
	public var isCompressedArrayTexture:Bool;
	public var layerUpdates:Set<Int>;

	public function new(mipmaps:Array<CompressedMipmap>, width:Int, height:Int, depth:Int, format:Dynamic, type:Int) {
		super(mipmaps, width, height, format, type);
		isCompressedArrayTexture = true;
		image.depth = depth;
		wrapR = ClampToEdgeWrapping;
		layerUpdates = new Set<Int>();
	}

	public function addLayerUpdates(layerIndex:Int) {
		layerUpdates.add(layerIndex);
	}

	public function clearLayerUpdates() {
		layerUpdates.clear();
	}
}