package three.test.unit.src.textures;

import haxe.unit.TestCase;
import three.textures.CompressedArrayTexture;
import three.textures.CompressedTexture;

class CompressedArrayTextureTests {
    public function new() {}

    public function testExtending() {
        var object = new CompressedArrayTexture();
        assertTrue(object instanceof CompressedTexture, 'CompressedArrayTexture extends from CompressedTexture');
    }

    public function testInstancing() {
        var object = new CompressedArrayTexture();
        assertNotNull(object, 'Can instantiate a CompressedArrayTexture.');
    }

    public function todoImageDepth() {
        // { width: width, height: height, depth: depth }
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoWrapR() {
        assertTrue(false, "everything's gonna be alright");
    }

    public function testIsCompressedArrayTexture() {
        var object = new CompressedArrayTexture();
        assertTrue(object.isCompressedArrayTexture, 'CompressedArrayTexture.isCompressedArrayTexture should be true');
    }
}