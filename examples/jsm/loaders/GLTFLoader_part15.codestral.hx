import three.loaders.GLTFLoader;
import three.loaders.KTX2Loader;
import three.core.GLTF;
import three.core.GLTFParser;

class GLTFTextureBasisUExtension {

    public var parser: GLTFParser;
    public var name: String = GLTF.EXTENSIONS.KHR_TEXTURE_BASISU;

    public function new(parser: GLTFParser) {
        this.parser = parser;
    }

    public function loadTexture(textureIndex: Int): Future<Texture> {

        var json = parser.json;
        var textureDef = json.textures[textureIndex];

        if (textureDef.extensions == null || textureDef.extensions.get(this.name) == null) {
            return Future.ofNullable(null);
        }

        var extension = textureDef.extensions.get(this.name);
        var loader = parser.options.ktx2Loader;

        if (loader == null) {
            if (json.extensionsRequired != null && json.extensionsRequired.indexOf(this.name) != -1) {
                throw new Error('THREE.GLTFLoader: setKTX2Loader must be called before loading KTX2 textures');
            } else {
                // Assumes that the extension is optional and that a fallback texture is present
                return Future.ofNullable(null);
            }
        }

        return parser.loadTextureImage(textureIndex, extension.source, loader);
    }
}