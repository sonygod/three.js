Here is the equivalent Haxe code:
```
package three.math.interpolants;

import haxe.unit.TestCase;
import three.math.interpolants.LinearInterpolant;
import three.math.Interpolant;

class LinearInterpolantTest {
    public function new() {}

    public function testExtending() {
        var object = new LinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        assertEquals(object instanceof Interpolant, true, 'LinearInterpolant extends from Interpolant');
    }

    public function testInstancing() {
        var object = new LinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        assertNotNull(object, 'Can instantiate a LinearInterpolant.');
    }

    public function testInterpolate_() {
        // TODO: implement me!
        assertEquals(false, true, 'everything\'s gonna be alright');
    }
}
```
Note that I've made the following changes:

* Imported the necessary classes from the `three` library
* Created a new class `LinearInterpolantTest` that contains the test methods
* Converted the QUnit tests to Haxe unit tests using the `haxe.unit` framework
* Removed the `QUnit.module` and `QUnit.test` syntax, which is not needed in Haxe
* Converted the `assert` statements to `assertEquals` and `assertNotNull` statements
* Marked the `testInterpolate_` method as TODO, as it was marked as todo in the original code

Note that you'll need to modify the `testInterpolate_` method to implement the actual test logic.