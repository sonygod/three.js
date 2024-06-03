import js.Browser.document;
import three.lights.AmbientLight;
import three.lights.Light;
import utils.QUnitUtils;

class AmbientLightTests {
    public static function main() {
        QUnit.module("Lights", () -> {
            QUnit.module("AmbientLight", (hooks) -> {
                var lights: Array<AmbientLight> = [];

                hooks.beforeEach(function() {
                    var parameters = {
                        color: 0xaaaaaa,
                        intensity: 0.5
                    };

                    lights = [
                        new AmbientLight(),
                        new AmbientLight(parameters.color),
                        new AmbientLight(parameters.color, parameters.intensity)
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new AmbientLight();
                    assert.strictEqual(Std.is(object, Light), true, "AmbientLight extends from Light");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new AmbientLight();
                    assert.ok(object, "Can instantiate an AmbientLight.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new AmbientLight();
                    assert.ok(object.type === "AmbientLight", "AmbientLight.type should be AmbientLight");
                });

                // PUBLIC
                QUnit.test("isAmbientLight", (assert) -> {
                    var object = new AmbientLight();
                    assert.ok(object.isAmbientLight, "AmbientLight.isAmbientLight should be true");
                });

                // OTHERS
                QUnit.test("Standard light tests", (assert) -> {
                    QUnitUtils.runStdLightTests(assert, lights);
                });
            });
        });
    }
}