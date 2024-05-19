package three.test.unit.src.textures;

import haxe.unit.TestCase;
import three.textures.CanvasTexture;
import three.textures.Texture;

class CanvasTextureTests {
    public function new() {}

    public function testExtending():Void {
        var object:CanvasTexture = new CanvasTexture();
        assertTrue(object instanceof Texture, 'CanvasTexture extends from Texture');
    }

    public function testInstancing():Void {
        var object:CanvasTexture = new CanvasTexture();
        assertNotNull(object, 'Can instantiate a CanvasTexture.');
    }

    public function testNeedsUpdate():Void {
        // todo: implement me!
        assertTrue(false, 'needsUpdate: everything\'s gonna be alright');
    }

    public function testIsCanvasTexture():Void {
        var object:CanvasTexture = new CanvasTexture();
        assertTrue(object.isCanvasTexture, 'CanvasTexture.isCanvasTexture should be true');
    }
}