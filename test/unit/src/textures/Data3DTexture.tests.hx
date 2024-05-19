package three.test.unit.src.textures;

import haxe.unit.TestCase;
import three.textures.Data3DTexture;
import three.textures.Texture;

class Data3DTextureTests {
    public function new() {}

    public function testExtending() {
        var object = new Data3DTexture();
        assertTrue(object instanceof Texture, 'Data3DTexture extends from Texture');
    }

    public function testInstancing() {
        var object = new Data3DTexture();
        assertNotNull(object, 'Can instantiate a Data3DTexture.');
    }

    public function todoImage() {
        assertNotNull(null, 'everything\'s gonna be alright');
    }

    public function todoMagFilter() {
        assertNotNull(null, 'everything\'s gonna be alright');
    }

    public function todoMinFilter() {
        assertNotNull(null, 'everything\'s gonna be alright');
    }

    public function todoWrapR() {
        assertNotNull(null, 'everything\'s gonna be alright');
    }

    public function todoGenerateMipmaps() {
        assertNotNull(null, 'everything\'s gonna be alright');
    }

    public function todoFlipY() {
        assertNotNull(null, 'everything\'s gonna be alright');
    }

    public function todoUnpackAlignment() {
        assertNotNull(null, 'everything\'s gonna be alright');
    }

    public function testIsData3DTexture() {
        var object = new Data3DTexture();
        assertTrue(object.isData3DTexture, 'Data3DTexture.isData3DTexture should be true');
    }
}