import three.textures.FramebufferTexture;
import three.textures.Texture;

class FramebufferTextureTests {
    public function testExtending() {
        var object:FramebufferTexture = new FramebufferTexture();
        // In Haxe, we can use `Std.is` function to check type
        trace(Std.is(object, Texture), 'FramebufferTexture extends from Texture');
    }

    public function testInstancing() {
        var object:FramebufferTexture = new FramebufferTexture();
        trace(object != null, 'Can instantiate a FramebufferTexture.');
    }

    public function testIsFramebufferTexture() {
        var object:FramebufferTexture = new FramebufferTexture();
        trace(object.isFramebufferTexture, 'FramebufferTexture.isFramebufferTexture should be true');
    }
}