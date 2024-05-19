package three.js.examples.jm.loaders;

class GLTFTextureBasisUExtension {
    public var parser:Dynamic;
    public var name:String;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.KHR_TEXTURE_BASISU;
    }

    public function loadTexture(textureIndex:Int):Null<Texture> {
        var parser:Dynamic = this.parser;
        var json:Dynamic = parser.json;

        var textureDef:Dynamic = json.textures[textureIndex];

        if (textureDef.extensions == null || textureDef.extensions[this.name] == null) {
            return null;
        }

        var extension:Dynamic = textureDef.extensions[this.name];
        var loader:Dynamic = parser.options.ktx2Loader;

        if (loader == null) {
            if (json.extensionsRequired != null && json.extensionsRequired.indexOf(this.name) >= 0) {
                throw new Error('THREE.GLTFLoader: setKTX2Loader must be called before loading KTX2 textures');
            } else {
                // Assumes that the extension is optional and that a fallback texture is present
                return null;
            }
        }

        return parser.loadTextureImage(textureIndex, extension.source, loader);
    }
}