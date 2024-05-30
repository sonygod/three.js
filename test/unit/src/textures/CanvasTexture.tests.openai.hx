import haxe.unit.TestRunner;
import textures.CanvasTexture;
import textures.Texture;

class TexturesTest {
    public static function main() {
        var runner = new TestRunner();
        runner.addCase(new TexturesTests());
        runner.run();
    }
}

class TexturesTests {
    public function new() {}

    public function testCanvasTexture() {
        TestRunner.assertEqual(typeof(CanvasTexture) == Texture, true, "CanvasTexture extends from Texture");
    }

    public function testInstantiateCanvasTexture() {
        var object = new CanvasTexture();
        TestRunner.assertNotNull(object, "Can instantiate a CanvasTexture.");
    }

    public function testNeedsUpdate() {
        // todo: implement needsUpdate test
        TestRunner.fail("needsUpdate test is not implemented");
    }

    public function testIsCanvasTexture() {
        var object = new CanvasTexture();
        TestRunner.assertTrue(object.isCanvasTexture, "CanvasTexture.isCanvasTexture should be true");
    }
}