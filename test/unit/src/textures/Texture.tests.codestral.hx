import three.js.textures.Texture;
import three.js.core.EventDispatcher;
import js.Browser.console;

class TextureTests {
    public static function main() {
        testExtending();
        testInstancing();
        testIsTexture();
        testDispose();
    }

    private static function testExtending() {
        var object:Texture = new Texture();
        console.log("Texture extends from EventDispatcher: " + (object is EventDispatcher));
    }

    private static function testInstancing() {
        var object:Texture = new Texture();
        console.log("Can instantiate a Texture: " + (object != null));
    }

    private static function testIsTexture() {
        var object:Texture = new Texture();
        console.log("Texture.isTexture should be true: " + object.isTexture);
    }

    private static function testDispose() {
        var object:Texture = new Texture();
        object.dispose();
        console.log("Dispose method called without errors");
    }
}