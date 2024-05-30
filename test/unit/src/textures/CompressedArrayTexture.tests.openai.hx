import haxe.unit.TestCase;
import three.textures.CompressedArrayTexture;
import three.textures.CompressedTexture;

class CompressedArrayTextureTests extends TestCase {
    public function testExtending() {
        var object = new CompressedArrayTexture();
        assertTrue(object instanceof CompressedTexture, 'CompressedArrayTexture extends from CompressedTexture');
    }

    public function testInstancing() {
        var object = new CompressedArrayTexture();
        assertNotNull(object, 'Can instantiate a CompressedArrayTexture.');
    }

    public function testImageDepth() {
        // TODO: implement this test
        assertTrue(false, "everything's gonna be alright");
    }

    public function testWrapR() {
        // TODO: implement this test
        assertTrue(false, "everything's gonna be alright");
    }

    public function testIsCompressedArrayTexture() {
        var object = new CompressedArrayTexture();
        assertTrue(object.isCompressedArrayTexture, 'CompressedArrayTexture.isCompressedArrayTexture should be true');
    }
}