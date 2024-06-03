import qunit.QUnit;
import three.src.helpers.DirectionalLightHelper;
import three.src.core.Object3D;
import three.src.lights.DirectionalLight;

class DirectionalLightHelperTests {
    public static function main() {
        QUnit.module("Helpers", () -> {
            QUnit.module("DirectionalLightHelper", () -> {
                var parameters = {
                    size: 1,
                    color: 0xaaaaaa,
                    intensity: 0.8
                };

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var light = new DirectionalLight(parameters.color);
                    var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
                    assert.strictEqual(Std.is(object, Object3D), true, "DirectionalLightHelper extends from Object3D");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var light = new DirectionalLight(parameters.color);
                    var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
                    assert.ok(object, "Can instantiate a DirectionalLightHelper.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var light = new DirectionalLight(parameters.color);
                    var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
                    assert.ok(object.type == "DirectionalLightHelper", "DirectionalLightHelper.type should be DirectionalLightHelper");
                });

                // PUBLIC
                QUnit.test("dispose", (assert) -> {
                    assert.expect(0);
                    var light = new DirectionalLight(parameters.color);
                    var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
                    object.dispose();
                });
            });
        });
    }
}