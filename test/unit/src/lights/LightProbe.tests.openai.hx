package three.test.unit.src.lights;

import three.lights.LightProbe;
import three.lights.Light;

class LightProbeTests {
    public function new() {}

    public static function main() {
        QUnit.module("Lights", () => {
            QUnit.module("LightProbe", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new LightProbe();
                    assert.isTrue(object instanceof Light, "LightProbe extends from Light");
                });

                // INSTANCING
                QUnit.todo("Instancing", (assert) => {
                    assert.fail("everything's gonna be alright");
                });

                // PROPERTIES
                QUnit.todo("sh", (assert) => {
                    assert.fail("everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isLightProbe", (assert) => {
                    var object = new LightProbe();
                    assert.isTrue(object.isLightProbe, "LightProbe.isLightProbe should be true");
                });

                QUnit.todo("copy", (assert) => {
                    assert.fail("everything's gonna be alright");
                });

                QUnit.todo("fromJSON", (assert) => {
                    assert.fail("everything's gonna be alright");
                });

                QUnit.todo("toJSON", (assert) => {
                    assert.fail("everything's gonna be alright");
                });
            });
        });
    }
}