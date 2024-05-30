package three.js.test.unit.src.extras.core;

import three.js.extras.core.CurvePath;
import three.js.extras.core.Curve;

class CurvePathTests {
    public static function main() {
        Tester.module("Extras", function() {
            Tester.module("Core", function() {
                Tester.module("CurvePath", function() {
                    // INHERITANCE
                    Tester.test("Extending", function(assert) {
                        var object = new CurvePath();
                        assert.isTrue(object instanceof Curve, "CurvePath extends from Curve");
                    });

                    // INSTANCING
                    Tester.test("Instancing", function(assert) {
                        var object = new CurvePath();
                        assert.isTrue(object != null, "Can instantiate a CurvePath.");
                    });

                    // PROPERTIES
                    Tester.test("type", function(assert) {
                        var object = new Curve();
                        assert.equal(object.type, "Curve", "Curve.type should be Curve");
                    });

                    Tester.todo("curves", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("autoClose", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    // PUBLIC
                    Tester.todo("add", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("closePath", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("getPoint", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("getLength", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("updateArcLengths", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("getCurveLengths", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("getSpacedPoints", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("getPoints", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("copy", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("toJSON", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("fromJSON", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });
                });
            });
        });
    }
}