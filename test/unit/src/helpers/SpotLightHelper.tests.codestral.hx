import qunit.QUnit;
import three.helpers.SpotLightHelper;
import three.core.Object3D;
import three.lights.SpotLight;

class SpotLightHelperTests {
    public static function main() {
        QUnit.module("Helpers", () -> {
            QUnit.module("SpotLightHelper", () -> {
                var parameters:Dynamic = {
                    color: 0xaaaaaa,
                    intensity: 0.5,
                    distance: 100,
                    angle: 0.8,
                    penumbra: 8,
                    decay: 2
                };

                QUnit.test("Extending", (assert) -> {
                    var light:SpotLight = new SpotLight(parameters.color);
                    var object:SpotLightHelper = new SpotLightHelper(light, parameters.color);
                    assert.strictEqual(Std.is(object, Object3D), true, 'SpotLightHelper extends from Object3D');
                });

                QUnit.test("Instancing", (assert) -> {
                    var light:SpotLight = new SpotLight(parameters.color);
                    var object:SpotLightHelper = new SpotLightHelper(light, parameters.color);
                    assert.ok(object, 'Can instantiate a SpotLightHelper.');
                });

                QUnit.test("type", (assert) -> {
                    var light:SpotLight = new SpotLight(parameters.color);
                    var object:SpotLightHelper = new SpotLightHelper(light, parameters.color);
                    assert.ok(object.type == 'SpotLightHelper', 'SpotLightHelper.type should be SpotLightHelper');
                });

                QUnit.test("dispose", (assert) -> {
                    assert.expect(0);
                    var light:SpotLight = new SpotLight(parameters.color);
                    var object:SpotLightHelper = new SpotLightHelper(light, parameters.color);
                    object.dispose();
                });
            });
        });
    }
}