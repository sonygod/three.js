import qunit.QUnit;
import three.math.SphericalHarmonics3;

class SphericalHarmonics3Test {
    public static function main() {
        QUnit.module("Maths", function() {
            QUnit.module("SphericalHarmonics3", function() {
                // INSTANCING
                QUnit.test("Instancing", function(assert: qunit.Assert) {
                    var object = new SphericalHarmonics3();
                    assert.ok(object, "Can instantiate a SphericalHarmonics3.");
                });

                // PROPERTIES
                QUnit.todo("coefficients", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isSphericalHarmonics3", function(assert: qunit.Assert) {
                    var object = new SphericalHarmonics3();
                    assert.ok(object.isSphericalHarmonics3, "SphericalHarmonics3.isSphericalHarmonics3 should be true");
                });

                QUnit.todo("set", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("zero", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getAt", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getIrradianceAt", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("add", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("addScaledSH", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("scale", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("lerp", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("equals", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("copy", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("clone", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("fromArray", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("toArray", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC - STATIC
                QUnit.todo("getBasisAt", function(assert: qunit.Assert) {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}