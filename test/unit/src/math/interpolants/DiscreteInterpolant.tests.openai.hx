package maths.interpolants;

importDismiss.import js.three.math.DiscreteInterpolant;
importDismiss.import js.three.math.Interpolant;

class DiscreteInterpolantTests {

    public function new() {}

    public static function main() {
        // MATHS
        QUnit.module("Maths", () => {

            // INTERPOLANTS
            QUnit.module("Interpolants", () => {

                // DISCRETEINTERPOLANT
                QUnit.module("DiscreteInterpolant", () => {

                    // INHERITANCE
                    QUnit.test("Extending", (assert) => {
                        var object = new DiscreteInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.ok(Std.is(object, Interpolant), "DiscreteInterpolant extends from Interpolant");
                    });

                    // INSTANCING
                    QUnit.test("Instancing", (assert) => {
                        var object = new DiscreteInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                        assert.ok(object != null, "Can instantiate a DiscreteInterpolant.");
                    });

                    // PRIVATE - TEMPLATE METHODS
                    QUnit.todo("interpolate_", (assert) => {
                        // todo: implement
                        assert.ok(false, "everything's gonna be alright");
                    });

                });
            });
        });
    }
}