import three.math.interpolants.LinearInterpolant;
import three.math.Interpolant;

class LinearInterpolantTests {
    public static function main() {
        testExtending();
        testInstancing();
    }

    static function testExtending() {
        var object = new LinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        haxe.unit.Assert.isTrue(Std.is(object, Interpolant), 'LinearInterpolant extends from Interpolant');
    }

    static function testInstancing() {
        var object = new LinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        haxe.unit.Assert.isNotNull(object, 'Can instantiate a LinearInterpolant.');
    }
}