package three.test.unit.src.textures;

import haxe.unit.TestCase;
import three.textures.DataTexture;
import three.textures.Texture;

class DataTextureTests {
    public function new() {}

    public function testExtending() {
        var object = new DataTexture();
        assertTrue(object instanceof Texture, 'DataTexture extends from Texture');
    }

    public function testInstancing() {
        var object = new DataTexture();
        assertNotNull(object, 'Can instantiate a DataTexture.');
    }

    public function todoImage() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoGenerateMipmaps() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFlipY() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoUnpackAlignment() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsDataTexture() {
        var object = new DataTexture();
        assertTrue(object.isDataTexture, 'DataTexture.isDataTexture should be true');
    }
}