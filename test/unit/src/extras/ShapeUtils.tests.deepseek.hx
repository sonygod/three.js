// 注意：这里我们假设你已经有了一个名为ShapeUtils的类，它包含了你需要测试的方法。
// 如果没有，你需要先创建这个类。

package three.js.test.unit.src.extras;

import haxe.unit.Test;
import haxe.unit.TestCase;

class ShapeUtilsTest extends TestCase {

    public function new() {
        super();
        // 在这里添加你的测试
    }

    public static function testArea():Void {
        // 在这里编写你的测试代码
        // assert.ok( false, 'everything\'s gonna be alright' );
    }

    public static function testIsClockWise():Void {
        // 在这里编写你的测试代码
        // assert.ok( false, 'everything\'s gonna be alright' );
    }

    public static function testTriangulateShape():Void {
        // 在这里编写你的测试代码
        // assert.ok( false, 'everything\'s gonna be alright' );
    }

    static public function main() {
        var instance = new ShapeUtilsTest();
        haxe.unit.Test.runTests([instance]);
    }
}