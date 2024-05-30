import js.QUnit.*;
import js.Extras.Core.Curve;

class CurveTest {
    static function test() return qunitModule("Extras -> Core -> Curve")(function() {
        qunitTest("Instancing", function(assert) {
            var object = new Curve();
            assert.ok(object, "Can instantiate a Curve.");
        });

        qunitTest("type", function(assert) {
            var object = new Curve();
            assert.ok(object.type == "Curve", "Curve.type should be Curve");
        });

        qunitTest("arcLengthDivisions", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("getPoint", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("getPointAt", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("getPoints", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("getSpacedPoints", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("getLength", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("getLengths", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("updateArcLengths", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("getUtoTmapping", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("getTangent", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("getTangentAt", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("computeFrenetFrames", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("clone", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("copy", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("toJSON", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunitTest("fromJSON", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    });
}