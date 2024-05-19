package three.test.unit.src.textures;

import haxe.unit.TestCase;

import three.textures.CompressedTexture;
import three.textures.Texture;

class CompressedTextureTest {
    public function new() { }

    public function testExtending() {
        var object = new CompressedTexture();
        assertEquals(object instanceof Texture, true, 'CompressedTexture extends from Texture');
    }

    public function testInstancing() {
        var object = new CompressedTexture();
        assertTrue(object != null, 'Can instantiate a CompressedTexture.');
    }

    public function todoImage() {
        // { width: width, height: height }
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoMipmaps() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFlipY() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoGenerateMipmaps() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsCompressedTexture() {
        var object = new CompressedTexture();
        assertTrue(object.isCompressedTexture, 'CompressedTexture.isCompressedTexture should be true');
    }
}