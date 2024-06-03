import js.Browser.document;
import js.html.QUnit;
import three.math.Interpolant;
import three.math.interpolants.DiscreteInterpolant;

QUnit.module("Maths", function() {
    QUnit.module("Interpolants", function() {
        QUnit.module("DiscreteInterpolant", function() {

            // INHERITANCE
            QUnit.test("Extending", function(assert:QUnit.Assert) {
                var object:DiscreteInterpolant = new DiscreteInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                assert.strictEqual(Std.is(object, Interpolant), true, "DiscreteInterpolant extends from Interpolant");
            });

            // INSTANCING
            QUnit.test("Instancing", function(assert:QUnit.Assert) {
                var object:DiscreteInterpolant = new DiscreteInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
                assert.ok(object != null, "Can instantiate a DiscreteInterpolant.");
            });

            // PRIVATE - TEMPLATE METHODS
            QUnit.todo("interpolate_", function(assert:QUnit.Assert) {
                assert.ok(false, "everything's gonna be alright");
            });
        });
    });
});