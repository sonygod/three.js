class GLTFTextureBasisUExtension {

    var parser:Dynamic;
    var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_TEXTURE_BASISU;
    }

    public function loadTexture(textureIndex:Int):Dynamic {
        var textureDef = this.parser.json.textures[textureIndex];

        if (!textureDef.extensions || !textureDef.extensions[this.name]) {
            return null;
        }

        var extension = textureDef.extensions[this.name];
        var loader = this.parser.options.ktx2Loader;

        if (!loader) {
            if (this.parser.json.extensionsRequired && this.parser.json.extensionsRequired.indexOf(this.name) >= 0) {
                throw 'THREE.GLTFLoader: setKTX2Loader must be called before loading KTX2 textures';
            } else {
                // Assumes that the extension is optional and that a fallback texture is present
                return null;
            }
        }

        return this.parser.loadTextureImage(textureIndex, extension.source, loader);
    }
}