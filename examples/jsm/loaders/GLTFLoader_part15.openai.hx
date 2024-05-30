package three.js.examples.jm.loaders;

class GLTFTextureBasisUExtension {
    public var parser:Dynamic;
    public var name:String = EXTENSIONS.KHR_TEXTURE_BASISU;

    public function new(parser:Dynamic) {
        this.parser = parser;
    }

    public function loadTexture(textureIndex:Int):Null_dyn {
        var parser:Dynamic = this.parser;
        var json:Dynamic = parser.json;

        var textureDef:Dynamic = json.textures[textureIndex];

        if (!(textureDef.extensions != null && textureDef.extensions.exists(this.name))) {
            return null;
        }

        var extension:Dynamic = textureDef.extensions[this.name];
        var loader:Dynamic = parser.options.ktx2Loader;

        if (loader == null) {
            if (json.extensionsRequired != null && Lambda.has(json.extensionsRequired, this.name)) {
                throw new Error('THREE.GLTFLoader: setKTX2Loader must be called before loading KTX2 textures');
            } else {
                // Assumes that the extension is optional and that a fallback texture is present
                return null;
            }
        }

        return parser.loadTextureImage(textureIndex, extension.source, loader);
    }
}