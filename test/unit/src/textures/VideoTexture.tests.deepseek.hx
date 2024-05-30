package three.js.test.unit.src.textures;

import three.js.src.textures.VideoTexture;
import three.js.src.textures.Texture;

class VideoTextureTests {
    static function main() {
        // INHERITANCE
        var videoDocumentElement = {};
        var object = new VideoTexture(videoDocumentElement);
        unittest.assert(object instanceof Texture);

        // INSTANCING
        var object = new VideoTexture(videoDocumentElement);
        unittest.assert(object != null);

        // PROPERTIES
        // TODO: minFilter
        // TODO: magFilter
        // TODO: generateMipmaps

        // PUBLIC STUFF
        unittest.assert(object.isVideoTexture);
        // TODO: clone
        // TODO: update
    }
}