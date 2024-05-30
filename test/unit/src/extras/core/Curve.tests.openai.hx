package three.js.test.unit.src.extras.core;

import three.js.extras.core.Curve;

class CurveTests {
    public function new() {}

    public static function main() {
        TestSuite.add("Extras", function(sub Suite) {
            sub.add("Core", function(sub SubSuite) {
                sub.add("Curve", function(sub SubSubSuite) {
                    // INSTANCING
                    SubSubSuite.add("Instancing", function(assert) {
                        var object = new Curve();
                        assert.ok(object, "Can instantiate a Curve.");
                    });

                    // PROPERTIES
                    SubSubSuite.add("type", function(assert) {
                        var object = new Curve();
                        assert.ok(object.type == "Curve", "Curve.type should be Curve");
                    });

                    // TODOs
                    SubSubSuite.add("arcLengthDivisions", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("getPoint", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("getPointAt", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("getPoints", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("getSpacedPoints", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("getLength", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("getLengths", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("updateArcLengths", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("getUtoTmapping", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("getTangent", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("getTangentAt", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("computeFrenetFrames", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("clone", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("copy", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("toJSON", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    SubSubSuite.add("fromJSON", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });
                });
            });
        });
    }
}