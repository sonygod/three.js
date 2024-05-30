package three.js.test.unit.src.lights;

import three.js.lights.HemisphereLight;
import three.js.lights.Light;
import three.js.utils.qunit_utils.TestUtils;

class HemisphereLightTest {
    static function main() {
        TestUtils.module("Lights", () -> {
            TestUtils.module("HemisphereLight", (hooks) -> {
                var lights:Array<HemisphereLight> = null;
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
                TestUtils.test("Extending", (assert) -> {
                    var object:HemisphereLight = new HemisphereLight();
                    assert.isTrue(object instanceof Light, 'HemisphereLight extends from Light');
                });

                // INSTANCING
                TestUtils.test("Instancing", (assert) -> {
                    var object:HemisphereLight = new HemisphereLight();
                    assert.isTrue(object != null, 'Can instantiate a HemisphereLight.');
                });

                // PROPERTIES
                TestUtils.test("type", (assert) -> {
                    var object:HemisphereLight = new HemisphereLight();
                    assert.isTrue(object.type == "HemisphereLight", 'HemisphereLight.type should be HemisphereLight');
                });

                TestUtils.todo("position", (assert) -> {
                    assert.Ok(false, 'everything\'s gonna be alright');
                });

                TestUtils.todo("groundColor", (assert) -> {
                    assert.Ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                TestUtils.test("isHemisphereLight", (assert) -> {
                    var object:HemisphereLight = new HemisphereLight();
                    assert.isTrue(object.isHemisphereLight, 'HemisphereLight.isHemisphereLight should be true');
                });

                TestUtils.todo("copy", (assert) -> {
                    // copy( source, recursive )
                    assert.Ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                TestUtils.test("Standard light tests", (assert) -> {
                    TestUtils.runStdLightTests(assert, lights);
                });
            });
        });
    }
}