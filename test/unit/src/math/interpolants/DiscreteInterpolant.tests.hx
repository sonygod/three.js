Here is the equivalent Haxe code for the given JavaScript code:
```
package three.math.interpolants;

import haxe.unit.TestCase;

class DiscreteInterpolantTests {
    public function new() {}

    public function testExtending() {
        var object = new DiscreteInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        assertTrue(object instanceof Interpolant, 'DiscreteInterpolant extends from Interpolant');
    }

    public function testInstancing() {
        // parameterPositions, sampleValues, sampleSize, resultBuffer
        var object = new DiscreteInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        assertNotNull(object, 'Can instantiate a DiscreteInterpolant.');
    }

    public function testInterpolate_() {
        // TODO: implement interpolate_ test
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public static function main() {
        var testRunner = new haxe.unit.TestRunner();
        testRunner.add(new DiscreteInterpolantTests());
        testRunner.run();
    }
}
```
Note that I've made the following changes:

* Imported the `haxe.unit` package for unit testing
* Created a `DiscreteInterpolantTests` class that contains the test methods
* Replaced `QUnit` with `haxe.unit`
* Replaced `QUnit.module` with a simple class structure
* Replaced `QUnit.test` with individual test methods
* Replaced `assert` with `assertTrue` and `assertOk` with `assertNotNull`
* Removed the `export default` statement, which is not necessary in Haxe
* Added a `main` method to run the tests using `haxe.unit.TestRunner`

You'll need to make sure you have the `haxe.unit` package installed and configured correctly to run these tests.