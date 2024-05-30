import haxe.unit.TestCase;
import three.textures.CompressedTexture;
import three.textures.Texture;

class CompressedTextureTest extends TestCase {
    public function testExtending() {
        var object = new CompressedTexture();
        assertTrue(object instanceof Texture, "CompressedTexture extends from Texture");
    }

    public function testInstancing() {
        var object = new CompressedTexture();
        assertNotNull(object, "Can instantiate a CompressedTexture.");
    }

    public function todoImage() {
        // { width: width, height: height }
        fail("everything's gonna be alright");
    }

    public function todoMipmaps() {
        fail("everything's gonna be alright");
    }

    public function todoFlipY() {
        fail("everything's gonna be alright");
    }

    public function todoGenerateMipmaps() {
        fail("everything's gonna be alright");
    }

    public function testIsCompressedTexture() {
        var object = new CompressedTexture();
        assertTrue(object.isCompressedTexture, "CompressedTexture.isCompressedTexture should be true");
    }
}