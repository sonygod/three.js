import js.Browser.document;
import js.html.QUnit;
import three.js.src.lights.PointLight;
import three.js.src.lights.Light;
import three.js.test.utils.QUnitUtils;

class PointLightTests {
    private var lights:Array<PointLight>;

    public function new() {
        QUnit.module("Lights", () -> {
            QUnit.module("PointLight", (hooks) -> {
                hooks.beforeEach(() -> {
                    var parameters = {
                        color: 0xaaaaaa,
                        intensity: 0.5,
                        distance: 100,
                        decay: 2
                    };

                    lights = [
                        new PointLight(),
                        new PointLight(parameters.color),
                        new PointLight(parameters.color, parameters.intensity),
                        new PointLight(parameters.color, parameters.intensity, parameters.distance),
                        new PointLight(parameters.color, parameters.intensity, parameters.distance, parameters.decay)
                    ];
                });

                QUnit.test("Extending", (assert) -> {
                    var object = new PointLight();
                    assert.eq(js.Std.is(object, Light), true, "PointLight extends from Light");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new PointLight();
                    assert.isTrue(object != null, "Can instantiate a PointLight.");
                });

                QUnit.test("type", (assert) -> {
                    var object = new PointLight();
                    assert.isTrue(object.type == "PointLight", "PointLight.type should be PointLight");
                });

                QUnit.test("power", (assert) -> {
                    var a = new PointLight(0xaaaaaa);

                    a.intensity = 100;
                    assert.eq(a.power, 100 * Math.PI * 4, "Correct power for an intensity of 100");

                    a.intensity = 40;
                    assert.eq(a.power, 40 * Math.PI * 4, "Correct power for an intensity of 40");

                    a.power = 100;
                    assert.eq(a.intensity, 100 / (4 * Math.PI), "Correct intensity for a power of 100");
                });

                QUnit.test("isPointLight", (assert) -> {
                    var object = new PointLight();
                    assert.isTrue(object.isPointLight, "PointLight.isPointLight should be true");
                });

                QUnit.test("dispose", (assert) -> {
                    assert.expect(0);

                    var object = new PointLight();
                    object.dispose();
                });

                QUnit.test("Standard light tests", (assert) -> {
                    QUnitUtils.runStdLightTests(assert, lights);
                });
            });
        });
    }
}