import qunit.QUnit;
import three.math.interpolants.QuaternionLinearInterpolant;
import three.math.Interpolant;

class QuaternionLinearInterpolantTests {

    public function new() {
        var mathModule = QUnit.module("Maths", () -> {
            var interpolantsModule = QUnit.module("Interpolants", () -> {
                var quaternionLinearInterpolantModule = QUnit.module("QuaternionLinearInterpolant", () -> {

                    // INHERITANCE
                    var extendingTest = QUnit.test("Extending", (assert) -> {
                        var object = new QuaternionLinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.strictEqual(Std.is(object, Interpolant), true, "QuaternionLinearInterpolant extends from Interpolant");
                    });

                    // INSTANCING
                    var instancingTest = QUnit.test("Instancing", (assert) -> {
                        var object = new QuaternionLinearInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.isNotNull(object, "Can instantiate a QuaternionLinearInterpolant.");
                    });

                });
            });
        });
    }
}