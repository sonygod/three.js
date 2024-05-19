package three.test.unit.src.lights;

import three.lights.Light;
import three.core.Object3D;
import three.test.utils.QUnitUtils;

class LightTests {
    public static function main() {
        QUnit.module("Lights", () => {
            QUnit.module("Light", (hooks) => {
                var lights:Array<Light>;
                hooks.beforeEach(() => {
                    var parameters = {
                        color: 0xaaaaaa,
                        intensity: 0.5
                    };
                    lights = [
                        new Light(),
                        new Light(parameters.color),
                        new Light(parameters.color, parameters.intensity)
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new Light();
                    assert.ok(object instanceof Object3D, "Light extends from Object3D");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new Light();
                    assert.ok(object, "Can instantiate a Light.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new Light();
                    assert.ok(object.type == "Light", "Light.type should be Light");
                });

                QUnit.todo("color", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("intensity", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isLight", (assert) => {
                    var object = new Light();
                    assert.ok(object.isLight, "Light.isLight should be true");
                });

                QUnit.test("dispose", (assert) => {
                    assert.expect(0);
                    // empty, test exists
                    var object = new Light();
                    object.dispose();
                });

                QUnit.todo("copy", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("toJSON", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                QUnit.test("Standard light tests", (assert) => {
                    QUnitUtils.runStdLightTests(assert, lights);
                });
            });
        });
    }
}