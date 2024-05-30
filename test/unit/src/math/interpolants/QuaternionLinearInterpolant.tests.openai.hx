package three.math.interpolants;

import haxe.unit.TestCase;
import three.math.Interpolant;
import three.math.interpolants.QuaternionLinearInterpolant;

class QuaternionLinearInterpolantTests {

    public function new() {}

    public function testExtending():Void {
        var object = new QuaternionLinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        TestCase.assertEquals(Type.getInstance(object) == Interpolant, true, 'QuaternionLinearInterpolant extends from Interpolant');
    }

    public function testInstancing():Void {
        var object = new QuaternionLinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        TestCase.assertNotNull(object, 'Can instantiate a QuaternionLinearInterpolant.');
    }

    public function testInterpolate_():Void {
        // TODO: implement this test
        TestCase.fail('not implemented');
    }

    public static function main():Void {
        var runner = new haxe.unit.TestRunner();
        runner.add(new QuaternionLinearInterpolantTests());
        runner.run();
    }

}