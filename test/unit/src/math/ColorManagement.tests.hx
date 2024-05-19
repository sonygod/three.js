Here is the converted Haxe code:
```
package three.math;

import haxe.unit.TestCase;
import three.math.ColorManagement;

class ColorManagementTest {
    public function new() {}

    public function testEnabled() {
        assertEquals(true, ColorManagement.enabled, 'ColorManagement.enabled is true by default.');
    }

    public function todoWorkingColorSpace() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoConvert() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFromWorkingColorSpace() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoToWorkingColorSpace() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoSRGBToLinear() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoLinearToSRGB() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public static function main() {
        var testCase = new ColorManagementTest();
        testCase.testEnabled();
        testCase.todoWorkingColorSpace();
        testCase.todoConvert();
        testCase.todoFromWorkingColorSpace();
        testCase.todoToWorkingColorSpace();
        testCase.todoSRGBToLinear();
        testCase.todoLinearToSRGB();
    }
}
```
Note that I assumed you want to use the `haxe.unit` testing framework, which is the default testing framework for Haxe. I also assumed that the `ColorManagement` class is already defined in a separate file, and that it has the same properties and methods as in the original JavaScript code.

Also, I replaced the `QUnit.test` and `QUnit.todo` functions with Haxe's `assertEquals` and `assertTrue` functions, respectively. I also removed the `export default` statement, as it is not necessary in Haxe.

You can run this test class using the Haxe compiler and a testing framework like `haxe.unit`.