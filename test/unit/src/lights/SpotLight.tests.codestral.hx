import qunit.QUnit;
import three.lights.SpotLight;
import three.lights.Light;
import utils.QUnitUtils;

class SpotLightTests {
    public static function main() {
        QUnit.module("Lights", () -> {
            QUnit.module("SpotLight", (hooks) -> {
                var lights: Array<SpotLight> = [];

                hooks.beforeEach(() -> {
                    var parameters = {
                        color: 0xaaaaaa,
                        intensity: 0.5,
                        distance: 100.0,
                        angle: 0.8,
                        penumbra: 8.0,
                        decay: 2.0
                    };

                    lights = [
                        new SpotLight(parameters.color),
                        new SpotLight(parameters.color, parameters.intensity),
                        new SpotLight(parameters.color, parameters.intensity, parameters.distance),
                        new SpotLight(parameters.color, parameters.intensity, parameters.distance, parameters.angle),
                        new SpotLight(parameters.color, parameters.intensity, parameters.distance, parameters.angle, parameters.penumbra),
                        new SpotLight(parameters.color, parameters.intensity, parameters.distance, parameters.angle, parameters.penumbra, parameters.decay)
                    ];
                });

                QUnit.test("Extending", (assert) -> {
                    var object = new SpotLight();
                    assert.strictEqual(Std.is(object, Light), true, "SpotLight extends from Light");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new SpotLight();
                    assert.ok(object, "Can instantiate a SpotLight.");
                });

                QUnit.test("type", (assert) -> {
                    var object = new SpotLight();
                    assert.ok(object.type == "SpotLight", "SpotLight.type should be SpotLight");
                });

                // TODO: Implement the rest of the tests

                QUnit.test("power", (assert) -> {
                    var a = new SpotLight(0xaaaaaa);

                    a.intensity = 100;
                    assert.numEqual(a.power, 100 * Math.PI, "Correct power for an intensity of 100");

                    a.intensity = 40;
                    assert.numEqual(a.power, 40 * Math.PI, "Correct power for an intensity of 40");

                    a.power = 100;
                    assert.numEqual(a.intensity, 100 / Math.PI, "Correct intensity for a power of 100");
                });

                QUnit.test("isSpotLight", (assert) -> {
                    var object = new SpotLight();
                    assert.ok(object.isSpotLight, "SpotLight.isSpotLight should be true");
                });

                QUnit.test("dispose", (assert) -> {
                    assert.expect(0);

                    var object = new SpotLight();
                    object.dispose();
                });

                QUnit.test("Standard light tests", (assert) -> {
                    QUnitUtils.runStdLightTests(assert, lights);
                });
            });
        });
    }
}