package;

import haxe.Json;
// Import necessary types
import three.GLTFParser;
import three.textures.Texture;

class GLTFTextureBasisUExtension {

  public var parser:GLTFParser;
  public var name:String;

  public function new(parser:GLTFParser) {
    this.parser = parser;
    this.name = "KHR_TEXTURE_BASISU"; // Assuming EXTENSIONS is a constant accessible in Haxe
  }

  public function loadTexture(textureIndex:Int):Null<Texture> {
    var json = parser.json;
    var textureDef:Dynamic = json.textures[textureIndex];

    if (textureDef.extensions == null || !Reflect.hasField(textureDef.extensions, this.name)) {
      return null;
    }

    var extension = Reflect.field(textureDef.extensions, this.name);
    var loader = parser.options.ktx2Loader;

    if (loader == null) {
      if (json.extensionsRequired != null && json.extensionsRequired.indexOf(this.name) >= 0) {
        throw "THREE.GLTFLoader: setKTX2Loader must be called before loading KTX2 textures";
      } else {
        // Assumes that the extension is optional and that a fallback texture is present
        return null;
      }
    }

    return parser.loadTextureImage(textureIndex, extension.source, loader);
  }
}