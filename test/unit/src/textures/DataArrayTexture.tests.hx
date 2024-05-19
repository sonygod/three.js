package three.test.unit.src.textures;

import haxe.unit.TestCase;
import three.textures.DataArrayTexture;
import three.textures.Texture;

class DataArrayTextureTests {

    public function new() {}

    public function testExtending() {
        var object = new DataArrayTexture();
        assertEquals(true, Std.is(object, Texture), 'DataArrayTexture extends from Texture');
    }

    public function testInstancing() {
        var object = new DataArrayTexture();
        assertNotNull(object, 'Can instantiate a DataArrayTexture.');
    }

    public function todoImage() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoMagFilter() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoMinFilter() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoWrapR() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoGenerateMipmaps() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFlipY() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoUnpackAlignment() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsDataArrayTexture() {
        var object = new DataArrayTexture();
        assertTrue(object.isDataArrayTexture, 'DataArrayTexture.isDataArrayTexture should be true');
    }
}