class StorageTexture extends Texture {
    public var isStorageTexture:Bool = true;
    public function new(width:Int = 1, height:Int = 1) {
        super();
        this.image = { width: width, height: height };
        this.magFilter = LinearFilter;
        this.minFilter = LinearFilter;
    }
}