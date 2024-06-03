import qunit.QUnit;
import three.lights.LightProbe;
import three.lights.Light;

class LightProbeTests {
    public static function main() {
        QUnit.module("Lights", () -> {
            QUnit.module("LightProbe", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new LightProbe();
                    assert.strictEqual(Std.is(object, Light), true, "LightProbe extends from Light");
                });

                QUnit.test("isLightProbe", (assert) -> {
                    var object = new LightProbe();
                    assert.ok(object.isLightProbe, "LightProbe.isLightProbe should be true");
                });
            });
        });
    }
}