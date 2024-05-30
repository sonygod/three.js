package three.test.unit.src.textures;

import three.textures.VideoTexture;
import three.textures.Texture;

class VideoTextureTests {

    public function new() {}

    public function testVideoTexture() {
        // INHERITANCE
        utensil.assert(Std.is(new VideoTexture({}), Texture), "VideoTexture extends from Texture");

        // INSTANCING
        utensil.assert(new VideoTexture({}) != null, "Can instantiate a VideoTexture.");

        // PROPERTIES
        utensil.todo("minFilter", "everything's gonna be alright");
        utensil.todo("magFilter", "everything's gonna be alright");
        utensil.todo("generateMipmaps", "everything's gonna be alright");

        // PUBLIC STUFF
        {
            var object = new VideoTexture({});
            utensil.assert(object.isVideoTexture, "VideoTexture.isVideoTexture should be true");
        }

        utensil.todo("clone", "everything's gonna be alright");
        utensil.todo("update", "everything's gonna be alright");
    }
}