import js.Browser.document;
import js.QUnit;
import three.lights.HemisphereLight;
import three.lights.Light;
import three.utils.QUnitUtils;

class HemisphereLightTests {
    public static function main() {
        QUnit.module("Lights", () -> {
            QUnit.module("HemisphereLight", (hooks) -> {
                var lights:Array<HemisphereLight> = [];
                hooks.beforeEach(() -> {
                    var parameters = {
                        skyColor: 0x123456,
                        groundColor: 0xabc012,
                        intensity: 0.6
                    };

                    lights = [
                        new HemisphereLight(),
                        new HemisphereLight(parameters.skyColor),
                        new HemisphereLight(parameters.skyColor, parameters.groundColor),
                        new HemisphereLight(parameters.skyColor, parameters.groundColor, parameters.intensity)
                    ];
                });

                QUnit.test("Extending", (assert) -> {
                    var object = new HemisphereLight();
                    assert.strictEqual(js.Std.is(object, Light), true, "HemisphereLight extends from Light");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new HemisphereLight();
                    assert.ok(object != null, "Can instantiate a HemisphereLight.");
                });

                QUnit.test("type", (assert) -> {
                    var object = new HemisphereLight();
                    assert.ok(object.type == "HemisphereLight", "HemisphereLight.type should be HemisphereLight");
                });

                QUnit.test("isHemisphereLight", (assert) -> {
                    var object = new HemisphereLight();
                    assert.ok(object.isHemisphereLight, "HemisphereLight.isHemisphereLight should be true");
                });

                QUnit.test("Standard light tests", (assert) -> {
                    QUnitUtils.runStdLightTests(assert, lights);
                });
            });
        });
    }
}