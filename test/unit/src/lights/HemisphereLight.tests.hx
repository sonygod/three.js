package three.test.unit.src.lights;

import three.lights.HemisphereLight;
import three.lights.Light;
import three.test.utils.QunitUtils;

class HemisphereLightTests {
    public function new() {}

    public static function main():Void {
        Qunit.module("Lights", () -> {
            Qunit.module("HemisphereLight", (hooks) -> {
                var lights:Array<HemisphereLight>;

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

                // INHERITANCE
                Qunit.test("Extending", (assert) -> {
                    var object:HemisphereLight = new HemisphereLight();
                    assert.isTrue(object instanceof Light, "HemisphereLight extends from Light");
                });

                // INSTANCING
                Qunit.test("Instancing", (assert) -> {
                    var object:HemisphereLight = new HemisphereLight();
                    assert.ok(object != null, "Can instantiate a HemisphereLight.");
                });

                // PROPERTIES
                Qunit.test("type", (assert) -> {
                    var object:HemisphereLight = new HemisphereLight();
                    assert.equal(object.type, "HemisphereLight", "HemisphereLight.type should be HemisphereLight");
                });

                Qunit.todo("position", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                Qunit.todo("groundColor", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                Qunit.test("isHemisphereLight", (assert) -> {
                    var object:HemisphereLight = new HemisphereLight();
                    assert.ok(object.isHemisphereLight, "HemisphereLight.isHemisphereLight should be true");
                });

                Qunit.todo("copy", (assert) -> {
                    // copy( source, recursive )
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                Qunit.test("Standard light tests", (assert) -> {
                    QunitUtils.runStdLightTests(assert, lights);
                });
            });
        });
    }
}