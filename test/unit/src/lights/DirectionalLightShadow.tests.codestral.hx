import js.Browser.document;
import js.QUnit;
import three.src.lights.DirectionalLightShadow;
import three.src.lights.LightShadow;
import three.src.loaders.ObjectLoader;
import three.src.lights.DirectionalLight;

class DirectionalLightShadowTest {
    public static function main() {
        QUnit.module("Lights", () -> {
            QUnit.module("DirectionalLightShadow", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object: DirectionalLightShadow = new DirectionalLightShadow();
                    assert.strictEqual(Std.is(object, LightShadow), true, "DirectionalLightShadow extends from LightShadow");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object: DirectionalLightShadow = new DirectionalLightShadow();
                    assert.ok(object, "Can instantiate a DirectionalLightShadow.");
                });

                QUnit.test("isDirectionalLightShadow", (assert) -> {
                    var object: DirectionalLightShadow = new DirectionalLightShadow();
                    assert.ok(object.isDirectionalLightShadow, "DirectionalLightShadow.isDirectionalLightShadow should be true");
                });

                QUnit.test("clone/copy", (assert) -> {
                    var a: DirectionalLightShadow = new DirectionalLightShadow();
                    var b: DirectionalLightShadow = new DirectionalLightShadow();

                    assert.notDeepEqual(a, b, "Newly instanced shadows are not equal");

                    var c: DirectionalLightShadow = a.clone();
                    assert.equal(a, c, "Shadows are identical after clone()");

                    c.mapSize.set(1024, 1024);
                    assert.notDeepEqual(a, c, "Shadows are different again after change");

                    b.copy(a);
                    assert.equal(a, b, "Shadows are identical after copy()");

                    b.mapSize.set(512, 512);
                    assert.notDeepEqual(a, b, "Shadows are different again after change");
                });

                QUnit.test("toJSON", (assert) -> {
                    var light: DirectionalLight = new DirectionalLight();
                    var shadow: DirectionalLightShadow = new DirectionalLightShadow();

                    shadow.bias = 10;
                    shadow.radius = 5;
                    shadow.mapSize.set(1024, 1024);
                    light.shadow = shadow;

                    var json: String = light.toJSON();
                    var newLight: DirectionalLight = new ObjectLoader().parse(json);

                    assert.equal(newLight.shadow, light.shadow, "Reloaded shadow is identical to the original one");
                });
            });
        });
    }
}