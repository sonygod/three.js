import CurvePath from '../../../../../src/extras/core/CurvePath';
import Curve from '../../../../../src/extras/core/Curve';
import qunit from 'qunit'; // Assuming you have a qunit library for Haxe

class CurvePathTests {

    public static function run() {
        qunit.module("Extras", () -> {
            qunit.module("Core", () -> {
                qunit.module("CurvePath", () -> {
                    // INHERITANCE
                    qunit.test("Extending", (assert) -> {
                        var object:CurvePath = new CurvePath();
                        assert.strictEqual(Std.is(object, Curve), true, 'CurvePath extends from Curve');
                    });

                    // INSTANCING
                    qunit.test("Instancing", (assert) -> {
                        var object:CurvePath = new CurvePath();
                        assert.ok(object != null, 'Can instantiate a CurvePath.');
                    });

                    // PROPERTIES
                    qunit.test("type", (assert) -> {
                        var object:Curve = new Curve();
                        assert.ok(object.type == "Curve", 'Curve.type should be Curve');
                    });

                    // TODO: Uncomment and implement the remaining tests as needed
                    // qunit.todo("curves", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("autoClose", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // // PUBLIC
                    // qunit.todo("add", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("closePath", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("getPoint", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("getLength", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("updateArcLengths", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("getCurveLengths", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("getSpacedPoints", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("getPoints", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("copy", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("toJSON", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });

                    // qunit.todo("fromJSON", (assert) -> {
                    //     assert.ok(false, 'everything\'s gonna be alright');
                    // });
                });
            });
        });
    }
}

CurvePathTests.run();