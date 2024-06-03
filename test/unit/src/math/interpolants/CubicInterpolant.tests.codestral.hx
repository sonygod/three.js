import test.QUnit;
import three.math.interpolants.CubicInterpolant;
import three.math.Interpolant;

class CubicInterpolantTests {
    public function new() {
        QUnit.module("Maths", () -> {
            QUnit.module("Interpolants", () -> {
                QUnit.module("CubicInterpolant", () -> {
                    // INHERITANCE
                    QUnit.test("Extending", (assert) -> {
                        var object = new CubicInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.strictEqual(
                            Std.is(object, CubicInterpolant), true,
                            'CubicInterpolant extends from Interpolant'
                        );
                    });

                    // INSTANCING
                    QUnit.test("Instancing", (assert) -> {
                        var object = new CubicInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.isNotNull(object, 'Can instantiate a CubicInterpolant.');
                    });
                });
            });
        });
    }
}