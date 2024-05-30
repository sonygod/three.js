import haxe.unit.TestCase;

import three.textures.DepthTexture;
import three.textures.Texture;

class TestDepthTexture extends TestCase {

    public function new() {
        super();
    }

    public function testExtending() {
        var object = new DepthTexture();
        assertTrue(object instanceof Texture, 'DepthTexture extends from Texture');
    }

    public function testInstancing() {
        var object = new DepthTexture();
        assertNotNull(object, 'Can instantiate a DepthTexture.');
    }

    // TODO: Implement these tests
    public function testImage() {
        // todo: implement this test
        assertEquals(false, true, 'todo');
    }

    public function testMagFilter() {
        // todo: implement this test
        assertEquals(false, true, 'todo');
    }

    public function testMinFilter() {
        // todo: implement this test
        assertEquals(false, true, 'todo');
    }

    public function testFlipY() {
        // todo: implement this test
        assertEquals(false, true, 'todo');
    }

    public function testGenerateMipmaps() {
        // todo: implement this test
        assertEquals(false, true, 'todo');
    }

    public function testIsDepthTexture() {
        var object = new DepthTexture();
        assertTrue(object.isDepthTexture, 'DepthTexture.isDepthTexture should be true');
    }
}