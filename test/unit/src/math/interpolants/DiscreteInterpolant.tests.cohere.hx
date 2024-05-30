import js.QUnit;
import js.math.interpolants.DiscreteInterpolant;
import js.math.Interpolant;

class TestDiscreteInterpolant {
    static function test() {
        var object = new DiscreteInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
        var assert = QUnit.test("Extending", function() {
            return QUnit.strictEqual(object instanceof Interpolant, true, "DiscreteInterpolant extends from Interpolant");
        });
        assert = QUnit.test("Instancing", function() {
            return QUnit.ok(object, "Can instantiate a DiscreteInterpolant.");
        });
        assert = QUnit.test("interpolate_", function() {
            return QUnit.ok(false, "everything's gonna be alright");
        });
    }
}

TestDiscreteInterpolant.test();