class GLTFTextureBasisUExtension {
    public var parser: Parser;
    public var name: String = EXTENSIONS.KHR_TEXTURE_BASISU;

    public function new(parser: Parser) {
        this.parser = parser;
    }

    public function loadTexture(textureIndex: Int): Texture? {
        var parser = this.parser;
        var json = parser.json;

        var textureDef = json.textures[textureIndex];

        if (textureDef.extensions == null || textureDef.extensions.__get(this.name) == null) {
            return null;
        }

        var extension = cast textureDef.extensions.__get(this.name), GLTFTextureBasisUExtension;
        var loader = parser.options.ktx2Loader;

        if (loader == null) {
            if (json.extensionsRequired != null && json.extensionsRequired.indexOf(this.name) >= 0) {
                throw $error('THREE.GLTFLoader: setKTX2Loader must be called before loading KTX2 textures');
            } else {
                // Assumes that the extension is optional and that a fallback texture is present
                return null;
            }
        }

        return parser.loadTextureImage(textureIndex, extension.source, loader);
    }
}