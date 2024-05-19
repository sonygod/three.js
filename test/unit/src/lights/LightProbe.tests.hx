package three.test.unit.src.lights;

import three.lights.LightProbe;
import three.lights.Light;
import qunit.QUnit;

class LightProbeTests {

    public function new() {}

    public static function main():Void {
        QUnit.module("Lights", () => {
            QUnit.module("LightProbe", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert:QUnitAssert) => {
                    var object = new LightProbe();
                    assert.ok(object instanceof Light, "LightProbe extends from Light");
                });

                // INSTANCING
                QUnit.todo("Instancing", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PROPERTIES
                QUnit.todo("sh", (assert:QUnitAssert) => {
                    // SphericalHarmonics3 if not supplied
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isLightProbe", (assert:QUnitAssert) => {
                    var object = new LightProbe();
                    assert.ok(object.isLightProbe, "LightProbe.isLightProbe should be true");
                });

                QUnit.todo("copy", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("fromJSON", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("toJSON", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}