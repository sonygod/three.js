import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import three.extras.ImageUtils;

class ImageUtilsTest {

    public function new() {}

    public function testGetDataURL():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testSrgbToLinear():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public static function main():Void {
        var runner = new TestRunner();
        runner.add(new ImageUtilsTest());
        runner.run();
    }
}