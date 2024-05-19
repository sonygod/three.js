package three.test.unit.src.lights;

import three.lights.DirectionalLight;
import three.lights.Light;
import three.test.utils.QUnitUtils;

class DirectionalLightTests {

    public function new() {}

    public static function main() {
        QUnit.module("Lights", () -> {
            QUnit.module("DirectionalLight", (hooks) -> {
                var lights:Array<DirectionalLight> = null;
                hooks.beforeEach(() -> {
                    var parameters = {
                        color: 0xaaaaaa,
                        intensity: 0.8
                    };
                    lights = [
                        new DirectionalLight(),
                        new DirectionalLight(parameters.color),
                        new DirectionalLight(parameters.color, parameters.intensity)
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new DirectionalLight();
                    assert.ok(object instanceof Light, "DirectionalLight extends from Light");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new DirectionalLight();
                    assert.ok(object != null, "Can instantiate a DirectionalLight.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new DirectionalLight();
                    assert.ok(object.type == "DirectionalLight", "DirectionalLight.type should be DirectionalLight");
                });

                QUnit.todo("position", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("target", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("shadow", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isDirectionalLight", (assert) -> {
                    var object = new DirectionalLight();
                    assert.ok(object.isDirectionalLight, "DirectionalLight.isDirectionalLight should be true");
                });

                QUnit.test("dispose", (assert) -> {
                    assert.expect(0);
                    var object = new DirectionalLight();
                    object.dispose();
                    // ensure calls dispose() on shadow
                });

                QUnit.todo("copy", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                QUnit.test("Standard light tests", (assert) -> {
                    QUnitUtils.runStdLightTests(assert, lights);
                });
            });
        });
    }
}